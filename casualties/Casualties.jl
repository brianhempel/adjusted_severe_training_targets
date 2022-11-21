import Dates
import Random

Random.seed!(12345) # deterministic randomness

const data_dir = joinpath(@__DIR__, "..", "data_2003-2021")

push!(LOAD_PATH, joinpath(@__DIR__, ".."))

import Grids
using Utils
import GMTPlot

const colors_path_40          = joinpath(@__DIR__, "..", "colors", "colors_40.cpt")
const colors_path_10          = joinpath(@__DIR__, "..", "colors", "colors_10.cpt")
const colors_path_5           = joinpath(@__DIR__, "..", "colors", "colors_5.cpt")
const colors_path_2           = joinpath(@__DIR__, "..", "colors", "colors_2.cpt")
const colors_path_1           = joinpath(@__DIR__, "..", "colors", "colors_1.cpt")
const colors_path_0_5         = joinpath(@__DIR__, "..", "colors", "colors_0.5.cpt")
const colors_path_reweighting = joinpath(@__DIR__, "..", "colors", "colors_reweighting.cpt")


push!(LOAD_PATH, joinpath(data_dir, "storm_data_reports"))

import WindReports

const reports_with_casualties = filter(r -> WindReports.ncasualties(r) > 0, WindReports.conus_wind_reports);

const conus_mask_13km = Grids.grid_130_cropped_conus_mask[:]

# There are some edge points on the CONUS that are not in the mask but have reports...include them

# for report in reports_with_casualties
#   lat, lon = 0.5 .* (report.start_latlon .+ report.end_latlon)

#   grid_i = Grids.latlon_to_closest_grid_i(Grids.grid_130_cropped, (lat, lon))

#   if !Grids.grid_130_cropped_conus_mask[grid_i]
#     w = Grids.grid_130_cropped.width

#     # Ensure one of our n/s/e/w neighbors is in the CONUS
#     if Grids.grid_130_cropped_conus_mask[grid_i - w] || Grids.grid_130_cropped_conus_mask[grid_i + w] || Grids.grid_130_cropped_conus_mask[grid_i - 1] || Grids.grid_130_cropped_conus_mask[grid_i + 1]
#       conus_mask_13km[grid_i] = true
#     else
#       println("$report not in CONUS!")
#     end
#   end
# end

# Expand CONUS mask by one pixel so we don't crop out any shoreline reports.
w = Grids.grid_130_cropped.width
for grid_i in w+1:(length(Grids.grid_130_cropped.latlons)-w)
  if Grids.grid_130_cropped_conus_mask[grid_i - w] || Grids.grid_130_cropped_conus_mask[grid_i + w] || Grids.grid_130_cropped_conus_mask[grid_i - 1] || Grids.grid_130_cropped_conus_mask[grid_i + 1]
    conus_mask_13km[grid_i] = true
  end
end

# The ASCII grid files look like:

# ncols         8640
# nrows         4320
# xllcorner     -180
# yllcorner     -90
# cellsize      0.041666666666667
# NODATA_value  -9999
# -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 ...
# -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 ...
# -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 -9999 ...
# ...

const σ_km = 200


function load_2pt5_min_data(zip_path) :: Matrix{Float32}
  grid_lines = map(strip, readlines(`unzip -p $zip_path $(replace(zip_path, "_asc.zip" => ".asc", "-" => "_"))`))

  # Convert to 2D array of Float32's, with -9999 recoded as 0
  vcat(
    map(grid_lines[7:length(grid_lines)]) do line
      transpose(map(cell -> max(0f0, parse(Float32, cell)), split(line)))
    end...
  )
end

function lookup(data, lat, lon)
  x_per_cell = 360.0 / size(data, 2)
  y_per_cell = 180.0 / size(data, 1)

  x_i = round(Int64, (lon + 180.0) / x_per_cell, RoundDown) + 1
  y_i = size(data, 1) - round(Int64, (lat + 90.0)  / y_per_cell, RoundDown)

  # println((y_i, x_i))

  data[y_i, x_i]
end

function lookup_xi_yi(data, lat, lon)
  x_per_cell = 360.0 / size(data, 2)
  y_per_cell = 180.0 / size(data, 1)

  x_i = round(Int64, (lon + 180.0) / x_per_cell, RoundDown) + 1
  y_i = size(data, 1) - round(Int64, (lat + 90.0)  / y_per_cell, RoundDown)

  # println((y_i, x_i))

  (x_i, y_i)
end

# 41.88261975597061, -87.63308257610062

function xi_yi_to_latlon(data, x_i, y_i)
  x_per_cell = 360.0 / size(data, 2)
  y_per_cell = 180.0 / size(data, 1)

  # x_i = round(Int64, (lon + 180.0) / x_per_cell, RoundDown) + 1
  # x_i = (lon + 180) / x_per_cell + 1
  # x_i - 1 = (lon + 180) / x_per_cell
  # (x_i - 1) * x_per_cell = lon + 180
  # (x_i - 1) * x_per_cell - 180 = lon
  lon = (x_i - 1) * x_per_cell - 180.0 + 0.5*x_per_cell

  # y_i = size(data, 1) - round(Int64, (lat + 90.0)  / y_per_cell, RoundDown)
  # y_i = size(data, 1) - (lat + 90.0) / y_per_cell
  # y_i - size(data, 1) = -(lat + 90.0) / y_per_cell
  # (y_i - size(data, 1)) * y_per_cell = -(lat + 90.0)
  # (size(data, 1) - y_i) * y_per_cell = lat + 90.0
  # (size(data, 1) - y_i) * y_per_cell - 90.0 = lat
  lat = (size(data, 1) - y_i) * y_per_cell - 90.0 + 0.5*y_per_cell

  (lat, lon)
end

# Center for International Earth Science Information Network - CIESIN - Columbia University. 2018. Gridded Population of the World, Version 4 (GPWv4): Population Count, Revision 11. Palisades, New York: NASA Socioeconomic Data and Applications Center (SEDAC). https://doi.org/10.7927/H4JW8BX5. Accessed 15 Nov 2022.

pop = load_2pt5_min_data("gpw-v4-population-count-rev11_2010_2pt5_min_asc.zip");

for _ in 1:1_000_000
  lat = -90.0  + rand(Float64)*180.0
  lon = -180.0 + rand(Float64)*360.0

  x_i, y_i   = lookup_xi_yi(pop, lat, lon)
  lat2, lon2 = xi_yi_to_latlon(pop, x_i, y_i)

  @assert lookup(pop, lat, lon) == lookup(pop, lat2, lon2)
end

# add_latlon!(hour_i, latlon) = push!(gridded_est_wind_hours[Grids.latlon_to_closest_grid_i(Grids.grid_130_cropped, latlon)], hour_i)

# Regrid population to 13km because we have a conus bitmask for that

pop_13km = map(_ -> 0.0, Grids.grid_130_cropped.latlons);

for x_i in axes(pop)[2]
  for y_i in axes(pop)[1]
    lat, lon = xi_yi_to_latlon(pop, x_i, y_i)

    grid_i = Grids.latlon_to_closest_grid_i(Grids.grid_130_cropped, (lat, lon))

    if conus_mask_13km[grid_i]
      pop_13km[grid_i] += pop[y_i, x_i]
    end
  end
end

println("CONUS total gridded population: $(floor(sum(pop_13km))) (should be ~306,675,006)")

GMTPlot.plot_map("population_13km_grid", Grids.grid_130_cropped.latlons, pop_13km; title = "2010 Population/Gridpoint, 13km Grid", nearest_neighbor = true, label_contours = false, steps = 20, zlow = 0, zhigh = 100000)

pop_13km_blurred = Grids.gaussian_blur(Grids.grid_130_cropped, conus_mask_13km, σ_km, pop_13km; only_in_conus = true)
println("CONUS total gridded blurred population: $(floor(sum(pop_13km_blurred))) (should be the same)")

GMTPlot.plot_map("population_13km_grid_blurred", Grids.grid_130_cropped.latlons, pop_13km_blurred; title = "2010 Population/Gridpoint", label_contours = false, steps = 20, zlow = 0, zhigh = 50000)

casualties_13km = map(_ -> 0.0, Grids.grid_130_cropped.latlons);



function jitter_latlon(latlon, max_mi)
  lat, lon = latlon

  miles_per_lat_degree = Grids.instantish_distance((lat - 0.5, lon), (lat + 0.5, lon)) / Grids.METERS_PER_MILE
  miles_per_lon_degree = Grids.instantish_distance((lat, lon - 0.5), (lat, lon + 0.5)) / Grids.METERS_PER_MILE

  lat2 = lat + max_mi * (2*rand(Float64)-1) / miles_per_lat_degree
  lon2 = lon + max_mi * (2*rand(Float64)-1) / miles_per_lon_degree

  grid_i = Grids.latlon_to_closest_grid_i(Grids.grid_130_cropped, (lat2, lon2))

  if Grids.grid_130_cropped_conus_mask[grid_i] && Grids.instantish_distance((lat2, lon2), (lat, lon)) <= max_mi * Grids.METERS_PER_MILE
    (lat2, lon2)
  else # try again
    jitter_latlon(latlon, max_mi)
  end
end


const jitter_mi = 20
casualty_latlons = []

for report in reports_with_casualties
  latlon = 0.5 .* (report.start_latlon .+ report.end_latlon)

  grid_i = Grids.latlon_to_closest_grid_i(Grids.grid_130_cropped, latlon)

  if !conus_mask_13km[grid_i]
    println("$report not in CONUS!")
  end

  casualties_13km[grid_i] += WindReports.ncasualties(report)

  for _ in 1:WindReports.ncasualties(report)
    ratio_on_segment = rand(Float64)
    latlon = Grids.ratio_on_segment(report.start_latlon, report.end_latlon, ratio_on_segment)

    if jitter_mi > 0 && any(latlon2 -> Grids.instantish_distance(latlon2, latlon) < 0.5*jitter_mi*Grids.METERS_PER_MILE, casualty_latlons)
      push!(casualty_latlons, jitter_latlon(latlon, jitter_mi))
    else
      push!(casualty_latlons, latlon)
    end
  end
end


GMTPlot.plot_map("casualties_13km_grid", Grids.grid_130_cropped.latlons, casualties_13km; title = "Casualites/Gridpoint, 13km Grid", nearest_neighbor = true, label_contours = false, steps = 20, zlow = 0, zhigh = 10)

casualties_13km_blurred = Grids.gaussian_blur(Grids.grid_130_cropped, conus_mask_13km, σ_km, casualties_13km; only_in_conus = true)
GMTPlot.plot_map("casualties_13km_grid_blurred", Grids.grid_130_cropped.latlons, casualties_13km_blurred; title = "Casualites/Gridpoint", label_contours = false, steps = 5, zlow = 0, zhigh = 0.5, colors = colors_path_0_5)


nyears = length(2003:2021)

# The Cedar Rapids cluster is from the 2020-8-10 derecho, which has 100 direct and 100 indirect estimated injuries.
# 2020-08-10 17:30:00 UTC,1597080600,2020-08-10 18:50:00 UTC,1597085400,Thunderstorm Wind,122.00,gust,estimated,41.9879,-91.8387,42.0212,-91.3675,"Widespread straight-line winds that produced extensive damage were reported throughout Linn County, associated with a derecho. These winds lasted around an hour in total at any one location, even though the initial line of storms moved out quickly. Damaging straight-line winds continued and were associated with the rear inflow jet. Maximum wind speeds were estimated to be 80 to 100 MPH for much of the county, with areas in central Linn County that had wind speed estimates that were 120 MPH or higher. The highest estimated wind speed were in the Cedar Rapids area where extensive damage to an apartment complex occurred with damage indicating winds about 140 MPH. A radio transmission tower also collapsed with wind speed estimated at 130 MPH. These estimates were determined based off damage reports and photos submitted through social media as well as a damage survey. The peak thunderstorm wind gust measured at the Cedar Rapids airport ASOS before it lost power was 68 MPH. The duration of strong winds caused extensive damaged most if not all trees, crops, and structures in their path. Due to the widespread damage, long duration power outages occurred. One fatality occurred here when a 63 year old man riding a bicycle was struck and killed by a tree that was knocked down due to the winds. There were also numerous injuries reported in the Cedar Rapids area."

# The St. Louis cluster is from 100 injuries when a tent collapsed on 2012-04-28:
# 2012-04-28 20:45:00 UTC,1335645900,2012-04-28 20:45:00 UTC,1335645900,Thunderstorm Wind,52.00,gust,estimated,38.6196,-90.1943,38.6196,-90.1943,"About 100 people were injured and one person was killed when a tent collapsed on a crowd that was gathered after a Cardinals game at Kilroy's Sports Bar (720 South Seventh Street). Seventeen people were taken to area hospitals and treated for their injuries. According to radar data and eye witness reports, outflow winds of 50 to 60 mph from the rear flank downdraft of the supercell thunderstorm arrived between 3:40 p.m. and 3:50 p.m. causing the localized damage near Busch Stadium."
casualties_per_1M_per_year = casualties_13km_blurred ./ (pop_13km_blurred ./ 1_000_000 .+ eps(Float32)) ./ nyears
sparse_vals = map(latlon -> (latlon, 1), casualty_latlons)
GMTPlot.plot_map("casualties_per_1M_per_year_13km_grid_blurred", Grids.grid_130_cropped.latlons, casualties_per_1M_per_year; title = "Casualites/Million/Year", sparse_vals = sparse_vals, sparse_val_symbol = "+", sparse_val_size = "0.04", sparse_val_pen="0.1p,0/0/0@75", label_contours = true, steps = 5, zlow = 0, zhigh = 5, colors = colors_path_5)


deaths_13km   = map(_ -> 0.0, Grids.grid_130_cropped.latlons);
death_latlons = []

for report in reports_with_casualties
  lat, lon = 0.5 .* (report.start_latlon .+ report.end_latlon)

  grid_i = Grids.latlon_to_closest_grid_i(Grids.grid_130_cropped, (lat, lon))

  if !conus_mask_13km[grid_i]
    println("$report not in CONUS!")
  end

  deaths_13km[grid_i] += WindReports.ndeaths(report)

  for _ in 1:WindReports.ndeaths(report)
    ratio_on_segment = rand(Float64)
    latlon = Grids.ratio_on_segment(report.start_latlon, report.end_latlon, ratio_on_segment)

    if jitter_mi > 0 && any(latlon2 -> Grids.instantish_distance(latlon2, latlon) < 0.5*jitter_mi*Grids.METERS_PER_MILE, death_latlons)
      push!(death_latlons, jitter_latlon(latlon, jitter_mi))
    else
      push!(death_latlons, latlon)
    end
  end
end

GMTPlot.plot_map("deaths_13km_grid", Grids.grid_130_cropped.latlons, deaths_13km; title = "Deaths/Gridpoint, 13km Grid", nearest_neighbor = true, label_contours = false, steps = 20, zlow = 0, zhigh = 2)

deaths_13km_blurred = Grids.gaussian_blur(Grids.grid_130_cropped, conus_mask_13km, σ_km, deaths_13km; only_in_conus = true)
GMTPlot.plot_map("deaths_13km_grid_blurred", Grids.grid_130_cropped.latlons, deaths_13km_blurred; title = "Deaths/Gridpoint", label_contours = false, steps = 20, zlow = 0, zhigh = 0.1)


ndecades = nyears / 10

# The deadliest report is the duck boat sinking 2018-07-20T00:00:00, which killed 17 people in southern MO.
deaths_per_1M_per_decade = deaths_13km_blurred ./ (pop_13km_blurred ./ 1_000_000 .+ eps(Float32)) ./ ndecades
sparse_vals = map(latlon -> (latlon, 1), death_latlons)
GMTPlot.plot_map("deaths_per_1M_per_decade_13km_grid_blurred", Grids.grid_130_cropped.latlons, deaths_per_1M_per_decade; title = "Deaths/Million/Decade", sparse_vals = sparse_vals, sparse_val_symbol = "+", sparse_val_size = "0.04", sparse_val_pen="0.1p,0/0/0@50", label_contours = true, steps = 10, zlow = 0, zhigh = 10, colors = colors_path_10)
