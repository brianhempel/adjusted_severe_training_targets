# The ASOS point-based gustiness is on the whole much smaller than the estimated reports gustinees.
#
# Compute a correction so that, after reweighting, the total amount of reported gusts within
# 25mi summed across the CONUS is roughly the same as before.
#
# This factor should be about 5.

import Dates

push!(LOAD_PATH, @__DIR__)

import Grids
using Utils

push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "storm_data_reports"))

import WindReports

# begin_time_str,begin_time_seconds,end_time_str,end_time_seconds,kind,speed,speed_type,source,begin_lat,begin_lon,end_lat,end_lon
# 2003-01-22 05:45:00 UTC,1043214300,2003-01-22 06:15:00 UTC,1043216100,Thunderstorm Wind,65,E,,32.65,-85.36667,32.65,-85.36667
# 2003-02-03 17:10:00 UTC,1044292200,2003-02-03 17:15:00 UTC,1044292500,Thunderstorm Wind,52,gust,estimated,36.8,-89.95,36.85,-89.78333

const estimated_reports = filter(r -> !r.measured, WindReports.conus_severe_wind_reports)

const asos_gust_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "asos_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "asos_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "asos_gust_days_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "asos_sig_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "asos_sig_gust_days_per_year_grid_130_cropped_blurred.csv")

const grid                 = Grids.grid_130_cropped
const latlons              = grid.latlons
const point_areas_sq_miles = grid.point_areas_sq_miles
const conus_mask           = Grids.grid_130_cropped_conus_mask

const begin_year = 2003
const end_year   = 2021
const nyears     = end_year + 1 - begin_year

const reports_gridded = WindReports.distribute_to_gridpoints(grid, estimated_reports)
const sig_reports_gridded = map(pt_reports -> filter(WindReports.is_sig_wind, pt_reports), reports_gridded)

function do_it(prefix, reports_gridded, seconds_to_period_i, target_counts_gridded)
  target_counts_total = 0.0

  for (sq_miles, target_count) in zip(point_areas_sq_miles[conus_mask], target_counts_gridded[conus_mask])
    target_counts_total += target_count * sq_miles
  end

  report_counts_total = 0.0

  for (sq_miles, pt_reports) in zip(point_areas_sq_miles[conus_mask], reports_gridded[conus_mask])
    periods = Set{Int64}()

    for report in pt_reports
      union!(periods, seconds_to_period_i(report.start_seconds_from_epoch_utc):seconds_to_period_i(report.end_seconds_from_epoch_utc))
    end
    report_counts_total += length(periods) * sq_miles
  end

  correction = report_counts_total / target_counts_total

  println("reweight correction $prefix: $(Float32(correction))")
end

do_it("hour",          reports_gridded,     seconds_to_hour_i,           nyears .* read_3rd_col(asos_gust_hours_per_year_grid_130_cropped_blurred_path))
do_it("fourhour",      reports_gridded,     seconds_to_fourhour_i,       nyears .* read_3rd_col(asos_gust_fourhours_per_year_grid_130_cropped_blurred_path))
do_it("day",           reports_gridded,     seconds_to_convective_day_i, nyears .* read_3rd_col(asos_gust_days_per_year_grid_130_cropped_blurred_path))
do_it("sig_hour",      sig_reports_gridded, seconds_to_hour_i,           nyears .* read_3rd_col(asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path))
do_it("sig_fourhour",  sig_reports_gridded, seconds_to_fourhour_i,       nyears .* read_3rd_col(asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path))
do_it("sig_day",       sig_reports_gridded, seconds_to_convective_day_i, nyears .* read_3rd_col(asos_sig_gust_days_per_year_grid_130_cropped_blurred_path))
