module WindReports

import Dates
import DelimitedFiles

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids
using Utils

const wind_reports_path = joinpath(@__DIR__, "..", "storm_data_reports", "wind_reports_2003-2021.csv")
const out_dir          = @__DIR__


const MINUTE = 60
const HOUR   = 60*MINUTE

struct Report
  start_time                   :: Dates.DateTime
  start_seconds_from_epoch_utc :: Int64
  end_time                     :: Dates.DateTime
  end_seconds_from_epoch_utc   :: Int64
  start_latlon                 :: Tuple{Float64, Float64}
  end_latlon                   :: Tuple{Float64, Float64}
  knots                        :: Float64
  sustained                    :: Bool # false == gust
  measured                     :: Bool
  injuries_direct              :: Int64
  injuries_indirect            :: Int64
  deaths_direct                :: Int64
  deaths_indirect              :: Int64
end

is_severe_wind(wind_report) = wind_report.knots  >= 50.0
is_sig_wind(wind_report)    = wind_report.knots  >= 65.0

ncasualties(report) = report.injuries_direct + report.injuries_indirect + report.deaths_direct + report.deaths_indirect
ndeaths(report)     = report.deaths_direct + report.deaths_indirect

function report_is_within_25mi(latlon, report)
  meters_away = Grids.instant_meters_to_line(latlon, report.start_latlon, report.end_latlon)
  meters_away <= 25.0 * Grids.METERS_PER_MILE
end

function distribute_to_gridpoints_slow(latlons, reports)
  reports_grided = parallel_map(latlons) do latlon
    filter(reports) do report
      report_is_within_25mi(latlon, report)
    end
  end

  reports_grided
end

function distribute_to_gridpoints(grid, reports)
  reports_grid_is = parallel_map(reports) do report
    Grids.diamond_search(grid, report.start_latlon) do latlon
      report_is_within_25mi(latlon, report)
    end
  end

  reports_grided = map(_ -> Report[], grid.latlons)

  for (grid_is, report) in zip(reports_grid_is, reports)
    for grid_i in grid_is
      push!(reports_grided[grid_i], report)
    end
  end

  # for report in reports
  #   grid_is = Grids.diamond_search(grid, report.start_latlon) do latlon
  #     report_is_within_25mi(latlon, report)
  #   end
  #   for grid_i in grid_is
  #     push!(reports_grided[grid_i], report)
  #   end
  # end

  reports_grided
end

function report_looks_okay(report :: Report) :: Bool
  duration = report.end_seconds_from_epoch_utc - report.start_seconds_from_epoch_utc
  if duration >= 4*HOUR
    println(stderr, "Report starting $(Dates.unix2datetime(report.start_seconds_from_epoch_utc)) ending $(Dates.unix2datetime(report.end_seconds_from_epoch_utc)) is $(duration / HOUR) hours long! discarding")
    false
  elseif duration < 0
    println(stderr, "Report starting $(Dates.unix2datetime(report.start_seconds_from_epoch_utc)) ending $(Dates.unix2datetime(report.end_seconds_from_epoch_utc)) is $(duration / MINUTE) minutes long! discarding")
    false
  else
    true
  end
end

function read_reports_csv(path) ::Vector{Report}
  report_rows, report_headers = DelimitedFiles.readdlm(path, ','; header=true)

  report_headers = report_headers[1,:] # 1x9 array to 9-element vector.

  start_seconds_col_i     = findfirst(isequal("begin_time_seconds"), report_headers)
  end_seconds_col_i       = findfirst(isequal("end_time_seconds"), report_headers)
  start_lat_col_i         = findfirst(isequal("begin_lat"), report_headers)
  start_lon_col_i         = findfirst(isequal("begin_lon"), report_headers)
  end_lat_col_i           = findfirst(isequal("end_lat"), report_headers)
  end_lon_col_i           = findfirst(isequal("end_lon"), report_headers)
  knots_col_i             = findfirst(isequal("speed"), report_headers)
  speed_type_col_i        = findfirst(isequal("speed_type"), report_headers)
  source_col_i            = findfirst(isequal("source"), report_headers)
  injuries_direct_col_i   = findfirst(isequal("injuries_direct"), report_headers)
  injuries_indirect_col_i = findfirst(isequal("injuries_indirect"), report_headers)
  deaths_direct_col_i     = findfirst(isequal("deaths_direct"), report_headers)
  deaths_indirect_col_i   = findfirst(isequal("deaths_indirect"), report_headers)

  row_to_report(row) = begin
    start_seconds = row[start_seconds_col_i]
    end_seconds   = row[end_seconds_col_i]

    if isa(row[start_lat_col_i], Real)
      start_latlon  = (row[start_lat_col_i], row[start_lon_col_i])
      end_latlon    = (row[end_lat_col_i],   row[end_lon_col_i])
    elseif row[start_lat_col_i] == "" || row[start_lat_col_i] == "LA" || row[start_lat_col_i] == "NJ" || row[start_lat_col_i] == "TN"
      # Some wind reports are not geocoded. One LSR report is geocoded as "LA,32.86,LA,32.86"
      start_latlon = (NaN, NaN)
      end_latlon   = (NaN, NaN)
    else
      # If some wind reports are not geocoded, DelimitedFiles treats the column as strings, I believe.
      start_latlon  = (parse(Float64, row[start_lat_col_i]), parse(Float64, row[start_lon_col_i]))
      end_latlon    = (parse(Float64, row[end_lat_col_i]),   parse(Float64, row[end_lon_col_i]))
    end

    knots     = row[knots_col_i]      == -1 ? 50.0 : row[knots_col_i]
    sustained = row[speed_type_col_i] == "sustained"
    measured  = row[source_col_i]     == "measured"

    injuries_direct = row[injuries_direct_col_i]
    injuries_indirect = row[injuries_indirect_col_i]
    deaths_direct = row[deaths_direct_col_i]
    deaths_indirect = row[deaths_indirect_col_i]

    Report(Dates.unix2datetime(start_seconds), start_seconds, Dates.unix2datetime(end_seconds), end_seconds, start_latlon, end_latlon, knots, sustained, measured, injuries_direct, injuries_indirect, deaths_direct, deaths_indirect)
  end

  reports_raw = mapslices(row_to_report, report_rows, dims = [2])[:,1]
  filter(report_looks_okay, reports_raw)
end

const wind_reports = read_reports_csv(wind_reports_path)
const conus_wind_reports = filter(wind_reports) do wind_report
  # Exclude Alaska, Hawaii, Puerto Rico
  Grids.is_in_conus_bounding_box(wind_report.start_latlon) || Grids.is_in_conus_bounding_box(wind_report.end_latlon)
end
const conus_severe_wind_reports = filter(is_severe_wind, conus_wind_reports)
const conus_sig_wind_reports = filter(is_sig_wind, conus_wind_reports)

end