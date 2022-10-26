
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

const all_reports       = filter(r -> r.start_seconds_from_epoch_utc in year_range_seconds || r.end_seconds_from_epoch_utc in year_range_seconds, WindReports.conus_severe_wind_reports)
const measured_reports  = filter(r -> r.measured,  all_reports)
const estimated_reports = filter(r -> !r.measured, all_reports)

# Reliability and Climatological Impacts of Convective Wind Estimations
# Roger Edwards, John T. Allen, Gregory W. Carbin
# JAMC 2018
# proposes multiplying estimated speeds by 0.8 because
# humans in wind tunnels overestimate speeds by 25% according to:
# Wind Speed Perception and Risk
# Duzgun Agdas, Gregory D. Webster, Forrest J. Masters
# PLoS ONE 2012
const estimated_reports_edwards_adjusted =
  filter(WindReports.is_severe_wind, map(estimated_reports) do r
    WindReports.Report(
      r.start_time,
      r.start_seconds_from_epoch_utc,
      r.end_time,
      r.end_seconds_from_epoch_utc,
      r.start_latlon,
      r.end_latlon,
      r.knots * 0.8,
      r.sustained,
      r.measured,
    )
  end)

reweighting_paths(suffix) = (
  joinpath(@__DIR__, "out", "hour_$suffix.csv"),
  joinpath(@__DIR__, "out", "fourhour_$suffix.csv"),
  joinpath(@__DIR__, "out", "day_$suffix.csv"),
  joinpath(@__DIR__, "out", "sig_hour_$suffix.csv"),
  joinpath(@__DIR__, "out", "sig_fourhour_$suffix.csv"),
  joinpath(@__DIR__, "out", "sig_day_$suffix.csv"),
)

length(estimated_reports)
# 249176

length(measured_reports)
# 31844

# const grid_236_conusish_latlons         = filter(Grids.is_in_conus_bounding_box, Grids.grid_236.latlons)
# const grid_130_cropped_conusish_latlons = filter(Grids.is_in_conus_bounding_box, Grids.grid_130_cropped.latlons)
const grid          = Grids.grid_130_cropped
const latlons       = grid.latlons
const conus_latlons = grid.latlons[Grids.grid_130_cropped_conus_mask]

const edge_correction_factors = read_3rd_col(joinpath(@__DIR__, "out", "conus_25mi_edge_correction_factors_grid_130_cropped.csv"))


const nyears     = end_year + 1 - begin_year
const ndays      = Int64((Dates.Date(end_year + 1) - Dates.Date(begin_year)) / Dates.Day(1))
const nhours     = ndays * 24
const nfourhours = nhours ÷ 4

mean(xs) = sum(xs) / length(xs)

function count_reports(reports, extra_unreweighted_reports, seconds_to_period_i, reweighting)
  counts = Dict{Int64,Float64}()

  for report in reports
    # use mean reweighting of of start and end latlons
    factor1 = Grids.lookup_nearest(grid, reweighting, report.start_latlon)
    factor2 = Grids.lookup_nearest(grid, reweighting, report.end_latlon)
    factor = mean([factor1, factor2])

    for period_i in seconds_to_period_i(report.start_seconds_from_epoch_utc):seconds_to_period_i(report.end_seconds_from_epoch_utc)
      count = get(counts, period_i, 0.0)
      counts[period_i] = min(1.0, count + factor)
    end
  end

  for report in extra_unreweighted_reports
    for period_i in seconds_to_period_i(report.start_seconds_from_epoch_utc):seconds_to_period_i(report.end_seconds_from_epoch_utc)
      counts[period_i] = 1.0
    end
  end

  sum(values(counts))
end

function output(reports, reweighting_paths = (nothing, nothing, nothing, nothing, nothing, nothing); edge_correction = false, extra_unreweighted_reports = WindReports.Report[])
  reports_gridded                    = WindReports.distribute_to_gridpoints(grid, reports)
  extra_unreweighted_reports_gridded = WindReports.distribute_to_gridpoints(grid, extra_unreweighted_reports)

  no_reweighting = ones(Float64, length(latlons))

  hour_reweighting,
  fourhour_reweighting,
  day_reweighting,
  sig_hour_reweighting,
  sig_fourhour_reweighting,
  sig_day_reweighting = map(reweighting_paths) do reweighting_path
    isnothing(reweighting_path) ? no_reweighting : read_3rd_col(reweighting_path)
  end

  println("lat,lon,nhours_with_reports,nfourhours_with_reports,ndays_with_reports,nhours_with_sig_reports,nfourhours_with_sig_reports,ndays_with_sig_reports,report_hours_per_year,report_fourhours_per_year,report_days_per_year,sig_report_hours_per_year,sig_report_fourhours_per_year,sig_report_days_per_year")

  for (latlon, pt_reports, edge_correction_factor, pt_extra_unreweighted_reports) in zip(latlons, reports_gridded, edge_correction_factors, extra_unreweighted_reports_gridded)
    edge_correction_factor = edge_correction ? edge_correction_factor : 1.0

    nhours_with_reports     = edge_correction_factor * count_reports(pt_reports, pt_extra_unreweighted_reports, seconds_to_hour_i,           hour_reweighting)
    nfourhours_with_reports = edge_correction_factor * count_reports(pt_reports, pt_extra_unreweighted_reports, seconds_to_fourhour_i,       fourhour_reweighting)
    ndays_with_reports      = edge_correction_factor * count_reports(pt_reports, pt_extra_unreweighted_reports, seconds_to_convective_day_i, day_reweighting)

    pt_sig_reports                    = filter(WindReports.is_sig_wind, pt_reports)
    pt_sig_extra_unreweighted_reports = filter(WindReports.is_sig_wind, pt_extra_unreweighted_reports)

    nhours_with_sig_reports     = edge_correction_factor * count_reports(pt_sig_reports, pt_sig_extra_unreweighted_reports, seconds_to_hour_i,           sig_hour_reweighting)
    nfourhours_with_sig_reports = edge_correction_factor * count_reports(pt_sig_reports, pt_sig_extra_unreweighted_reports, seconds_to_fourhour_i,       sig_fourhour_reweighting)
    ndays_with_sig_reports      = edge_correction_factor * count_reports(pt_sig_reports, pt_sig_extra_unreweighted_reports, seconds_to_convective_day_i, sig_day_reweighting)

    row = [
      latlon[1],
      latlon[2],
      nhours_with_reports,
      nfourhours_with_reports,
      ndays_with_reports,
      nhours_with_sig_reports,
      nfourhours_with_sig_reports,
      ndays_with_sig_reports,
      Float32(nhours_with_reports         / nyears),
      Float32(nfourhours_with_reports     / nyears),
      Float32(ndays_with_reports          / nyears),
      Float32(nhours_with_sig_reports     / nyears),
      Float32(nfourhours_with_sig_reports / nyears),
      Float32(ndays_with_sig_reports      / nyears),
    ]
    println(join(row, ','))
  end
end

if ARGS[1] == "estimated"
  output(estimated_reports; edge_correction = true)
elseif ARGS[1] == "estimated_edwards_adjusted"
  output(estimated_reports_edwards_adjusted; edge_correction = true)
elseif ARGS[1] == "estimated_reweighted"
  suffix = ARGS[2]
  output(estimated_reports, reweighting_paths(suffix); edge_correction = true)
elseif ARGS[1] == "measured"
  output(measured_reports; edge_correction = true)
elseif ARGS[1] == "measured+estimated_reweighted"
  suffix = ARGS[2]
  output(estimated_reports, reweighting_paths(suffix); edge_correction = true, extra_unreweighted_reports = measured_reports)
elseif ARGS[1] == "all"
  output(all_reports; edge_correction = true)
else
  println(stderr, "must provide a \"estimated\", \"estimated_edwards_adjusted\", \"estimated_reweighted\", \"measured\", \"measured+estimated_reweighted\", or \"all\" as an argument")
  exit(1)
end
