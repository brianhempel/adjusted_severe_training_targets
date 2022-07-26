module Grids

import DelimitedFiles

struct Grid
  height  :: Int64 # Element count
  width   :: Int64 # Element count
  latlons :: Vector{Tuple{Float64,Float64}} # Ordering is row-major: W -> E, S -> N
end

const grid_236 = begin
  cells = DelimitedFiles.readdlm(joinpath(@__DIR__, "grid_236.csv"), ',', Float64; header = true)[1]
  latlons = mapslices(cells; dims=[2]) do row
    (row[3], row[4] > 180.0 ? row[4] - 360.0 : row[4])
  end[:,1]

  Grid(
    maximum(@view cells[:,2]), # height
    maximum(@view cells[:,1]), # width
    latlons
  )
end

# https://en.wikipedia.org/wiki/List_of_extreme_points_of_the_United_States
const s_extreme = 24.0
const n_extreme = 50.0
const w_extreme = -125.0
const e_extreme = -66.0

# For excluding Alaska, Hawaii, Puerto Rico tornadoes
function is_in_conus_bounding_box((lat, lon))
  lat > s_extreme && lat < n_extreme && lon > w_extreme && lon < e_extreme
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

function mask_from_latlons(grid, latlons)
  mask = BitArray(undef, length(grid.latlons))
  mask .= 0

  for latlon in latlons
    flat_i = Grids.latlon_to_closest_grid_i(grid, latlon)
    mask[flat_i] = 1
  end

  mask
end


const FEET_PER_METER  = 100.0 / 2.54 / 12.0
const METERS_PER_MILE = 5280.0 / FEET_PER_METER

# # FCC method below with some terms removed, but performs just as well.
# # And way better than haversine for the kinds of distances we are dealing with.
# # Error < 0.005% for the distances we are using.
# # Precondition: longitudes don't cross over (raw lon2-lon1 < 180)
# function instant_distance(lat1 :: Float64, lon1 :: Float64, lat2 :: Float64, lon2 :: Float64) :: Float64
#   mean_lat = (lat1 + lat2) / 2.0 / 180.0 * π
#   dlat     = lat2 - lat1
#   dlon     = lon2 - lon1
#
#   k1 = 111.13209 - 0.56605cos(2*mean_lat)
#   k2 = 111.41513cos(mean_lat) - 0.09455cos(3*mean_lat)
#
#   √((k1*dlat)^2 + (k2*dlon)^2) * 1000.0
# end

# Compared to actual calculation on an ellipsoid, error is greatest when
# close to the line (since geodesic follows a different path).
# For the scales we are concerned about, error is always < 0.45%.
# Precondition: longitudes don't cross over (raw lon2-lon1 < 180)
function instant_meters_to_line((lat, lon) :: Tuple{Float64,Float64}, (lat1, lon1) :: Tuple{Float64,Float64}, (lat2, lon2) :: Tuple{Float64,Float64}) :: Float64
  mean_lat = (lat + lat1 + lat2) / 3.0 / 180.0 * π

  k1 = 111.13209 - 0.56605cos(2*mean_lat)
  k2 = 111.41513cos(mean_lat) - 0.09455cos(3*mean_lat)

  # Translate so endpoint 1 is the origin.
  x2 = (lon2 - lon1) * k2
  y2 = (lat2 - lat1) * k1
  x  = (lon  - lon1) * k2
  y  = (lat  - lat1) * k1

  # Unit vector...
  segment_length = √(x2^2 + y2^2)

  if segment_length < 1.0/1000.0 # 1m
    # Segment is essentially 0 length.
    return √(x^2 + y^2) * 1000.0
  else
    ux2 = x2 / segment_length
    uy2 = y2 / segment_length
  end

  # Project onto line
  distance_from_origin_on_line = x*ux2 + y*uy2

  if distance_from_origin_on_line <= 0.0
    # Closer to endpoint 1 (the origin)
    √(x^2 + y^2) * 1000.0
  elseif distance_from_origin_on_line >= segment_length
    # Closer to endpoint 2
    √((x-x2)^2 + (y-y2)^2) * 1000.0
  else
    # Closer to somewhere on the line
    x_proj = ux2 * distance_from_origin_on_line
    y_proj = uy2 * distance_from_origin_on_line

    √((x-x_proj)^2 + (y-y_proj)^2) * 1000.0
  end
end

function miles_to_line((lat, lon) :: Tuple{Float64,Float64}, (lat1, lon1) :: Tuple{Float64,Float64}, (lat2, lon2) :: Tuple{Float64,Float64}) :: Float64
  if abs(lon - lon1) >= 180.0 || abs(lon - lon2) >= 180.0 || abs(lon1 - lon2) >= 180.0
    # instant_meters_to_line calculation is not periodic
    NaN
  else
    instant_meters_to_line((lat, lon), (lat1, lon1), (lat2, lon2)) / Grids.METERS_PER_MILE
  end
end


# FCC method, per Wikipedia https://en.wikipedia.org/wiki/Geographical_distance#Ellipsoidal_Earth_projected_to_a_plane
# Surprisingly good! Generally much less than 0.01% error over short distances, and not completely awful over long distances.
# Precondition: longitudes don't cross over (raw lon2-lon1 < 180)
function instantish_distance((lat1, lon1), (lat2, lon2))
  mean_lat = (lat1 + lat2) / 2.0 / 180.0 * π
  dlat     = lat2 - lat1
  dlon     = lon2 - lon1

  k1 = 111.13209 - 0.56605cos(2*mean_lat) + 0.00120cos(4*mean_lat)
  k2 = 111.41513cos(mean_lat) - 0.09455cos(3*mean_lat) + 0.00012cos(5*mean_lat)

  √((k1*dlat)^2 + (k2*dlon)^2) * 1000.0
end

import Proj4

wgs84 = Proj4.Projection("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
# Julia wrapper doesn't set the geod by default :(
major_axis, eccentricity_squared = Proj4._get_spheroid_defn(wgs84.rep)
wgs84.geod = Proj4.geod_geodesic(major_axis, 1-sqrt(1-eccentricity_squared))

function ratio_on_segment((lat1, lon1) :: Tuple{Float64,Float64}, (lat2, lon2) :: Tuple{Float64,Float64}, ratio :: Float64) :: Tuple{Float64,Float64}
  Proj4.geod_geodesic(major_axis, 1-sqrt(1-eccentricity_squared)) # Omit this line and you get NaNs below. Compiler bug? Almost certainly.
  distance, point_1_azimuth, point_2_azimuth = Proj4._geod_inverse(wgs84.geod, [lon1, lat1], [lon2, lat2])
  if isnan(point_1_azimuth) || isnan(point_2_azimuth)
    println("NaN in GeoUtils.ratio_on_segment!")
    println(((lat1, lon1), (lat2, lon2), distance, point_1_azimuth, point_2_azimuth))
  end
  ratio_point = deepcopy([lon1, lat1]) # call is destructive :(
  Proj4._geod_direct!(wgs84.geod, ratio_point, point_1_azimuth, distance * ratio)
  (ratio_point[2], ratio_point[1])
end

# Events should be a vector of records that have start_seconds_from_epoch_utc, end_seconds_from_epoch_utc, start_latlon, and end_latlon fields.
function event_segments_around_time(events, seconds_from_utc_epoch :: Int64, seconds_before_and_after :: Int64) :: Vector{Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}}
  period_start_seconds = seconds_from_utc_epoch - seconds_before_and_after
  period_end_seconds   = seconds_from_utc_epoch + seconds_before_and_after

  is_relevant_event(event) = begin
    (event.end_seconds_from_epoch_utc  > period_start_seconds &&
    event.start_seconds_from_epoch_utc < period_end_seconds) ||
    # Zero-duration events exactly on the boundary count in the later period
    (event.start_seconds_from_epoch_utc == period_start_seconds && event.end_seconds_from_epoch_utc == period_start_seconds)
  end

  relevant_events = filter(is_relevant_event, events)

  event_to_segment(event) = begin
    start_seconds = event.start_seconds_from_epoch_utc
    end_seconds   = event.end_seconds_from_epoch_utc
    start_latlon  = event.start_latlon
    end_latlon    = event.end_latlon

    duration = event.end_seconds_from_epoch_utc - event.start_seconds_from_epoch_utc

    # Turns out no special case is needed for tornadoes of 0 duration.

    if start_seconds >= period_start_seconds
      seg_start_latlon = start_latlon
    else
      start_ratio = Float64(period_start_seconds - start_seconds) / duration
      seg_start_latlon = Grids.ratio_on_segment(start_latlon, end_latlon, start_ratio)
    end

    if end_seconds <= period_end_seconds
      seg_end_latlon = end_latlon
    else
      # This math is correct
      end_ratio = Float64(period_end_seconds - start_seconds) / duration
      seg_end_latlon = Grids.ratio_on_segment(start_latlon, end_latlon, end_ratio)
    end

    (seg_start_latlon, seg_end_latlon)
  end

  map(event_to_segment, relevant_events)
end

end