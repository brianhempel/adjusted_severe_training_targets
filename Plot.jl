push!(LOAD_PATH, @__DIR__)
using Utils
import GMTPlot

const asos_gustiness_path                                            = joinpath(@__DIR__, "out", "asos_gustiness.csv")
const asos_gust_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "asos_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "asos_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_gust_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "asos_gust_days_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "asos_sig_gust_hours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred.csv")
const asos_sig_gust_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "asos_sig_gust_days_per_year_grid_130_cropped_blurred.csv")

const estimated_report_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "estimated_report_hours_per_year_grid_130_cropped_blurred.csv")
const estimated_report_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "estimated_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const estimated_report_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "estimated_report_days_per_year_grid_130_cropped_blurred.csv")
const estimated_sig_report_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "estimated_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
const estimated_sig_report_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "estimated_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const estimated_sig_report_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "estimated_sig_report_days_per_year_grid_130_cropped_blurred.csv")

const estimated_edwards_adjusted_report_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "estimated_edwards_adjusted_report_hours_per_year_grid_130_cropped_blurred.csv")
const estimated_edwards_adjusted_report_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "estimated_edwards_adjusted_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const estimated_edwards_adjusted_report_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "estimated_edwards_adjusted_report_days_per_year_grid_130_cropped_blurred.csv")
const estimated_edwards_adjusted_sig_report_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "estimated_edwards_adjusted_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
const estimated_edwards_adjusted_sig_report_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "estimated_edwards_adjusted_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const estimated_edwards_adjusted_sig_report_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "estimated_edwards_adjusted_sig_report_days_per_year_grid_130_cropped_blurred.csv")

hour_reweighting_grid_130_cropped_path(factor)          = joinpath(@__DIR__, "out", "hour_x$(factor)_reweighting_grid_130_cropped.csv")
fourhour_reweighting_grid_130_cropped_path(factor)      = joinpath(@__DIR__, "out", "fourhour_x$(factor)_reweighting_grid_130_cropped.csv")
day_reweighting_grid_130_cropped_path(factor)           = joinpath(@__DIR__, "out", "day_x$(factor)_reweighting_grid_130_cropped.csv")
sig_hour_reweighting_grid_130_cropped_path(factor)      = joinpath(@__DIR__, "out", "sig_hour_x$(factor)_reweighting_grid_130_cropped.csv")
sig_fourhour_reweighting_grid_130_cropped_path(factor)  = joinpath(@__DIR__, "out", "sig_fourhour_x$(factor)_reweighting_grid_130_cropped.csv")
sig_day_reweighting_grid_130_cropped_path(factor)       = joinpath(@__DIR__, "out", "sig_day_x$(factor)_reweighting_grid_130_cropped.csv")

estimated_reweighted_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_report_days_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_sig_report_days_per_year_grid_130_cropped_blurred.csv")

const measured_report_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "measured_report_hours_per_year_grid_130_cropped_blurred.csv")
const measured_report_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const measured_report_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "measured_report_days_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")

const all_report_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "all_report_hours_per_year_grid_130_cropped_blurred.csv")
const all_report_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "all_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const all_report_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "all_report_days_per_year_grid_130_cropped_blurred.csv")
const all_sig_report_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "all_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
const all_sig_report_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "all_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const all_sig_report_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "all_sig_report_days_per_year_grid_130_cropped_blurred.csv")

estimated_reweighted_plus_measured_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_plus_measured_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_plus_measured_report_days_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_reweighted_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "out", "estimated_x$(factor)_reweighted_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")


const colors_path_40          = joinpath(@__DIR__, "colors", "colors_40.cpt")
const colors_path_10          = joinpath(@__DIR__, "colors", "colors_10.cpt")
const colors_path_5           = joinpath(@__DIR__, "colors", "colors_5.cpt")
const colors_path_2           = joinpath(@__DIR__, "colors", "colors_2.cpt")
const colors_path_1           = joinpath(@__DIR__, "colors", "colors_1.cpt")
const colors_path_0_5         = joinpath(@__DIR__, "colors", "colors_0.5.cpt")
const colors_path_reweighting = joinpath(@__DIR__, "colors", "colors_reweighting.cpt")


function plot_one(title, station_vals, interpolation_path; zlow, zhigh, steps, colors, label_contours = true)
  base_path    = replace(lowercase(title), "/" => "_per_", " + " => "_plus_", "-" => "", r"[^a-z0-9_]+" => "_")
  title        = replace(title, r" x\d+ " => " ") # Don't put the correction factor in the title
  grid_latlons = Tuple{Float64,Float64}[]
  grid_vals    = Float64[]

  if !isfile(interpolation_path)
    println(stderr, "$interpolation_path doesn't exist! skipping plot")
    return
  end

  headers = nothing
  for line in eachline(interpolation_path)
    if isnothing(headers)
      headers = split(line, ',')
      continue
    end
    lat, lon, val = parse.(Float64, split(line, ','))

    push!(grid_latlons, (lat, lon))
    push!(grid_vals, val)
  end

  GMTPlot.plot_map(joinpath("plots", base_path), grid_latlons, grid_vals; title = title, sparse_vals = station_vals, zlow = zlow, zhigh = zhigh, steps = steps, colors = colors, label_contours = label_contours)
end

function plot_asos()
  hour_station_vals         = Tuple{Tuple{Float64,Float64},Float64}[]
  fourhour_station_vals     = Tuple{Tuple{Float64,Float64},Float64}[]
  day_station_vals          = Tuple{Tuple{Float64,Float64},Float64}[]
  hour_sig_station_vals     = Tuple{Tuple{Float64,Float64},Float64}[]
  fourhour_sig_station_vals = Tuple{Tuple{Float64,Float64},Float64}[]
  day_sig_station_vals      = Tuple{Tuple{Float64,Float64},Float64}[]

  headers = nothing
  for line in eachline(asos_gustiness_path)
    if isnothing(headers)
      headers = split(line, ',')
      continue
    end
    wban_id, name, state, lat, lon, ndays, nhours_with_gusts, nfourhours_with_gusts, ndays_with_gusts, nhours_with_sig_gusts, nfourhours_with_sig_gusts, ndays_with_sig_gusts, gust_hours_per_year, gust_fourhours_per_year, gust_days_per_year, sig_gust_hours_per_year, sig_gust_fourhours_per_year, sig_gust_days_per_year, _ = split(line, ',')

    latlon = parse.(Float64, (lat, lon))
    push!(hour_station_vals,         (latlon, parse(Float64, gust_hours_per_year)))
    push!(fourhour_station_vals,     (latlon, parse(Float64, gust_fourhours_per_year)))
    push!(day_station_vals,          (latlon, parse(Float64, gust_days_per_year)))
    push!(hour_sig_station_vals,     (latlon, parse(Float64, sig_gust_hours_per_year)))
    push!(fourhour_sig_station_vals, (latlon, parse(Float64, sig_gust_fourhours_per_year)))
    push!(day_sig_station_vals,      (latlon, parse(Float64, sig_gust_days_per_year)))
  end

  @sync begin
    @async plot_one("ASOS Severe Gust Hours/Year",      hour_station_vals,         asos_gust_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
    @async plot_one("ASOS Severe Gust Four-Hours/Year", fourhour_station_vals,     asos_gust_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
    @async plot_one("ASOS Severe Gust Days/Year",       day_station_vals,          asos_gust_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
    @async plot_one("ASOS Sig. Gust Hours/Year",        hour_sig_station_vals,     asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
    @async plot_one("ASOS Sig. Gust Four-Hours/Year",   fourhour_sig_station_vals, asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
    @async plot_one("ASOS Sig. Gust Days/Year",         day_sig_station_vals,      asos_sig_gust_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
  end
end

function plot_reports()
  @sync begin
    @async plot_one("Estimated Report Hours/Year",           nothing, estimated_report_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("Estimated Report Four-Hours/Year",      nothing, estimated_report_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("Estimated Report Days/Year",            nothing, estimated_report_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("Estimated Sig. Report Hours/Year",      nothing, estimated_sig_report_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
    @async plot_one("Estimated Sig. Report Four-Hours/Year", nothing, estimated_sig_report_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
    @async plot_one("Estimated Sig. Report Days/Year",       nothing, estimated_sig_report_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
  end

  @sync begin
    @async plot_one("Edwards et al. 2018 Adjusted Estimated Report Hours/Year",           nothing, estimated_edwards_adjusted_report_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 5, steps = 5, colors = colors_path_5)
    @async plot_one("Edwards et al. 2018 Adjusted Estimated Report Four-Hours/Year",      nothing, estimated_edwards_adjusted_report_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 5, steps = 5, colors = colors_path_5)
    @async plot_one("Edwards et al. 2018 Adjusted Estimated Report Days/Year",            nothing, estimated_edwards_adjusted_report_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 5, steps = 5, colors = colors_path_5)
    @async plot_one("Edwards et al. 2018 Adjusted Estimated Sig. Report Hours/Year",      nothing, estimated_edwards_adjusted_sig_report_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 1, steps = 5, colors = colors_path_1)
    @async plot_one("Edwards et al. 2018 Adjusted Estimated Sig. Report Four-Hours/Year", nothing, estimated_edwards_adjusted_sig_report_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 1, steps = 5, colors = colors_path_1)
    @async plot_one("Edwards et al. 2018 Adjusted Estimated Sig. Report Days/Year",       nothing, estimated_edwards_adjusted_sig_report_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 1, steps = 5, colors = colors_path_1)
  end

  @sync begin
    @async plot_one("Measured Report Hours/Year",           nothing, measured_report_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
    @async plot_one("Measured Report Four-Hours/Year",      nothing, measured_report_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
    @async plot_one("Measured Report Days/Year",            nothing, measured_report_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
    @async plot_one("Measured Sig. Report Hours/Year",      nothing, measured_sig_report_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 2,  steps = 10,  colors = colors_path_2)
    @async plot_one("Measured Sig. Report Four-Hours/Year", nothing, measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 2,  steps = 10,  colors = colors_path_2)
    @async plot_one("Measured Sig. Report Days/Year",       nothing, measured_sig_report_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 2,  steps = 10,  colors = colors_path_2)
  end

  @sync begin
    @async plot_one("All Report Hours/Year",           nothing, all_report_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("All Report Four-Hours/Year",      nothing, all_report_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("All Report Days/Year",            nothing, all_report_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("All Sig. Report Hours/Year",      nothing, all_sig_report_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
    @async plot_one("All Sig. Report Four-Hours/Year", nothing, all_sig_report_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
    @async plot_one("All Sig. Report Days/Year",       nothing, all_sig_report_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
  end

  for correction_factor in 1:10
    @sync begin
      @async plot_one("Hour x$(correction_factor) Reweighting Factors",           nothing, hour_reweighting_grid_130_cropped_path(correction_factor);          zlow = 0, zhigh = 1, steps = 10, colors = colors_path_reweighting)
      @async plot_one("Four-Hour x$(correction_factor) Reweighting Factors",      nothing, fourhour_reweighting_grid_130_cropped_path(correction_factor);      zlow = 0, zhigh = 1, steps = 10, colors = colors_path_reweighting)
      @async plot_one("Day x$(correction_factor) Reweighting Factors",            nothing, day_reweighting_grid_130_cropped_path(correction_factor);           zlow = 0, zhigh = 1, steps = 10, colors = colors_path_reweighting)
      @async plot_one("Sig. Hour x$(correction_factor) Reweighting Factors",      nothing, sig_hour_reweighting_grid_130_cropped_path(correction_factor);      zlow = 0, zhigh = 1, steps = 10, colors = colors_path_reweighting)
      @async plot_one("Sig. Four-Hour x$(correction_factor) Reweighting Factors", nothing, sig_fourhour_reweighting_grid_130_cropped_path(correction_factor);  zlow = 0, zhigh = 1, steps = 10, colors = colors_path_reweighting)
      @async plot_one("Sig. Day x$(correction_factor) Reweighting Factors",       nothing, sig_day_reweighting_grid_130_cropped_path(correction_factor);       zlow = 0, zhigh = 1, steps = 10, colors = colors_path_reweighting)
    end

    @sync begin
      @async plot_one("Estimated x$(correction_factor) Reweighted Report Hours/Year",           nothing, estimated_reweighted_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);         zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
      @async plot_one("Estimated x$(correction_factor) Reweighted Report Four-Hours/Year",      nothing, estimated_reweighted_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
      @async plot_one("Estimated x$(correction_factor) Reweighted Report Days/Year",            nothing, estimated_reweighted_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);          zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
      @async plot_one("Estimated x$(correction_factor) Reweighted Sig. Report Hours/Year",      nothing, estimated_reweighted_sig_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
      @async plot_one("Estimated x$(correction_factor) Reweighted Sig. Report Four-Hours/Year", nothing, estimated_reweighted_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor); zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
      @async plot_one("Estimated x$(correction_factor) Reweighted Sig. Report Days/Year",       nothing, estimated_reweighted_sig_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);      zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
    end

    @sync begin
      @async plot_one("Estimated x$(correction_factor) Reweighted + Measured Report Hours/Year",           nothing, estimated_reweighted_plus_measured_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);         zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
      @async plot_one("Estimated x$(correction_factor) Reweighted + Measured Report Four-Hours/Year",      nothing, estimated_reweighted_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
      @async plot_one("Estimated x$(correction_factor) Reweighted + Measured Report Days/Year",            nothing, estimated_reweighted_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);          zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
      @async plot_one("Estimated x$(correction_factor) Reweighted + Measured Sig. Report Hours/Year",      nothing, estimated_reweighted_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 2,  steps = 10, colors = colors_path_2)
      @async plot_one("Estimated x$(correction_factor) Reweighted + Measured Sig. Report Four-Hours/Year", nothing, estimated_reweighted_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor); zlow = 0, zhigh = 2,  steps = 10, colors = colors_path_2)
      @async plot_one("Estimated x$(correction_factor) Reweighted + Measured Sig. Report Days/Year",       nothing, estimated_reweighted_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);      zlow = 0, zhigh = 2,  steps = 10, colors = colors_path_2)
    end
  end
end

plot_asos()
plot_reports()

# @sync begin
#   @async plot_one("verifiability_mask",     nothing, joinpath(@__DIR__, "out", "verifiability_mask.csv");     zlow = 0, zhigh = 1, steps = 1, colors = colors_path_reweighting, label_contours = false)
#   @async plot_one("verifiability_mask_sig", nothing, joinpath(@__DIR__, "out", "verifiability_mask_sig.csv"); zlow = 0, zhigh = 1, steps = 1, colors = colors_path_reweighting, label_contours = false)
# end

# import Grids
# push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "storm_data_reports"))
# import WindReports

# function plot_near_est_report()
#   conus_latlons = Grids.grid_130_cropped.latlons[Grids.grid_130_cropped_conus_mask]
#   estimated_reports = filter(e -> !e.measured, WindReports.conus_severe_wind_reports)

#   report_counts = parallel_map(conus_latlons) do latlon
#     count(estimated_reports) do report
#       WindReports.report_is_within_25mi(latlon, report)
#     end
#   end

#   @sync for n in 1:10
#     @async GMTPlot.plot_map(joinpath("explorations", "within_25mi_of_$(n)_estimated_reports"),  conus_latlons, Float32.(report_counts .>= n) ; title = "within_25mi_of_$(n)_estimated_reports")
#   end
# end

# plot_near_est_report()