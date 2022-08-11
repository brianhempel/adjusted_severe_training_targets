import StatsBase

push!(LOAD_PATH, @__DIR__)

import Grids
using Utils


const grid       = Grids.grid_130_cropped
const conus_mask = Grids.grid_130_cropped_conus_mask

# const asos_gust_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "asos_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "asos_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
# const asos_gust_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "asos_gust_days_per_year_grid_130_cropped_blurred.csv")
# const asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "asos_sig_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
# const asos_sig_gust_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "asos_sig_gust_days_per_year_grid_130_cropped_blurred.csv")

# estimated_normalized_plus_measured_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
# estimated_normalized_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_report_days_per_year_grid_130_cropped_blurred.csv")
# estimated_normalized_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
# estimated_normalized_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")

if get(ARGS, 1, "") == "sig"
  target   = read_3rd_col(asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path)
  reported = read_3rd_col(estimated_normalized_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(1))
else
  target   = read_3rd_col(asos_gust_fourhours_per_year_grid_130_cropped_blurred_path)
  reported = read_3rd_col(estimated_normalized_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(1))
end

vals = Float32.(reported ./ target .>= 0.5 .&& conus_mask)

println("lat,lon,verifiability_mask")
for (val, latlon) in zip(vals, grid.latlons)
  println("$(latlon[1]),$(latlon[2]),$val")
end
