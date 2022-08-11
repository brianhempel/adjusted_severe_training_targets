push!(LOAD_PATH, @__DIR__)

import DelimitedFiles
import Grids
import WeightedKNN
using Utils

const asos_gustiness_path = joinpath(@__DIR__, "out", "asos_gustiness.csv")

function writeout_weighted_knn(latlons, vals, out_base_path; nneighbors, weight_by)
  out_rows = []

  lk = ReentrantLock()

  out_rows = parallel_map(Grids.grid_130_cropped.latlons) do latlon
    out_val = WeightedKNN.weighted_knn_at_point(latlon, latlons, vals; nneighbors = nneighbors, weight_by = weight_by)
    (latlon[1], latlon[2], out_val)
  end

  open(joinpath(@__DIR__, "out", out_base_path) * ".csv", "w") do f
    println(f, "lat,lon,$out_base_path")
    DelimitedFiles.writedlm(f, out_rows, ',')
  end

  ()
end

function do_it()
  latlons           = Tuple{Float64,Float64}[]
  hour_vals         = Float64[]
  fourhour_vals     = Float64[]
  day_vals          = Float64[]
  hour_sig_vals     = Float64[]
  fourhour_sig_vals = Float64[]
  day_sig_vals      = Float64[]

  headers = nothing
  for line in eachline(asos_gustiness_path)
    if isnothing(headers)
      headers = split(line, ',')
      continue
    end
    wban_id, name, state, lat, lon, ndays, nhours_with_gusts, nfourhours_with_gusts, ndays_with_gusts, nhours_with_sig_gusts, nfourhours_with_sig_gusts, ndays_with_sig_gusts, gust_hours_per_year, gust_fourhours_per_year, gust_days_per_year, sig_gust_hours_per_year, sig_gust_fourhours_per_year, sig_gust_days_per_year, _ = split(line, ',')

    push!(latlons,           parse.(Float64, (lat, lon)))
    push!(hour_vals,         parse(Float64, gust_hours_per_year))
    push!(fourhour_vals,     parse(Float64, gust_fourhours_per_year))
    push!(day_vals,          parse(Float64, gust_days_per_year))
    push!(hour_sig_vals,     parse(Float64, sig_gust_hours_per_year))
    push!(fourhour_sig_vals, parse(Float64, sig_gust_fourhours_per_year))
    push!(day_sig_vals,      parse(Float64, sig_gust_days_per_year))
  end


  # Best (non-sig) is 12 neighbors, σ=150.0km
  # Best for sig gusts is 30 neighbors, σ=125.0km

  writeout_weighted_knn(latlons, hour_vals,         "asos_gust_hours_per_year_grid_130_cropped_blurred";         nneighbors = 12, weight_by = WeightedKNN.gaussian(150))
  writeout_weighted_knn(latlons, fourhour_vals,     "asos_gust_fourhours_per_year_grid_130_cropped_blurred";     nneighbors = 12, weight_by = WeightedKNN.gaussian(150))
  writeout_weighted_knn(latlons, day_vals,          "asos_gust_days_per_year_grid_130_cropped_blurred";          nneighbors = 12, weight_by = WeightedKNN.gaussian(150))
  writeout_weighted_knn(latlons, hour_sig_vals,     "asos_sig_gust_hours_per_year_grid_130_cropped_blurred";     nneighbors = 30, weight_by = WeightedKNN.gaussian(125))
  writeout_weighted_knn(latlons, fourhour_sig_vals, "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred"; nneighbors = 30, weight_by = WeightedKNN.gaussian(125))
  writeout_weighted_knn(latlons, day_sig_vals,      "asos_sig_gust_days_per_year_grid_130_cropped_blurred";      nneighbors = 30, weight_by = WeightedKNN.gaussian(125))
end

do_it()
