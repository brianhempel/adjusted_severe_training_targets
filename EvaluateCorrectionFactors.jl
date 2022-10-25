import StatsBase

push!(LOAD_PATH, @__DIR__)

import Grids
using Utils


const grid       = Grids.grid_130_cropped
const conus_mask = Grids.grid_130_cropped_conus_mask

const asos_gust_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "asos_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "asos_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "asos_gust_days_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "asos_sig_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "asos_sig_gust_days_per_year_grid_130_cropped_blurred.csv")

estimated_reweighted_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_report_days_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_sig_report_days_per_year_grid_130_cropped_blurred.csv")

estimated_reweighted_plus_measured_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_plus_measured_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_plus_measured_report_days_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "estimated_x$(factor)_reweighted_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")

const measured_report_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "measured_report_hours_per_year_grid_130_cropped_blurred.csv")
const measured_report_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const measured_report_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "measured_report_days_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")


function do_it()
  x = read_3rd_col(asos_gust_days_per_year_grid_130_cropped_blurred_path)[conus_mask]

  for correction_factor in [1,2,3,4,5,6,10]
    y = read_3rd_col(estimated_reweighted_report_days_per_year_grid_130_cropped_blurred_path(correction_factor))[conus_mask]

    cor = StatsBase.corspearman(x, y)

    println("Correction factor $correction_factor,\tno measured reports, spearman correlation: $(Float32(cor))")
  end

  y = read_3rd_col(measured_report_days_per_year_grid_130_cropped_blurred_path)[conus_mask]

  cor = StatsBase.corspearman(x, y)

  println("Correction factor 0\tspearman correlation: $(Float32(cor))")

  for correction_factor in [1,2,3,4,5,6,10]
    y = read_3rd_col(estimated_reweighted_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(correction_factor))[conus_mask]

    cor = StatsBase.corspearman(x, y)

    println("Correction factor $correction_factor\tspearman correlation: $(Float32(cor))")
  end
end

do_it()
