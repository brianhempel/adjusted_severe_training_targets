module WeightedKNN

push!(LOAD_PATH, @__DIR__)

import Grids

# weighting functions
uniform        = (meters -> 1.0)
gaussian(σ_km) = (meters -> exp(-(meters/1000)^2 / (2 * σ_km^2)))

function weighted_knn_at_point(latlon, latlons, vals; nneighbors = 5, weight_by = uniform)
  distances          = map(val_ll -> Grids.instantish_distance(val_ll, latlon), latlons)
  neighbor_is        = sortperm(distances)[1:nneighbors]
  neighbor_vals      = vals[neighbor_is]
  neighbor_distances = distances[neighbor_is]
  weights            = weight_by.(neighbor_distances)
  out_val            = sum(neighbor_vals .* weights) / sum(weights)
  out_val
end

end