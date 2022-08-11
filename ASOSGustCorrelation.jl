# didn't work

import Dates

push!(LOAD_PATH, @__DIR__)

import ASOSStations
import Grids
using Utils


const sizes = [1:10; 15:5:100] # km

print("km,fourhour_gusts_jaccard_similarity,fourhour_frequency")

for gust_size_km in sizes
  print(",$(gust_size_km)_km_mad")
end
println()

function circles_jaccard(r, d)
  if d >= 2r
    0
  else
    α = 2acos(d/2r) # yes, Julia interprets this as d / (2*r)

    one_circle_area = π*r^2

    overlap_area = 2 * r^2 * (α/2 - cos(α/2)*sin(α/2))

    union_area = 2one_circle_area - overlap_area

    overlap_area / union_area
  end
end

for station1 in ASOSStations.stations
  for station2 in ASOSStations.stations
    station1.wban_id < station2.wban_id || continue

    km = Float32(Grids.instantish_distance(station1.latlon, station2.latlon) / 1000.0)

    km <= 1000 || continue

    shared_fourhours = intersect(station1.legit_fourhours, station2.legit_fourhours)

    length(shared_fourhours) >= 5 * 365.25 * (24 ÷ 4) || continue

    gusts1 = Set(intersect(station1.gust_fourhours, shared_fourhours))
    gusts2 = Set(intersect(station2.gust_fourhours, shared_fourhours))

    shared = intersect(gusts1, gusts2)
    all    = union(gusts1, gusts2)

    length(all) >= 1 || continue

    jaccard_similarity = Float32(length(shared) / length(all))

    # jaccard_similarity = jaccard_similarity == 0 ? rand() * 0.01 - 0.005 : jaccard_similarity

    expected_jaccards = map(sizes) do gust_size_km
      # lots of math on paper to find the area of overlap of two circles of radius r separated by distance d
      r = gust_size_km
      d = km
      circles_jaccard(r, d)
    end

    weight = length(all)

    mads = map(expected_jaccards) do expected_jaccard
      Float32(abs(expected_jaccard - jaccard_similarity) * Float32(weight))
    end

    print("$km,$jaccard_similarity,$(Float32(length(all) / length(shared_fourhours)))")

    for mad in mads
      print(",$mad")
    end
    println()
  end
end
