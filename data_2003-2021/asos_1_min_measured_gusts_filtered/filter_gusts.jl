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

function extract()
  grid = Grids.grid_236

  n_filtered = 0
  n_rejected = 0

  out_filtered    = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_filtered.csv.gz")), "w")
  out_rejected    = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_rejected.csv.gz")), "w")
  out_filtered_50 = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_at_least_50_knots_filtered.csv.gz")), "w")
  out_rejected_50 = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_at_least_50_knots_rejected.csv.gz")), "w")
  out_filtered_65 = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_at_least_65_knots_filtered.csv.gz")), "w")
  out_rejected_65 = open(pipeline(`gzip -9`, joinpath(out_dir, "gusts_at_least_65_knots_rejected.csv.gz")), "w")

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
      println(out_filtered,    line * ",near_any_wind_reports")
      println(out_filtered_50, line * ",near_any_wind_reports")
      println(out_filtered_65, line * ",near_any_wind_reports")
      println(out_rejected,    line * ",near_any_wind_reports,reasons")
      println(out_rejected_50, line * ",near_any_wind_reports,reasons")
      println(out_rejected_65, line * ",near_any_wind_reports,reasons")
      continue
    end

    row = split(line, ',')

    @assert length(row) == length(headers)

    # "2022-06-01 05:01:00 UTC"
    #  1234567890123456789
    year  = parse(Int64, row[time_str_col_i][1:4])
    month = parse(Int64, row[time_str_col_i][6:7])
    day   = parse(Int64, row[time_str_col_i][9:10])
    hour  = parse(Int64, row[time_str_col_i][12:13])

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
    else
      near_any_wind_reports = false
    end

    out_line = line * (near_any_wind_reports ? ",true" :  ",false")

    if in_conus && info_available && mucape_okay && lightning_okay
      println(out_filtered, out_line)
      gust_knots >= 50 && println(out_filtered_50, out_line)
      gust_knots >= 65 && println(out_filtered_65, out_line)
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
