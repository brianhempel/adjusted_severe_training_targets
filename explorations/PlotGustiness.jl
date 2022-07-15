# julia --project=.. PlotGustiness.jl

push!(LOAD_PATH, (@__DIR__) * "/../lib")

import PlotMap
import DelimitedFiles
import GeoUtils
import StormEvents
import Grids
import Grib2
import Conus

struct Gust
  seconds_from_epoch_utc :: Int64
  latlon                 :: Tuple{Float64, Float64}
  knots                  :: Float32
  gust_knots             :: Float32
end

rows, headers = DelimitedFiles.readdlm((@__DIR__) * "/gusts_deduped_qced.csv", ','; header=true)

headers = headers[1,:]

seconds_col_i    = findfirst(isequal("time_seconds"), headers)
knots_col_i      = findfirst(isequal("knots"),        headers)
gust_knots_col_i = findfirst(isequal("gust_knots"),   headers)
lat_col_i        = findfirst(isequal("lat"),          headers)
lon_col_i        = findfirst(isequal("lon"),          headers)

row_to_gust(row) = begin
  seconds    = row[seconds_col_i]
  latlon     = (row[lat_col_i], row[lon_col_i])
  knots      = row[knots_col_i]
  gust_knots = row[gust_knots_col_i]
  Gust(seconds, latlon, knots, gust_knots)
end

gusts = mapslices(row_to_gust, rows, dims = [2])[:,1]

gusts_by_precise_latlon = Dict{Tuple{Float64, Float64}, Vector{Gust}}()

for gust in gusts
  gs = get(gusts_by_precise_latlon, gust.latlon, Gust[])
  push!(gs, gust)
  gusts_by_precise_latlon[gust.latlon] = gs
end

gust_station_days_count = 0

for (latlon, gs) in gusts_by_precise_latlon
  global gust_station_days_count
  gust_days                = unique(map(gust -> StormEvents.seconds_to_convective_days_since_epoch_utc(gust.seconds_from_epoch_utc), gs))
  gust_station_days_count += length(gust_days)
end

println("$gust_station_days_count gust_station_days_count")



gustiness_by_precise_latlon = Dict{Tuple{Float64, Float64}, Float64}()

for (latlon, gs) in gusts_by_precise_latlon
  gust_days        = unique(map(gust -> StormEvents.seconds_to_convective_days_since_epoch_utc(gust.seconds_from_epoch_utc), gs))
  period_day_count = length(minimum(gust_days):maximum(gust_days)) # very naive

  if length(gust_days) >= 5 && period_day_count >= 365*5
    gustiness_by_precise_latlon[latlon] = length(gust_days) / period_day_count
  end
end

clip_level = 0.025

PlotMap.plot_debug_map_latlons("gustiness_naive_5yr", collect(keys(gustiness_by_precise_latlon)), clamp.(collect(values(gustiness_by_precise_latlon)),0,clip_level); title="naive gust day prob", steps=100, zlow=0, zhigh=clip_level, sparse=true)


gustiness_by_precise_latlon = Dict{Tuple{Float64, Float64}, Float64}()

for (latlon, gs) in gusts_by_precise_latlon
  gust_days        = unique(map(gust -> StormEvents.seconds_to_convective_days_since_epoch_utc(gust.seconds_from_epoch_utc), gs))
  period_day_count = length(minimum(gust_days):maximum(gust_days)) # very naive

  if length(gust_days) >= 10 && period_day_count >= 365*10
    gustiness_by_precise_latlon[latlon] = length(gust_days) / period_day_count
  end
end

clip_level = 0.025

PlotMap.plot_debug_map_latlons("gustiness_naive_10yr", collect(keys(gustiness_by_precise_latlon)), clamp.(collect(values(gustiness_by_precise_latlon)),0,clip_level); title="naive gust day prob (10+ yrs)", steps=100, zlow=0, zhigh=clip_level, sparse=true)


gustiness_by_precise_latlon = Dict{Tuple{Float64, Float64}, Float64}()

for (latlon, gs) in gusts_by_precise_latlon
  gust_days        = unique(map(gust -> StormEvents.seconds_to_convective_days_since_epoch_utc(gust.seconds_from_epoch_utc), gs))
  period_day_count = length(minimum(gust_days):maximum(gust_days)) # very naive

  if length(gust_days) >= 3 && period_day_count >= 365*3
    gustiness_by_precise_latlon[latlon] = length(gust_days) / period_day_count
  end
end

clip_level = 0.025

PlotMap.plot_debug_map_latlons("gustiness_naive_3yr", collect(keys(gustiness_by_precise_latlon)), clamp.(collect(values(gustiness_by_precise_latlon)),0,clip_level); title="naive gust day prob (3+ yrs)", steps=100, zlow=0, zhigh=clip_level, sparse=true)


sustaininess_by_precise_latlon = Dict{Tuple{Float64, Float64}, Float64}()

for (latlon, gs) in gusts_by_precise_latlon
  gust_days        = unique(map(gust -> StormEvents.seconds_to_convective_days_since_epoch_utc(gust.seconds_from_epoch_utc), gs))
  sustaineds       = filter(gust -> gust.knots >= 50, gs)
  sustaineds_days  = unique(map(gust -> StormEvents.seconds_to_convective_days_since_epoch_utc(gust.seconds_from_epoch_utc), sustaineds))
  period_day_count = length(minimum(gust_days):maximum(gust_days)) # very naive

  if length(gust_days) >= 3 && period_day_count >= 365*3
    sustaininess_by_precise_latlon[latlon] = length(sustaineds_days) / period_day_count
  end
end

clip_level = 0.01

PlotMap.plot_debug_map_latlons("sustaininess_naive_3yr", collect(keys(sustaininess_by_precise_latlon)), clamp.(collect(values(sustaininess_by_precise_latlon)),0,clip_level); title="sustained sevwind day prob (3+ yrs)", steps=100, zlow=0, zhigh=clip_level, sparse=true)


function read_and_filter_events_csv(path)
  filter(StormEvents.read_events_csv(path)) do event
    Conus.is_in_conus_bounding_box(event.start_latlon) || Conus.is_in_conus_bounding_box(event.end_latlon)
  end
end

# wind_reports      = read_and_filter_events_csv((@__DIR__) * "/wind_events_1998-2013.csv")
wind_reports      = read_and_filter_events_csv((@__DIR__) * "/wind_events_2003-2021.csv")
wind_reports      = filter(event -> event.severity.knots >= 50.0, wind_reports)
sustained_reports = filter(event -> event.severity.sustained,  wind_reports)
gust_reports      = filter(event -> !event.severity.sustained, wind_reports)
measured_reports  = filter(event -> event.severity.measured,  wind_reports)
estimated_reports = filter(event -> !event.severity.measured, wind_reports)


println("$(length(wind_reports)) severe thunderstorm wind reports in Storm Data from 2003-2021")
println("$(length(sustained_reports)) sustained")
println("$(length(gust_reports)) gusts")
println("$(length(measured_reports)) measured")
println("$(length(estimated_reports)) estimated")


# From MakeClimatologicalBackground.jl
function make_convective_day_to_events(events)
  convective_day_to_events = Dict{Int64,Vector{StormEvents.Event}}()

  for event in events
    for day_i in StormEvents.start_time_in_convective_days_since_epoch_utc(event):StormEvents.end_time_in_convective_days_since_epoch_utc(event)
      if !haskey(convective_day_to_events, day_i)
        convective_day_to_events[day_i] = StormEvents.Event[]
      end
      push!(convective_day_to_events[day_i], event)
    end
  end

  convective_day_to_events
end

# From MakeClimatologicalBackground.jl
#
# Adds 1 to each grid point that is within miles of any of the event segments. (Mulitple events do not accumulate more than 1.)
#
# Mutates counts_grid.
function count_neighborhoods!(counts_grid, grid, event_segments, miles)

  positive_grid_is = Set{Int64}()

  for (latlon1, latlon2) in event_segments
    event_grid_is = Grids.diamond_search(grid, Grids.latlon_to_closest_grid_i(grid, latlon1)) do candidate_latlon
      meters_away = GeoUtils.instant_meters_to_line(candidate_latlon, latlon1, latlon2)
      meters_away <= miles * GeoUtils.METERS_PER_MILE
    end

    push!(positive_grid_is, event_grid_is...)
  end

  for grid_i in positive_grid_is
    counts_grid[grid_i] += 1f0
  end

  ()
end

MINUTE = 60
HOUR   = StormEvents.HOUR
DAY    = StormEvents.DAY
NEIGHBORHOOD_RADIUS_MILES = 25

# From MakeClimatologicalBackground.jl
#
# For the counts to work right, the start needs to be aligned to a day boundary
#
# Returns (day_count, event_day_counts_grid)
function count_events_by_day(range_in_convective_days_from_epoch, grid, convective_day_to_events)
  day_count = 0
  seg_count = 0

  event_day_counts_grid = zeros(Float32, size(grid.latlons))

  for day_i in range_in_convective_days_from_epoch.start:range_in_convective_days_from_epoch.stop
    day_seconds_from_epoch = StormEvents.convective_days_since_epoch_to_seconds_utc(day_i)

    print(".")

    events         = get(convective_day_to_events, day_i, StormEvents.Event[])
    event_segments = StormEvents.event_segments_around_time(events, day_seconds_from_epoch + 12*HOUR, 12*HOUR)
    seg_count += length(event_segments)

    count_neighborhoods!(event_day_counts_grid, grid, event_segments, NEIGHBORHOOD_RADIUS_MILES)
    day_count += 1
  end
  println("Event count: $(length(vcat(collect(values(convective_day_to_events))...)))")
  println("Seg count: $seg_count")
  println("Days: $day_count")
  println(sum(event_day_counts_grid))

  (day_count, event_day_counts_grid)
end


# For the counts to work right, the start needs to be aligned to a day boundary
start = minimum(map(event -> StormEvents.seconds_to_convective_days_since_epoch_utc(event.start_seconds_from_epoch_utc), wind_reports))
stop  = maximum(map(event -> StormEvents.seconds_to_convective_days_since_epoch_utc(event.end_seconds_from_epoch_utc),   wind_reports))
RANGE = start:stop


# Same cropping and 3x downsampling as in HREF.jl
HREF_CROPPED_15KM_GRID =
  Grib2.read_grid(
    (@__DIR__) * "/../lib/href_one_field_for_grid.grib2",
    crop = ((1+214):(1473 - 99), (1+119):(1025-228)),
    downsample = 3
  ) :: Grids.Grid


function grided_event_day_rates(events)
  convective_day_to_events = make_convective_day_to_events(events)

  day_count, event_day_counts_grid = count_events_by_day(RANGE, HREF_CROPPED_15KM_GRID, convective_day_to_events)

  event_day_counts_grid ./ day_count
end

CONUS_ON_HREF_CROPPED_15KM_GRID = Conus.is_in_conus.(HREF_CROPPED_15KM_GRID.latlons)


function plot_day_rates(title, events)
  vals = grided_event_day_rates(events)

  PlotMap.plot_debug_map(
    replace(title, r"\W+" => "_"),
    HREF_CROPPED_15KM_GRID,
    vals;
    title=title,
    zlow=0,
    zhigh=maximum(vals[CONUS_ON_HREF_CROPPED_15KM_GRID]),
    steps=12
  )
end

plot_day_rates("wind reports day rate 2003-2021", wind_reports)
plot_day_rates("sustained reports day rate 2003-2021", sustained_reports)
plot_day_rates("gust reports day rate 2003-2021", gust_reports)
plot_day_rates("measured reports day rate 2003-2021", measured_reports)
plot_day_rates("estimated reports day rate 2003-2021", estimated_reports)

