# Compute a correction to convert ASOS point-based gustiness to 25mi neighborhood gustiness.
#
# Use ASOS gustiness rates to figure out what portion of the land area is under gust per period.
#
# Conservatively consider only periods with an ASOS gust.
#
# Non-conservatively assume all periods are the same.
#
# Within a period, conservatively assume the affected area is perfectly circular, and expand it by 25mi to match report-based neighborhood probs.

import Dates

push!(LOAD_PATH, @__DIR__)

import ASOSStations
import Grids
using Utils

# push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "storm_data_reports"))

# import WindReports

# report_to_hour_is(report)           = seconds_to_hour_i(report.start_seconds_from_epoch_utc):seconds_to_hour_i(report.end_seconds_from_epoch_utc)
# report_to_fourhour_is(report)       = seconds_to_fourhour_i(report.start_seconds_from_epoch_utc):seconds_to_fourhour_i(report.end_seconds_from_epoch_utc)
# report_to_convective_day_is(report) = seconds_to_convective_day_i(report.start_seconds_from_epoch_utc):seconds_to_convective_day_i(report.end_seconds_from_epoch_utc)

const asos_gust_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "asos_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "asos_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "asos_gust_days_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "asos_sig_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "asos_sig_gust_days_per_year_grid_130_cropped_blurred.csv")

const grid    = Grids.grid_130_cropped
const latlons = grid.latlons

const begin_year = 2003
const end_year   = 2021
const nyears     = end_year + 1 - begin_year
const ndays      = Int64((Dates.Date(end_year + 1) - Dates.Date(begin_year)) / Dates.Day(1))
const nhours     = ndays * 24
const nfourhours = nhours ÷ 4

function do_it()
  gust_hours               = Set{Int64}()
  gust_fourhours           = Set{Int64}()
  gust_convective_days     = Set{Int64}()
  sig_gust_hours           = Set{Int64}()
  sig_gust_fourhours       = Set{Int64}()
  sig_gust_convective_days = Set{Int64}()

  for station in ASOSStations.stations
    union!(gust_hours,               station.gust_hours)
    union!(gust_fourhours,           station.gust_fourhours)
    union!(gust_convective_days,     station.gust_convective_days)
    union!(sig_gust_hours,           station.sig_gust_hours)
    union!(sig_gust_fourhours,       station.sig_gust_fourhours)
    union!(sig_gust_convective_days, station.sig_gust_convective_days)
  end

  # for report in WindReports.conus_severe_wind_reports
  #   union!(gust_hours,           report_to_hour_is(report))
  #   union!(gust_fourhours,       report_to_fourhour_is(report))
  #   union!(gust_convective_days, report_to_convective_day_is(report))
  #   if WindReports.is_sig_wind(report)
  #     union!(sig_gust_hours,           report_to_hour_is(report))
  #     union!(sig_gust_fourhours,       report_to_fourhour_is(report))
  #     union!(sig_gust_convective_days, report_to_convective_day_is(report))
  #   end
  # end


  asos_gust_hours_per_hour_gridded             = read_3rd_col(asos_gust_hours_per_year_grid_130_cropped_blurred_path)         ./ 365.25 ./ 24
  asos_gust_fourhours_per_fourhour_gridded     = read_3rd_col(asos_gust_fourhours_per_year_grid_130_cropped_blurred_path)     ./ 365.25 ./ 24 .* 4
  asos_gust_days_per_day_gridded               = read_3rd_col(asos_gust_days_per_year_grid_130_cropped_blurred_path)          ./ 365.25
  asos_sig_gust_hours_per_hour_gridded         = read_3rd_col(asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path)     ./ 365.25 ./ 24
  asos_sig_gust_fourhours_per_fourhour_gridded = read_3rd_col(asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path) ./ 365.25 ./ 24 .* 4
  asos_sig_gust_days_per_day_gridded           = read_3rd_col(asos_sig_gust_days_per_year_grid_130_cropped_blurred_path)      ./ 365.25

  conus_mask = Grids.is_in_conus_130_cropped.(latlons)

  function correction(gust_periods_per_period_gridded, ngust_periods, nperiods)
    target_painted_amount_per_period_no_border = sum(gust_periods_per_period_gridded[conus_mask] .* nperiods ./ ngust_periods .* grid.point_areas_sq_miles[conus_mask])

    # Assume the desired painted amount per day is perfectly circular, then add 25mi to it
    # a = πr^2
    # r = √(a/π)
    r = √(target_painted_amount_per_period_no_border/π)
    target_painted_amount_per_period = π*((r+25)^2)

    target_painted_amount_per_period / target_painted_amount_per_period_no_border
  end

  # println("25mi neighborhood correction hour:         $(Float32(correction(asos_gust_hours_per_hour_gridded,             nhours,     nhours)))")
  # println("25mi neighborhood correction fourhour:     $(Float32(correction(asos_gust_fourhours_per_fourhour_gridded,     nfourhours, nfourhours)))")
  # println("25mi neighborhood correction day:          $(Float32(correction(asos_gust_days_per_day_gridded,               ndays,      ndays)))")
  # println("25mi neighborhood correction sig hour:     $(Float32(correction(asos_sig_gust_hours_per_hour_gridded,         nhours,     nhours)))")
  # println("25mi neighborhood correction sig fourhour: $(Float32(correction(asos_sig_gust_fourhours_per_fourhour_gridded, nfourhours, nfourhours)))")
  # println("25mi neighborhood correction sig day:      $(Float32(correction(asos_sig_gust_days_per_day_gridded,           ndays,      ndays)))")

  println("25mi neighborhood correction hour:         $(Float32(correction(asos_gust_hours_per_hour_gridded,             length(gust_hours),               nhours)))")
  println("25mi neighborhood correction fourhour:     $(Float32(correction(asos_gust_fourhours_per_fourhour_gridded,     length(gust_fourhours),           nfourhours)))")
  println("25mi neighborhood correction day:          $(Float32(correction(asos_gust_days_per_day_gridded,               length(gust_convective_days),     ndays)))")
  println("25mi neighborhood correction sig hour:     $(Float32(correction(asos_sig_gust_hours_per_hour_gridded,         length(sig_gust_hours),           nhours)))")
  println("25mi neighborhood correction sig fourhour: $(Float32(correction(asos_sig_gust_fourhours_per_fourhour_gridded, length(sig_gust_fourhours),       nfourhours)))")
  println("25mi neighborhood correction sig day:      $(Float32(correction(asos_sig_gust_days_per_day_gridded,           length(sig_gust_convective_days), ndays)))")
end

do_it()
