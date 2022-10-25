push!(LOAD_PATH, @__DIR__)

import Grids

const estimated_reports_gustiness_path                                    = joinpath(@__DIR__, "out", "estimated_reports_gustiness.csv")
estimated_reports_reweighted_gustiness_path(factor)                       = joinpath(@__DIR__, "out", "estimated_reports_x$(factor)_reweighted_gustiness.csv")
estimated_reports_reweighted_plus_measured_reports_gustiness_path(factor) = joinpath(@__DIR__, "out", "estimated_reports_x$(factor)_reweighted_plus_measured_reports_gustiness.csv")
const measured_reports_gustiness_path                                     = joinpath(@__DIR__, "out", "measured_reports_gustiness.csv")
const all_reports_gustiness_path                                          = joinpath(@__DIR__, "out", "all_reports_gustiness.csv")
const estimated_reports_gustiness_path_2003_2011                          = joinpath(@__DIR__, "out", "estimated_reports_gustiness_2003-2011.csv")
const measured_reports_gustiness_path_2003_2011                           = joinpath(@__DIR__, "out", "measured_reports_gustiness_2003-2011.csv")
const all_reports_gustiness_path_2003_2011                                = joinpath(@__DIR__, "out", "all_reports_gustiness_2003-2011.csv")
const estimated_reports_gustiness_path_2013_2021                          = joinpath(@__DIR__, "out", "estimated_reports_gustiness_2013-2021.csv")
const measured_reports_gustiness_path_2013_2021                           = joinpath(@__DIR__, "out", "measured_reports_gustiness_2013-2021.csv")
const all_reports_gustiness_path_2013_2021                                = joinpath(@__DIR__, "out", "all_reports_gustiness_2013-2021.csv")

const get_grid_i = Grids.get_grid_i

# awww yeah n^2 blurring
function blur(grid, conus_bitmask, σ_km, vals)
  mid_xi = grid.width ÷ 2
  mid_yi = grid.height ÷ 2
  # a box roughly 6*σ_km on each side
  radius_nx = findfirst(mid_xi:grid.width) do east_xi
    Grids.instantish_distance(grid.latlons[get_grid_i(grid, (mid_yi, mid_xi))], grid.latlons[get_grid_i(grid, (mid_yi, east_xi))]) / 1000.0 > σ_km*3
  end
  radius_ny = findfirst(mid_yi:grid.height) do north_yi
    Grids.instantish_distance(grid.latlons[get_grid_i(grid, (mid_yi, mid_xi))], grid.latlons[get_grid_i(grid, (north_yi, mid_xi))]) / 1000.0 > σ_km*3
  end

  # println(stderr, "σ_km = $(σ_km), radius_nx = $radius_nx, radius_ny = $radius_ny")

  out = zeros(Float64, size(vals))

  if σ_km == 0
    out[conus_bitmask] = vals[conus_bitmask]
    return out
  end

  for y1 in 1:grid.height
    Threads.@threads for x1 in 1:grid.width
      weight = eps(1.0)
      amount = 0.0
      i1 = get_grid_i(grid, (y1, x1))
      # conus_bitmask[i1] || continue
      val_ll = grid.latlons[i1]
      for y2 in clamp(y1 - radius_ny, 1, grid.height):clamp(y1 + radius_ny, 1, grid.height)
        for x2 in clamp(x1 - radius_nx, 1, grid.width):clamp(x1 + radius_nx, 1, grid.width)
          i2 = get_grid_i(grid, (y2, x2))
          conus_bitmask[i2] || continue
          ll = grid.latlons[i2]
          meters = Grids.instantish_distance(val_ll, ll)
          w = exp(-(meters/1000)^2 / (2 * σ_km^2))
          amount += w * vals[i2]
          weight += w
        end
      end
      out[i1] = amount / weight
    end
  end

  out
end

function writeout_blurred(out_base_path, grid, conus_bitmask, σ_km, vals)
  println(stderr, out_base_path)

  blurred = blur(grid, conus_bitmask, σ_km, vals)

  @assert length(blurred) == length(grid.latlons)

  open(joinpath(@__DIR__, "out", out_base_path) * ".csv", "w") do f
    println(f, "lat,lon,$out_base_path")
    for (val, latlon) in zip(blurred, grid.latlons)
      println(f, "$(latlon[1]),$(latlon[2]),$val")
    end
  end

  ()
end

function do_it(prefix, reports_gustiness_path, σ_km, σ_km_sig)
  println(stderr, prefix)

  latlons           = Tuple{Float64,Float64}[]
  hour_vals         = Float64[]
  fourhour_vals     = Float64[]
  day_vals          = Float64[]
  hour_sig_vals     = Float64[]
  fourhour_sig_vals = Float64[]
  day_sig_vals      = Float64[]

  headers = nothing
  for line in eachline(reports_gustiness_path)
    if isnothing(headers)
      headers = split(line, ',')
      continue
    end
    lat, lon, nhours_with_reports, nfourhours_with_reports, ndays_with_reports, nhours_with_sig_reports, nfourhours_with_sig_reports, ndays_with_sig_reports, report_hours_per_year, report_fourhours_per_year, report_days_per_year, sig_report_hours_per_year, sig_report_fourhours_per_year, sig_report_days_per_year = split(line, ',')

    push!(latlons,           parse.(Float64, (lat, lon)))
    push!(hour_vals,         parse(Float64, report_hours_per_year))
    push!(fourhour_vals,     parse(Float64, report_fourhours_per_year))
    push!(day_vals,          parse(Float64, report_days_per_year))
    push!(hour_sig_vals,     parse(Float64, sig_report_hours_per_year))
    push!(fourhour_sig_vals, parse(Float64, sig_report_fourhours_per_year))
    push!(day_sig_vals,      parse(Float64, sig_report_days_per_year))
  end

  writeout_blurred("$(prefix)_report_hours_per_year_grid_130_cropped_blurred",         Grids.grid_130_cropped, Grids.grid_130_cropped_conus_mask, σ_km,     hour_vals)
  writeout_blurred("$(prefix)_report_fourhours_per_year_grid_130_cropped_blurred",     Grids.grid_130_cropped, Grids.grid_130_cropped_conus_mask, σ_km,     fourhour_vals)
  writeout_blurred("$(prefix)_report_days_per_year_grid_130_cropped_blurred",          Grids.grid_130_cropped, Grids.grid_130_cropped_conus_mask, σ_km,     day_vals)
  writeout_blurred("$(prefix)_sig_report_hours_per_year_grid_130_cropped_blurred",     Grids.grid_130_cropped, Grids.grid_130_cropped_conus_mask, σ_km_sig, hour_sig_vals)
  writeout_blurred("$(prefix)_sig_report_fourhours_per_year_grid_130_cropped_blurred", Grids.grid_130_cropped, Grids.grid_130_cropped_conus_mask, σ_km_sig, fourhour_sig_vals)
  writeout_blurred("$(prefix)_sig_report_days_per_year_grid_130_cropped_blurred",      Grids.grid_130_cropped, Grids.grid_130_cropped_conus_mask, σ_km_sig, day_sig_vals)
end

do_it("estimated", estimated_reports_gustiness_path, 7, 25)
do_it("measured",  measured_reports_gustiness_path,  5, 0)
do_it("all",       all_reports_gustiness_path,       7, 25) # There are more measured reports, so use its blur params.
for correction_factor in 1:10
  if isfile(estimated_reports_reweighted_gustiness_path(correction_factor))
    do_it("estimated_x$(correction_factor)_reweighted", estimated_reports_reweighted_gustiness_path(correction_factor), 7, 25)
  end
end
for correction_factor in 1:10
  if isfile(estimated_reports_reweighted_plus_measured_reports_gustiness_path(correction_factor))
    do_it("estimated_x$(correction_factor)_reweighted_plus_measured", estimated_reports_reweighted_plus_measured_reports_gustiness_path(correction_factor), 7, 25) # There are more measured reports, so use its blur params.
  end
end

# do_it("estimated_2003-2011", estimated_reports_gustiness_path_2003_2011, 7, 25)
# do_it("measured_2003-2011",  measured_reports_gustiness_path_2003_2011, 5, 0)
# do_it("estimated_2013-2021", estimated_reports_gustiness_path_2013_2021, 7, 25)
# do_it("measured_2013-2021",  measured_reports_gustiness_path_2013_2021, 5, 0)

