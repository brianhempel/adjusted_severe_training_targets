# This exploration was just to see what proportion of severe wind reports meet the MUCAPE≥1 and lightning criteria
#
# The CSV outputs here are otherwise unused.
#
# Answer: ~85%
#
#           passed   no data   no cape or lightning   ratio passed where data
# 50+ knot  236749   2949      41436                  85.1%
# 65+ knot  16315    186       3129                   83.9%
#
# There are 33 50+knot reports and 2 65+knot reports outside CONUS in the above (oops) but
# that's too few to change the results.

import Dates
import DelimitedFiles
import Printf

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids

const wind_events_path = joinpath(@__DIR__, "..", "storm_data_reports", "wind_events_2003-2021.csv")
const out_dir          = joinpath(@__DIR__)

const mucape_at_least_one_gridded_dir           = joinpath(@__DIR__, "..", "mucape_at_least_one_gridded")
const at_least_one_lightning_strike_gridded_dir = joinpath(@__DIR__, "..", "at_least_one_lightning_strike_gridded")


function any_bit_set(root_path, grid, year, month, day, hour, flat_is) :: Bool
  yyyymm        = Printf.@sprintf "%04d%02d"            year month
  yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" year month day hour
  in_path       = joinpath(root_path, yyyymm, yyyymmdd_hh00 * ".bits")
  bit_vec       = BitVector(undef, length(grid.latlons))
  read!(in_path, bit_vec)
  any(flat_i -> bit_vec[flat_i], flat_is)
end

function compute_missing_present_hours()
  # vector of (yr, mon, day, hr)
  present_hours = Tuple{Int64,Int64,Int64,Int64}[]
  missing_hours = Tuple{Int64,Int64,Int64,Int64}[]

  t     = Dates.DateTime(2003,1,1,0)
  end_t = Dates.DateTime(2022,1,1,0)

  while t < end_t
    yyyymm        = Printf.@sprintf "%04d%02d"            Dates.year(t) Dates.month(t)
    yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" Dates.year(t) Dates.month(t) Dates.day(t) Dates.hour(t)

    mucape_path    = joinpath(mucape_at_least_one_gridded_dir, yyyymm, yyyymmdd_hh00 * ".bits")
    lightning_path = joinpath(at_least_one_lightning_strike_gridded_dir, yyyymm, yyyymmdd_hh00 * ".bits")

    if isfile(mucape_path) && isfile(lightning_path)
      push!(present_hours, (Dates.year(t), Dates.month(t), Dates.day(t), Dates.hour(t)))
    else
      push!(missing_hours, (Dates.year(t), Dates.month(t), Dates.day(t), Dates.hour(t)))
    end

    t += Dates.Hour(1)
  end

  println("$(length(missing_hours) / (length(present_hours) + length(missing_hours)) * 100)% of hours missing MUCAPE or lightning info")

  present_hours, missing_hours
end

_, missing_hours = compute_missing_present_hours()

const missing_hours_set = Set(missing_hours)


MINUTE = 60
HOUR   = 60*MINUTE
# DAY    = 24*HOUR


function extract()
  grid = Grids.grid_236

  n_filtered = 0
  n_rejected = 0

  out_filtered    = open(joinpath(out_dir, "wind_reports_filtered.csv"), "w")
  out_rejected    = open(joinpath(out_dir, "wind_reports_rejected.csv"), "w")
  out_filtered_50 = open(joinpath(out_dir, "wind_reports_at_least_50_knots_filtered.csv"), "w")
  out_rejected_50 = open(joinpath(out_dir, "wind_reports_at_least_50_knots_rejected.csv"), "w")
  out_filtered_65 = open(joinpath(out_dir, "wind_reports_at_least_65_knots_filtered.csv"), "w")
  out_rejected_65 = open(joinpath(out_dir, "wind_reports_at_least_65_knots_rejected.csv"), "w")

  headers = nothing
  begin_time_str_col_i, end_time_str_col_i, speed_col_i, begin_lat_col_i, begin_lon_col_i, end_lat_col_i, end_lon_col_i = -1, -1, -1, -1, -1, -1, -1
  for line in eachline(wind_events_path)
    if isnothing(headers)
      # begin_time_str,begin_time_seconds,end_time_str,end_time_seconds,kind,speed,speed_type,source,begin_lat,begin_lon,end_lat,end_lon
      headers              = split(line, ',')
      begin_time_str_col_i = findfirst(isequal("begin_time_str"), headers) :: Int64
      begin_time_str_col_i = findfirst(isequal("begin_time_str"), headers) :: Int64
      end_time_str_col_i   = findfirst(isequal("end_time_str"),   headers) :: Int64
      end_time_str_col_i   = findfirst(isequal("end_time_str"),   headers) :: Int64
      speed_col_i          = findfirst(isequal("speed"),          headers) :: Int64
      begin_lat_col_i      = findfirst(isequal("begin_lat"),      headers) :: Int64
      begin_lon_col_i      = findfirst(isequal("begin_lon"),      headers) :: Int64
      end_lat_col_i        = findfirst(isequal("end_lat"),        headers) :: Int64
      end_lon_col_i        = findfirst(isequal("end_lon"),        headers) :: Int64
      println(out_filtered,    line)
      println(out_filtered_50, line)
      println(out_filtered_65, line)
      println(out_rejected,    line * ",reasons")
      println(out_rejected_50, line * ",reasons")
      println(out_rejected_65, line * ",reasons")
      continue
    end

    row = split(line, ',')

    @assert length(row) == length(headers)

    # "2022-06-01 05:01:00 UTC"
    #  1234567890123456789
    begin_year  = parse(Int64, row[begin_time_str_col_i][1:4])
    begin_month = parse(Int64, row[begin_time_str_col_i][6:7])
    begin_day   = parse(Int64, row[begin_time_str_col_i][9:10])
    begin_hour  = parse(Int64, row[begin_time_str_col_i][12:13])
    end_year    = parse(Int64, row[end_time_str_col_i][1:4])
    end_month   = parse(Int64, row[end_time_str_col_i][6:7])
    end_day     = parse(Int64, row[end_time_str_col_i][9:10])
    end_hour    = parse(Int64, row[end_time_str_col_i][12:13])

    speed = parse(Float32, row[speed_col_i])

    print("\r$(row[begin_time_str_col_i])")

    begin_latlon = parse(Float64, row[begin_lat_col_i]), parse(Float64, row[begin_lon_col_i])
    end_latlon   = parse(Float64, row[end_lat_col_i]), parse(Float64, row[end_lon_col_i])

    in_conus = Grids.is_in_conus_bounding_box(begin_latlon) && Grids.is_in_conus_bounding_box(end_latlon)

    info_available =
      !((begin_year, begin_month, begin_day, begin_hour) in missing_hours_set) &&
      !((end_year,   end_month,   end_day,   end_hour)   in missing_hours_set)

    if in_conus && info_available
      function check_mucape_and_lightning(latlon, year, month, day, hour)
        center_flat_i = Grids.latlon_to_closest_grid_i(grid, latlon)

        # Grid 236 is much larger than CONUS so we don't need to worry about the edges

        # 3x3 square
        flat_is = [
          center_flat_i+grid.width-1, center_flat_i+grid.width, center_flat_i+grid.width+1,
          center_flat_i-1,            center_flat_i,            center_flat_i+1,
          center_flat_i-grid.width-1, center_flat_i-grid.width, center_flat_i-grid.width+1,
        ]

        mucape_okay    = any_bit_set(mucape_at_least_one_gridded_dir,           grid, year, month, day, hour, flat_is)
        lightning_okay = any_bit_set(at_least_one_lightning_strike_gridded_dir, grid, year, month, day, hour, flat_is)

        mucape_okay, lightning_okay
      end

      mucape_okay, lightning_okay = check_mucape_and_lightning(begin_latlon, begin_year, begin_month, begin_day, begin_hour)
      if !(mucape_okay && lightning_okay)
        mucape_okay, lightning_okay = check_mucape_and_lightning(end_latlon, end_year, end_month, end_day, end_hour)
      end
    end

    if in_conus && info_available && mucape_okay && lightning_okay
      println(out_filtered, line)
      speed >= 50 && println(out_filtered_50, line)
      speed >= 65 && println(out_filtered_65, line)
      n_filtered += 1
    else
      reasons = []
      !in_conus       &&                                       push!(reasons, "outside_conus")
      !info_available &&                                       push!(reasons, "mucape_or_lightning_unavailable")
      in_conus        && info_available  && !mucape_okay    && push!(reasons, "mucape<1")
      in_conus        && info_available  && !lightning_okay && push!(reasons, "no_lightning")
      println(out_rejected, line * "," * join(reasons, ";"))
      speed >= 50 && println(out_rejected_50, line * "," * join(reasons, ";"))
      speed >= 65 && println(out_rejected_65, line * "," * join(reasons, ";"))
      n_rejected += 1
    end
  end

  close(out_filtered)
  close(out_rejected)
  close(out_filtered_50)
  close(out_rejected_50)
  close(out_filtered_65)
  close(out_rejected_65)

  println()
  println("Filtered: $n_filtered")
  println("Rejected: $n_rejected")
end

extract()
