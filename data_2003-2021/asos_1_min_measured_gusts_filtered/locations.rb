require 'csv'

FEET_PER_METER  = 100.0 / 2.54 / 12.0
METERS_PER_MILE = 5280.0 / FEET_PER_METER

# FCC method, per Wikipedia https://en.wikipedia.org/wiki/Geographical_distance#Ellipsoidal_Earth_projected_to_a_plane
# Surprisingly good! Generally much less than 0.01% error over short distances, and not completely awful over long distances.
# Precondition: longitudes don't cross over (raw lon2-lon1 < 180)
def instantish_distance_miles(lat1, lon1, lat2, lon2)
  mean_lat = (lat1 + lat2) / 2.0 / 180.0 * Math::PI
  dlat     = lat2 - lat1
  dlon     = lon2 - lon1

  k1 = 111.13209 - 0.56605*Math.cos(2*mean_lat) + 0.00120*Math.cos(4*mean_lat)
  k2 = 111.41513*Math.cos(mean_lat) - 0.09455*Math.cos(3*mean_lat) + 0.00012*Math.cos(5*mean_lat)

  Math.sqrt((k1*dlat)**2.0 + (k2*dlon)**2.0) * 1000.0 / METERS_PER_MILE
end

class Array
  def mean
    sum / size.to_f
  end
end

CSV.read("gusts_at_least_50_knots_filtered_tc.csv", headers: true).group_by do |r|
  r["wban_id"]
end.map do |wban_id, rows|
  [wban_id, rows.map {|r| [r["lat"], r["lon"]]}.uniq]
end.sort.select do |wban_id, lls|
  lls.size >= 2
end.map do |wban_id, lls|
  mean_lat = lls.map(&:first).map(&:to_f).mean
  mean_lon = lls.map(&:last).map(&:to_f).mean

  miless = lls.map {|lat, lon| instantish_distance_miles(lat.to_f, lon.to_f, mean_lat, mean_lon)}

  [wban_id, miless.max]
end.sort_by(&:last).each do |asdf|
  p asdf
end