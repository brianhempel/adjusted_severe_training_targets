# Grid lightning to the closest prior hour (truncate the mins and secs off the time).

import DelimitedFiles
import Printf

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids

const data_dir = joinpath(@__DIR__, "..", "national_lightning_detection_network")
const out_dir  = joinpath(@__DIR__)



# before 2014:
# 04/01/03 00:02:56 49.927 -110.850   -88.3  -10.9 kA  3
# 04/01/03 00:03:54 49.966 -110.984   -71.9   -8.1 kA  2
# ...

# 2014 and later:
# 2014-01-01 00:03:10 40.447  -57.979   260.8   48.8 kA  1
# 2014-01-01 06:18:44 22.895  -87.159  -182.5  -27.0 kA  1
# ...

row_date_str(row) = row[1]
row_hr_str(row)   = row[2][1:2]

function process_file(path)

  rows = map(split, readlines(`gunzip --stdout $path`))


  hour_groups = []

  last_date_str = ""
  last_hr_str   = ""
  rows_this_hour = []

  for r in rows
    date_str = row_date_str(r)
    hr_str   = row_hr_str(r)
    if last_hr_str != hr_str || last_date_str != date_str
      if last_date_str != ""
        push!(hour_groups, rows_this_hour)
        rows_this_hour = []
      end
      last_date_str = date_str
      last_hr_str   = hr_str
    end

    push!(rows_this_hour, r)
  end

  push!(hour_groups, rows_this_hour)

  @assert length(rows) == sum(map(length, hour_groups))

  for hour_rows in hour_groups
    date_str = row_date_str(hour_rows[1])
    hr_str   = row_hr_str(hour_rows[1])

    for r in hour_rows
      @assert date_str == row_date_str(r)
      @assert hr_str   == row_hr_str(r)
    end
  end

  for hour_rows in hour_groups
    date_str = row_date_str(hour_rows[1])
    hr_str   = row_hr_str(hour_rows[1])

    print("\r$date_str $hr_str     ")

    latlons_in_hour = map(hour_rows) do r
      (parse(Float64, r[3]), parse(Float64, r[4]))
    end

    mask = Grids.mask_from_latlons(Grids.grid_236, latlons_in_hour)

    print(Float32(count(mask) / length(mask))*100)
    print("%         ")

    # write out

    if occursin("/" , date_str)
      # "04/01/03"
      month, day, year  = parse.(Int64, split(date_str, "/"))
      year += 2000
    else
      # 2014-01-01
      year, month, day  = parse.(Int64, split(date_str, "-"))
    end

    hour = parse(Int64, hr_str)

    yyyymm        = Printf.@sprintf "%04d%02d"            year month
    yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" year month day hour

    mkpath(joinpath(out_dir, yyyymm))
    out_path = joinpath(out_dir, yyyymm, yyyymmdd_hh00 * ".bits")
    write(out_path, mask)
  end

  ()
end

for fname in readdir(data_dir)
  if endswith(fname, ".lga.gz")
    path = joinpath(data_dir, fname)
    process_file(path)
  end
end
