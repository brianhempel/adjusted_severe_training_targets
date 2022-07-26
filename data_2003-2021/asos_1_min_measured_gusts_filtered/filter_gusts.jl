# Filters gusts to those that are near MUCAPE≥1 and a lighting strike. (Any in 3x3 box on grid 236 for the same hour.)
#
# The *_tc.csv outputs additionally filter by the tropical cyclone check. (Not within 250mi of a tropical storm or hurricane, unless there are wind reports in the 3x3 box for the hour.)


import Dates
import DelimitedFiles
import Printf

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids

const gusts_path = joinpath(@__DIR__, "..", "asos_1_min_measured_gusts", "gusts.csv.zip")
const out_dir    = joinpath(@__DIR__)

const mucape_at_least_one_gridded_dir           = joinpath(@__DIR__, "..", "mucape_at_least_one_gridded")
const at_least_one_lightning_strike_gridded_dir = joinpath(@__DIR__, "..", "at_least_one_lightning_strike_gridded")
const at_least_one_wind_report_gridded_dir      = joinpath(@__DIR__, "..", "at_least_one_wind_report_gridded")


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


struct TCSegment
  start_seconds_from_epoch_utc :: Int64
  end_seconds_from_epoch_utc   :: Int64
  start_latlon                 :: Tuple{Float64, Float64}
  end_latlon                   :: Tuple{Float64, Float64}
  status                       :: String # TS and HU are the ones we care about
end

const tc_segments_path = joinpath(@__DIR__, "..", "tropical_cyclones", "tropical_cyclones_2003-2021.csv")

function read_tc_csv(path) :: Vector{TCSegment}
  tc_rows, tc_headers = DelimitedFiles.readdlm(path, ',', String; header=true)

  # begin_time_str,begin_time_seconds,end_time_str,end_time_seconds,id,name,status,knots,max_radius_34_knot_winds_nmiles,begin_lat,begin_lon,end_lat,end_lon
  tc_headers = tc_headers[1,:]

  start_seconds_col_i = findfirst(isequal("begin_time_seconds"), tc_headers)
  end_seconds_col_i   = findfirst(isequal("end_time_seconds"),   tc_headers)
  start_lat_col_i     = findfirst(isequal("begin_lat"),          tc_headers)
  start_lon_col_i     = findfirst(isequal("begin_lon"),          tc_headers)
  end_lat_col_i       = findfirst(isequal("end_lat"),            tc_headers)
  end_lon_col_i       = findfirst(isequal("end_lon"),            tc_headers)
  status_col_i        = findfirst(isequal("status"),             tc_headers)

  row_to_tc(row) = TCSegment(
    parse(Int64, row[start_seconds_col_i]),
    parse(Int64, row[end_seconds_col_i]),
    parse.(Float64, (row[start_lat_col_i], row[start_lon_col_i])),
    parse.(Float64, (row[end_lat_col_i],   row[end_lon_col_i])),
    row[status_col_i],
  )

  mapslices(row_to_tc, tc_rows, dims = [2])[:,1]
end

const hurricane_and_tropical_storm_segments = filter(seg -> seg.status == "TS" || seg.status == "HU", read_tc_csv(tc_segments_path))


function extract()
  grid = Grids.grid_236

  n_filtered = 0
  n_rejected = 0

  out_filtered       = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_filtered.csv.gz")), "w")
  out_rejected       = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_rejected.csv.gz")), "w")
  out_filtered_50    = open(joinpath(out_dir, "gusts_at_least_50_knots_filtered.csv"), "w")
  out_rejected_50    = open(joinpath(out_dir, "gusts_at_least_50_knots_rejected.csv"), "w")
  out_filtered_65    = open(joinpath(out_dir, "gusts_at_least_65_knots_filtered.csv"), "w")
  out_rejected_65    = open(joinpath(out_dir, "gusts_at_least_65_knots_rejected.csv"), "w")
  out_filtered_tc    = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_filtered_tc.csv.gz")), "w")
  out_rejected_tc    = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_rejected_tc.csv.gz")), "w")
  out_filtered_50_tc = open(joinpath(out_dir, "gusts_at_least_50_knots_filtered_tc.csv"), "w")
  out_rejected_50_tc = open(joinpath(out_dir, "gusts_at_least_50_knots_rejected_tc.csv"), "w")
  out_filtered_65_tc = open(joinpath(out_dir, "gusts_at_least_65_knots_filtered_tc.csv"), "w")
  out_rejected_65_tc = open(joinpath(out_dir, "gusts_at_least_65_knots_rejected_tc.csv"), "w")

  headers = nothing
  time_str_col_i, gust_knots_col_i, lat_col_i, lon_col_i = -1, -1, -1, -1
  for line in eachline(`unzip -p $gusts_path`)
    if isnothing(headers)
      # time_str,time_seconds,wban_id,name,state,county,knots,gust_knots,lat,lon
      headers          = split(line, ',')
      time_str_col_i   = findfirst(isequal("time_str"),   headers) :: Int64
      gust_knots_col_i = findfirst(isequal("gust_knots"), headers) :: Int64
      lat_col_i        = findfirst(isequal("lat"),        headers) :: Int64
      lon_col_i        = findfirst(isequal("lon"),        headers) :: Int64
      println(out_filtered,    line * ",near_any_wind_reports,near_hurricane_or_tropical_storm")
      println(out_filtered_50, line * ",near_any_wind_reports,near_hurricane_or_tropical_storm")
      println(out_filtered_65, line * ",near_any_wind_reports,near_hurricane_or_tropical_storm")
      println(out_rejected,    line * ",near_any_wind_reports,near_hurricane_or_tropical_storm,reasons")
      println(out_rejected_50, line * ",near_any_wind_reports,near_hurricane_or_tropical_storm,reasons")
      println(out_rejected_65, line * ",near_any_wind_reports,near_hurricane_or_tropical_storm,reasons")
      continue
    end

    row = split(line, ',')

    @assert length(row) == length(headers)

    # "2022-06-01 05:01:00 UTC"
    #  1234567890123456789
    year   = parse(Int64, row[time_str_col_i][1:4])
    month  = parse(Int64, row[time_str_col_i][6:7])
    day    = parse(Int64, row[time_str_col_i][9:10])
    hour   = parse(Int64, row[time_str_col_i][12:13])
    minute = parse(Int64, row[time_str_col_i][15:16])
    second = parse(Int64, row[time_str_col_i][18:19])

    gust_knots = parse(Int64, row[gust_knots_col_i])

    year >= 2003 && year <= 2021 || continue

    print("\r$(row[time_str_col_i])")

    latlon = parse(Float64, row[lat_col_i]), parse(Float64, row[lon_col_i])

    in_conus = Grids.is_in_conus_bounding_box(latlon)

    info_available = !((year, month, day, hour) in missing_hours_set)
    if in_conus
      center_flat_i = Grids.latlon_to_closest_grid_i(grid, latlon)

      # Grid 236 is much larger than CONUS so we don't need to worry about the edges

      # 3x3 square
      flat_is = [
        center_flat_i+grid.width-1, center_flat_i+grid.width, center_flat_i+grid.width+1,
        center_flat_i-1,            center_flat_i,            center_flat_i+1,
        center_flat_i-grid.width-1, center_flat_i-grid.width, center_flat_i-grid.width+1,
      ]

      if info_available
        mucape_okay    = any_bit_set(mucape_at_least_one_gridded_dir,           grid, year, month, day, hour, flat_is)
        lightning_okay = any_bit_set(at_least_one_lightning_strike_gridded_dir, grid, year, month, day, hour, flat_is)
      end

      near_any_wind_reports = any_bit_set(at_least_one_wind_report_gridded_dir, grid, year, month, day, hour, flat_is)

      time_in_seconds_since_epoch_utc = Int64(Dates.datetime2unix(Dates.DateTime(year, month, day, hour, minute, second)))
      # event_segments_around_time will return segments of 0 length for a time duration of 0, but the below is still correct in any case.
      tc_segments = Grids.event_segments_around_time(hurricane_and_tropical_storm_segments, time_in_seconds_since_epoch_utc, 0)
      near_hurricane_or_tropical_storm = any(tc_segments) do (latlon1, latlon2)
        Grids.miles_to_line(latlon, latlon1, latlon2) <= 250
      end
    else
      near_any_wind_reports = false
      near_hurricane_or_tropical_storm = false
    end

    out_line = line * (near_any_wind_reports ? ",true" :  ",false") * (near_hurricane_or_tropical_storm ? ",true" :  ",false")

    if in_conus && info_available && mucape_okay && lightning_okay
      println(out_filtered, out_line)
      gust_knots >= 50 && println(out_filtered_50, out_line)
      gust_knots >= 65 && println(out_filtered_65, out_line)
      if near_hurricane_or_tropical_storm && !near_any_wind_reports
        out_line *= ",near_hurricane_or_tropical_storm_but_no_wind_reports"
        println(out_rejected_tc, out_line)
        gust_knots >= 50 && println(out_rejected_50_tc, out_line)
        gust_knots >= 65 && println(out_rejected_65_tc, out_line)
      else
        println(out_filtered_tc, out_line)
        gust_knots >= 50 && println(out_filtered_50_tc, out_line)
        gust_knots >= 65 && println(out_filtered_65_tc, out_line)
      end
      n_filtered += 1
    else
      reasons = []
      !in_conus       &&                                       push!(reasons, "outside_conus")
      !info_available &&                                       push!(reasons, "mucape_or_lightning_unavailable")
      in_conus        && info_available  && !mucape_okay    && push!(reasons, "mucape<1")
      in_conus        && info_available  && !lightning_okay && push!(reasons, "no_lightning")
      out_line *= "," * join(reasons, ";")
      println(out_rejected, out_line)
      gust_knots >= 50 && println(out_rejected_50, out_line)
      gust_knots >= 65 && println(out_rejected_65, out_line)
      if in_conus && near_hurricane_or_tropical_storm && !near_any_wind_reports
        out_line *= ";near_hurricane_or_tropical_storm_but_no_wind_reports"
      end
      println(out_rejected_tc, out_line)
      gust_knots >= 50 && println(out_rejected_50_tc, out_line)
      gust_knots >= 65 && println(out_rejected_65_tc, out_line)
      n_rejected += 1
    end
  end

  close(out_filtered)
  close(out_rejected)
  close(out_filtered_50)
  close(out_rejected_50)
  close(out_filtered_65)
  close(out_rejected_65)
  close(out_filtered_tc)
  close(out_rejected_tc)
  close(out_filtered_50_tc)
  close(out_rejected_50_tc)
  close(out_filtered_65_tc)
  close(out_rejected_65_tc)

  println()
  println("Filtered: $n_filtered")
  println("Rejected: $n_rejected")
end

extract()
