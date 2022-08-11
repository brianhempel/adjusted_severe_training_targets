# Compute a correction to convert ASOS point-based gustiness to 25mi neighborhood gustiness.
#
# Compare the point-based gustiness to the 25mi neighborhood gustiness for points
# with 1 to 10 ASOS stations within 25mi.
#
# As the number of nearby ASOS stations increases, the ratio between the point-based
# and the 25mi gustiness should approach an asymptope as the stations catch all the
# severe gusts...but instead it looks linear :o


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
  asos_gust_hours_per_year_gridded         = read_3rd_col(asos_gust_hours_per_year_grid_130_cropped_blurred_path)
  asos_gust_fourhours_per_year_gridded     = read_3rd_col(asos_gust_fourhours_per_year_grid_130_cropped_blurred_path)
  asos_gust_days_per_year_gridded          = read_3rd_col(asos_gust_days_per_year_grid_130_cropped_blurred_path)
  asos_sig_gust_hours_per_year_gridded     = read_3rd_col(asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path)
  asos_sig_gust_fourhours_per_year_gridded = read_3rd_col(asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path)
  asos_sig_gust_days_per_year_gridded      = read_3rd_col(asos_sig_gust_days_per_year_grid_130_cropped_blurred_path)

  correction_factors_by_nearby_station_count = map(_ -> Float64[], 1:10)

  for (latlon, asos_gust_days_per_year) in zip(latlons, asos_gust_days_per_year_gridded)
    Grids.is_in_conus_130_cropped(latlon) || continue

    # asos_gust_days_per_year > 0 || continue
    asos_gust_days_per_year >= 1/5 || continue
    # asos_gust_days_per_year >= 0.5 || continue
    # asos_gust_days_per_year >= 0.75 || continue
    # asos_gust_days_per_year >= 1 || continue
    # asos_gust_days_per_year >= 1.5 || continue

    nearby_stations = filter(s -> Grids.instantish_distance(s.latlon, latlon) <= 25 * Grids.METERS_PER_MILE, ASOSStations.stations)

    nearby_stations != [] || continue

    # Starting with the longest-running station, add stations until we would have < 5 years of data
    sort!(nearby_stations, by=(s -> -s.ndays))

    stations_to_use = ASOSStations.Station[]
    shared_days = Set{Int64}(nearby_stations[1].legit_convective_days)
    gust_days_within_25_mi = Set{Int64}()

    for station in nearby_stations
      if length(stations_to_use) < 10 && length(intersect(shared_days, station.legit_convective_days)) >= 365.25 * 5
        intersect!(shared_days, station.legit_convective_days)
        union!(gust_days_within_25_mi, station.gust_convective_days)
        push!(stations_to_use, station)
      end
    end

    stations_to_use != [] || continue

    gusts_within_25mi_days_per_year = length(intersect(shared_days, gust_days_within_25_mi)) / length(shared_days) * 365.25

    factor = gusts_within_25mi_days_per_year / asos_gust_days_per_year

    push!(correction_factors_by_nearby_station_count[length(stations_to_use)], factor)
  end

  for i in eachindex(correction_factors_by_nearby_station_count)
    println("25mi neighborhood day correction $i stations:\t$(Float32(mean(correction_factors_by_nearby_station_count[i])))")
  end
end

do_it()
