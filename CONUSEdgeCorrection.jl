# What to multiply 25mi neighborhood report counts by to componensate for gridpoints on the edge of CONUS that have half
# as much chance to have a report within 25mi.

push!(LOAD_PATH, @__DIR__)

import Grids
using Utils

const latlons = Grids.grid_130_cropped.latlons

function compute_edge_correction(latlon)
  nearby_pts           = parallel_filter(ll -> Grids.instantish_distance(ll, latlon) <= 25 * Grids.METERS_PER_MILE, latlons)
  nnearby_pts_in_conus = count(Grids.is_in_conus_130_cropped, nearby_pts)
  (length(nearby_pts) + 0.5) / (nnearby_pts_in_conus + 0.5) # smoothing factor of 0.5 gridpoints...just a number
end

println("lat,lon,conus_25mi_edge_correction_factor")
for latlon in latlons
  factor = compute_edge_correction(latlon)
  println("$(latlon[1]),$(latlon[2]),$(Float32(factor))")
end
