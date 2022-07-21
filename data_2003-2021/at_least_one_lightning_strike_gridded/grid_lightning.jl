# Grid lightning to the closest prior hour (truncate the mins and secs off the time).

import Printf

const data_dir = joinpath(@__DIR__, "..", "national_lightning_detection_network")
const out_dir  = joinpath(@__DIR__)

import DelimitedFiles

struct Grid
  height  :: Int64 # Element count
  width   :: Int64 # Element count
  latlons :: Vector{Tuple{Float64,Float64}} # Ordering is row-major: W -> E, S -> N
end


const grid_236 = begin
  cells = DelimitedFiles.readdlm(joinpath(@__DIR__, "..", "..", "grid_236.csv"), ',', Float64; header = true)[1]
  latlons = mapslices(cells; dims=[2]) do row
    (row[3], row[4] > 180.0 ? row[4] - 360.0 : row[4])
  end[:,1]

  Grid(
    maximum(@view cells[:,2]), # height
    maximum(@view cells[:,1]), # width
    latlons
  )
end

function get_grid_i(grid :: Grid, (s_to_n_row, w_to_e_col) :: Tuple{Int64, Int64}) :: Int64
  if w_to_e_col < 1
    error("Error indexing into grid, asked for column $w_to_e_col")
  elseif w_to_e_col > grid.width
    error("Error indexing into grid, asked for column $w_to_e_col")
  elseif s_to_n_row < 1
    error("Error indexing into grid, asked for row $s_to_n_row")
  elseif s_to_n_row > grid.height
    error("Error indexing into grid, asked for row $s_to_n_row")
  end
  grid.width*(s_to_n_row-1) + w_to_e_col
end

# Returns the index into the grid to return the point closest to the given lat-lon coordinate.
#
# "Closest" is simple 2D Euclidean distance on the lat-lon plane.
# It's "wrong" but since neighboring grid points are always close, it's not very wrong.
# And happily our grids don't cross -180/180.
#
# Binaryish search
function latlon_to_closest_grid_i(grid :: Grid, (lat, lon) :: Tuple{Float64, Float64}) :: Int64
  s_to_n_row = div(grid.height, 2)
  w_to_e_col = div(grid.width, 2)

  vertical_step_size   = div(grid.height, 2) - 1
  horizontal_step_size = div(grid.width, 2)  - 1

  latlon_to_closest_grid_i_search(
    grid,
    (lat, lon),
    (s_to_n_row, w_to_e_col),
    (vertical_step_size, horizontal_step_size)
  )
end

function latlon_to_closest_grid_i_search(grid :: Grid, (target_lat, target_lon) :: Tuple{Float64, Float64}, (s_to_n_row, w_to_e_col) :: Tuple{Int64, Int64}, (vertical_step_size, horizontal_step_size) :: Tuple{Int64, Int64}) :: Int64

  best_distance_squared = 10000000.0^2 # Best distance in "degrees"
  center_is_best = false
  best_s_to_n_row, best_w_to_e_col = (1, 1)

  # down row
  s_to_n_row_to_test = s_to_n_row - vertical_step_size

  if s_to_n_row_to_test >= 1
    w_to_e_col_to_test = w_to_e_col - horizontal_step_size
    if w_to_e_col_to_test >= 1
      flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
      (lat, lon) = grid.latlons[flat_i]
      distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
      if distance_squared < best_distance_squared
        best_distance_squared = distance_squared
        best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
        center_is_best = false
      end
    end

    w_to_e_col_to_test = w_to_e_col
    flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
    (lat, lon) = grid.latlons[flat_i]
    distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
    if distance_squared < best_distance_squared
      best_distance_squared = distance_squared
      best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
      center_is_best = false
    end

    w_to_e_col_to_test = w_to_e_col + horizontal_step_size
    if w_to_e_col_to_test <= grid.width
      flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
      (lat, lon) = grid.latlons[flat_i]
      distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
      if distance_squared < best_distance_squared
        best_distance_squared = distance_squared
        best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
        center_is_best = false
      end
    end
  end

  # center row
  s_to_n_row_to_test = s_to_n_row

  w_to_e_col_to_test = w_to_e_col - horizontal_step_size
  if w_to_e_col_to_test >= 1
    flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
    (lat, lon) = grid.latlons[flat_i]
    distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
    if distance_squared < best_distance_squared
      best_distance_squared = distance_squared
      best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
      center_is_best = false
    end
  end

  w_to_e_col_to_test = w_to_e_col
  flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
  (lat, lon) = grid.latlons[flat_i]
  distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
  if distance_squared < best_distance_squared
    best_distance_squared = distance_squared
    best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
    center_is_best = true
  end

  w_to_e_col_to_test = w_to_e_col + horizontal_step_size
  if w_to_e_col_to_test <= grid.width
    flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
    (lat, lon) = grid.latlons[flat_i]
    distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
    if distance_squared < best_distance_squared
      best_distance_squared = distance_squared
      best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
      center_is_best = false
    end
  end

  # up row
  s_to_n_row_to_test = s_to_n_row + vertical_step_size

  if s_to_n_row_to_test <= grid.height
    w_to_e_col_to_test = w_to_e_col - horizontal_step_size
    if w_to_e_col_to_test >= 1
      flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
      (lat, lon) = grid.latlons[flat_i]
      distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
      if distance_squared < best_distance_squared
        best_distance_squared = distance_squared
        best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
        center_is_best = false
      end
    end

    w_to_e_col_to_test = w_to_e_col
    flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
    (lat, lon) = grid.latlons[flat_i]
    distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
    if distance_squared < best_distance_squared
      best_distance_squared = distance_squared
      best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
      center_is_best = false
    end

    w_to_e_col_to_test = w_to_e_col + horizontal_step_size
    if w_to_e_col_to_test <= grid.width
      flat_i = get_grid_i(grid, (s_to_n_row_to_test, w_to_e_col_to_test))
      (lat, lon) = grid.latlons[flat_i]
      distance_squared = (lat-target_lat)^2 + (lon-target_lon)^2
      if distance_squared < best_distance_squared
        best_distance_squared = distance_squared
        best_s_to_n_row, best_w_to_e_col = (s_to_n_row_to_test, w_to_e_col_to_test)
        center_is_best = false
      end
    end
  end

  if center_is_best && vertical_step_size == 1 && horizontal_step_size == 1
    get_grid_i(grid, (best_s_to_n_row, best_w_to_e_col))
  else
    new_vertical_step_size   = max(1, div(vertical_step_size, 2))
    new_horizontal_step_size = max(1, div(horizontal_step_size, 2))
    latlon_to_closest_grid_i_search(
      grid,
      (target_lat, target_lon),
      (best_s_to_n_row, best_w_to_e_col),
      (new_vertical_step_size, new_horizontal_step_size)
    )
  end
end


# before 2014:
# 04/01/03 00:02:56 49.927 -110.850   -88.3  -10.9 kA  3
# 04/01/03 00:03:54 49.966 -110.984   -71.9   -8.1 kA  2
# ...

# 2014 and later:
# 2014-01-01 00:03:10 40.447  -57.979   260.8   48.8 kA  1
# 2014-01-01 06:18:44 22.895  -87.159  -182.5  -27.0 kA  1
# ...

function mask_from_latlons(latlons)
  mask = BitArray(undef, length(grid_236.latlons))
  mask .= 0

  for latlon in latlons
    flat_i = latlon_to_closest_grid_i(grid_236, latlon)
    mask[flat_i] = 1
  end

  mask
end

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

    mask = mask_from_latlons(latlons_in_hour)

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
