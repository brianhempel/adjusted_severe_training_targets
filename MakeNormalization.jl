
import Dates

push!(LOAD_PATH, @__DIR__)

import Grids
using Utils

push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "storm_data_reports"))

import WindReports



# begin_time_str,begin_time_seconds,end_time_str,end_time_seconds,kind,speed,speed_type,source,begin_lat,begin_lon,end_lat,end_lon
# 2003-01-22 05:45:00 UTC,1043214300,2003-01-22 06:15:00 UTC,1043216100,Thunderstorm Wind,65,E,,32.65,-85.36667,32.65,-85.36667
# 2003-02-03 17:10:00 UTC,1044292200,2003-02-03 17:15:00 UTC,1044292500,Thunderstorm Wind,52,gust,estimated,36.8,-89.95,36.85,-89.78333

const MINUTE = 60
const HOUR   = 60*MINUTE
const DAY    = 24*HOUR

begin_year, end_year = parse.(Int64, split(get(ENV, "YEAR_RANGE", "2003-2021"), "-"))

const year_range_seconds = Int64(Dates.datetime2unix(Dates.DateTime(begin_year))) + 12*HOUR : Int64(Dates.datetime2unix(Dates.DateTime(end_year + 1))) + 12*HOUR - 1

const all_reports       = filter(r -> r.start_seconds_from_epoch_utc in year_range_seconds || r.end_seconds_from_epoch_utc in year_range_seconds,  WindReports.conus_severe_wind_reports)
const measured_reports  = filter(r -> r.measured,  all_reports)
const estimated_reports = filter(r -> !r.measured, all_reports)

const asos_gust_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "asos_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "asos_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "asos_gust_days_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "asos_sig_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "asos_sig_gust_days_per_year_grid_130_cropped_blurred.csv")

length(estimated_reports)
# 249176

length(measured_reports)
# 31844

const grid    = Grids.grid_130_cropped
const latlons = grid.latlons

const edge_factors = read_3rd_col(joinpath(@__DIR__, "out", "conus_25mi_edge_correction_factors_grid_130_cropped.csv"))


seconds_to_convective_day_i(sec) = (sec - 12*HOUR) ÷ DAY
seconds_to_hour_i(sec)           = sec ÷ HOUR
seconds_to_fourhour_i(sec)       = sec ÷ (HOUR * 4)

const nyears     = end_year + 1 - begin_year
const ndays      = Int64((Dates.Date(end_year + 1) - Dates.Date(begin_year)) / Dates.Day(1))
const nhours     = ndays * 24
const nfourhours = nhours ÷ 4

mean(xs) = sum(xs) / length(xs)

function find_normalization_factor(reports, seconds_to_period_i, target_count)
  counts = Dict{Int64,Float64}()

  for report in reports
    for period_i in seconds_to_period_i(report.start_seconds_from_epoch_utc):seconds_to_period_i(report.end_seconds_from_epoch_utc)
      count = get(counts, period_i, 0.0)
      counts[period_i] = count + 1.0
    end
  end

  if sum(map(c -> min(1.0, c), values(counts))) < target_count
    return 1.0
  end

  factor = 0.5
  step   = 0.25

  for _ in 1:10
    report_positive_period_count = sum(map(c -> min(1.0, c*factor) :: Float64, values(counts)))
    if report_positive_period_count > target_count
      factor -= step
    elseif report_positive_period_count < target_count
      factor += step
    end
    step *= 0.5
  end

  factor
end

const reports_gridded = WindReports.distribute_to_gridpoints(grid, estimated_reports)
const sig_reports_gridded = map(pt_reports -> filter(WindReports.is_sig_wind, pt_reports), reports_gridded)

function do_it(prefix, reports_gridded, seconds_to_period_i, target_counts_gridded)
  open(joinpath(@__DIR__, "out", "$(prefix)_normalization_grid_130_cropped.csv"), "w") do f
    println(f, "lat,lon,factor")
    for ((lat, lon), pt_reports, target_count, edge_factor) in zip(latlons, reports_gridded, target_counts_gridded, edge_factors)
      factor = find_normalization_factor(pt_reports, seconds_to_period_i, target_count / edge_factor)
      println(f, "$lat,$lon,$factor")
    end
  end
end

# hours_correction,
# fourhours_correction,
# days_correction,
# sig_hours_correction,
# sig_fourhours_correction,
# sig_days_correction = parse.(Float64, (last.(split.(readlines(corrections_path)))))

for correction_factor in parse.(Int64, ARGS)
  do_it("hour_x$correction_factor",          reports_gridded,     seconds_to_hour_i,           nyears .* correction_factor .* read_3rd_col(asos_gust_hours_per_year_grid_130_cropped_blurred_path))
  do_it("fourhour_x$correction_factor",      reports_gridded,     seconds_to_fourhour_i,       nyears .* correction_factor .* read_3rd_col(asos_gust_fourhours_per_year_grid_130_cropped_blurred_path))
  do_it("day_x$correction_factor",           reports_gridded,     seconds_to_convective_day_i, nyears .* correction_factor .* read_3rd_col(asos_gust_days_per_year_grid_130_cropped_blurred_path))
  do_it("sig_hour_x$correction_factor",      sig_reports_gridded, seconds_to_hour_i,           nyears .* correction_factor .* read_3rd_col(asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path))
  do_it("sig_fourhour_x$correction_factor",  sig_reports_gridded, seconds_to_fourhour_i,       nyears .* correction_factor .* read_3rd_col(asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path))
  do_it("sig_day_x$correction_factor",       sig_reports_gridded, seconds_to_convective_day_i, nyears .* correction_factor .* read_3rd_col(asos_sig_gust_days_per_year_grid_130_cropped_blurred_path))
end

# do_it("hour_uncorrected",          reports_gridded,     seconds_to_hour_i,           nyears .* read_3rd_col(asos_gust_hours_per_year_grid_130_cropped_blurred_path))
# do_it("fourhour_uncorrected",      reports_gridded,     seconds_to_fourhour_i,       nyears .* read_3rd_col(asos_gust_fourhours_per_year_grid_130_cropped_blurred_path))
# do_it("day_uncorrected",           reports_gridded,     seconds_to_convective_day_i, nyears .* read_3rd_col(asos_gust_days_per_year_grid_130_cropped_blurred_path))
# do_it("sig_hour_uncorrected",      sig_reports_gridded, seconds_to_hour_i,           nyears .* read_3rd_col(asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path))
# do_it("sig_fourhour_uncorrected",  sig_reports_gridded, seconds_to_fourhour_i,       nyears .* read_3rd_col(asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path))
# do_it("sig_day_uncorrected",       sig_reports_gridded, seconds_to_convective_day_i, nyears .* read_3rd_col(asos_sig_gust_days_per_year_grid_130_cropped_blurred_path))
