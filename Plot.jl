push!(LOAD_PATH, @__DIR__)
using Utils

import DelimitedFiles

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

hour_normalization_grid_130_cropped_path(factor)          = joinpath(@__DIR__, "out", "hour_x$(factor)_normalization_grid_130_cropped.csv")
fourhour_normalization_grid_130_cropped_path(factor)      = joinpath(@__DIR__, "out", "fourhour_x$(factor)_normalization_grid_130_cropped.csv")
day_normalization_grid_130_cropped_path(factor)           = joinpath(@__DIR__, "out", "day_x$(factor)_normalization_grid_130_cropped.csv")
sig_hour_normalization_grid_130_cropped_path(factor)      = joinpath(@__DIR__, "out", "sig_hour_x$(factor)_normalization_grid_130_cropped.csv")
sig_fourhour_normalization_grid_130_cropped_path(factor)  = joinpath(@__DIR__, "out", "sig_fourhour_x$(factor)_normalization_grid_130_cropped.csv")
sig_day_normalization_grid_130_cropped_path(factor)       = joinpath(@__DIR__, "out", "sig_day_x$(factor)_normalization_grid_130_cropped.csv")

estimated_normalized_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_report_days_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_sig_report_days_per_year_grid_130_cropped_blurred.csv")

const measured_report_hours_per_year_grid_130_cropped_blurred_path         = joinpath(@__DIR__, "out", "measured_report_hours_per_year_grid_130_cropped_blurred.csv")
const measured_report_fourhours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const measured_report_days_per_year_grid_130_cropped_blurred_path          = joinpath(@__DIR__, "out", "measured_report_days_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_hours_per_year_grid_130_cropped_blurred_path     = joinpath(@__DIR__, "out", "measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path = joinpath(@__DIR__, "out", "measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
const measured_sig_report_days_per_year_grid_130_cropped_blurred_path      = joinpath(@__DIR__, "out", "measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")

estimated_normalized_plus_measured_report_hours_per_year_grid_130_cropped_blurred_path(factor)         = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(factor)          = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_report_days_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred_path(factor)     = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(factor) = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred.csv")
estimated_normalized_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred_path(factor)      = joinpath(@__DIR__, "out", "estimated_x$(factor)_normalized_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred.csv")


const colors_path_40            = joinpath(@__DIR__, "colors", "colors_40.cpt")
const colors_path_10            = joinpath(@__DIR__, "colors", "colors_10.cpt")
const colors_path_5             = joinpath(@__DIR__, "colors", "colors_5.cpt")
const colors_path_2             = joinpath(@__DIR__, "colors", "colors_2.cpt")
const colors_path_1             = joinpath(@__DIR__, "colors", "colors_1.cpt")
const colors_path_0_5           = joinpath(@__DIR__, "colors", "colors_0.5.cpt")
const colors_path_normalization = joinpath(@__DIR__, "colors", "colors_normalization.cpt")

# Plots the vals
# Color scheme choices: http://gmt.soest.hawaii.edu/doc/latest/GMT_Docs.html#built-in-color-palette-tables-cpt
function plot_map(base_path, latlons, vals; title=nothing, zlow=minimum(vals), zhigh=maximum(vals), steps=10, sparse_vals=nothing, colors="tofino", pdf=false, label_contours=true)
  # GMT sets internal working directory based on parent pid, so run in sh so each has a diff parent pid.
  open(base_path * ".sh", "w") do f

    println(f, "projection=-Jl-100/35/33/45/0.3")
    println(f, "region=-R-120.7/22.8/-63.7/47.7+r # +r makes the map square rather than weird shaped")

    if vals != []
      open(base_path * ".xyz", "w") do f
        # lon lat val
        DelimitedFiles.writedlm(f, map(i -> (latlons[i][2], latlons[i][1], vals[i]), 1:length(vals)), '\t')
      end

      # println(f, "gmt nearneighbor $base_path.xyz -R-134/-61/21.2/52.5 -I2k -Nn -G$base_path.nc  # interpolate the xyz coordinates to a grid")
      println(f, "gmt sphinterpolate $base_path.xyz -R-134/-61/21.2/52.5 -I2k -Q0 -G$base_path.nc  # interpolate the xyz coordinates to a grid")
    end

    range     = zhigh - zlow
    step_size = range / steps

    cpt_path =
      if endswith(colors, ".cpt")
        colors
      else
        println(f, "gmt makecpt -C$colors -T$zlow/$zhigh/$step_size > $base_path.cpt")
        "$base_path.cpt"
      end

    println(f, "gmt begin $base_path pdf")

    println(f, "gmt coast \$region \$projection -B+g240/245/255+n -ENA -Gc # Use the color of water for the background and begin clipping to north america")

    if vals != []
      println(f, "gmt grdimage $base_path.nc -nn \$region \$projection -C$cpt_path # draw the vals using the projection")
      label_contours && println(f, "gmt grdcontour $(base_path).nc \$region \$projection -A+f3p+i -W0.2p,70/70/70 -C$cpt_path -Gd2i # draw labels on each contour")
    end

    # println(f, "gmt sphtriangulate $base_path.xyz -Qv > triangulated")
    # println(f, "gmt triangulate $base_path.xyz -M -Qn \$region \$projection > triangulated")
    # println(f, "gmt plot triangulated \$region \$projection -L -C$cpt_path")

    # sparsevals should be a vec of (latlon, val)
    if !isnothing(sparse_vals)
      # Plot individual obs
      open(base_path * "_sparse.xyz", "w") do f
        # lon lat val
        DelimitedFiles.writedlm(f, map(i -> (sparse_vals[i][1][2], sparse_vals[i][1][1], sparse_vals[i][2]), 1:length(sparse_vals)), '\t')
      end
      println(f, "gmt plot $(base_path)_sparse.xyz -Sc0.07 -W0.25p \$region \$projection -C$cpt_path")
    end
    println(f, "gmt coast -Q # stop clipping")

    println(f, "gmt coast \$region \$projection -A500 -N2/thinnest -t65 # draw state borders 65% transparent")
    println(f, "gmt coast \$region \$projection -A500 -N1 -Wthinnest -t45 # draw country borders and coastlines 45% transparent")

    # Draw legend box.
    if !isnothing(title)
      println(f, "gmt legend -Dx0.04i/0.04i+w1.7i+l1.3 -C0.03i/0.03i -F+gwhite+pthin << EOF")
      println(f, "L 3.5pt,Helvetica-Bold C $title")
      println(f, "L 7pt,Helvetica-Bold C ") # blank line
      println(f, "L 7pt,Helvetica-Bold C ") # blank line
      println(f, "EOF")
    end

    if endswith(colors, ".cpt")
      # println(f, "gmt colorbar --FONT_ANNOT_PRIMARY=4p,Helvetica --MAP_FRAME_PEN=0.5p --MAP_TICK_PEN_PRIMARY=0.5p -Dx0.25i/0.25i+w1.3i+h -S -L0i -Np -C$cpt_path")
      println(f, "gmt colorbar --FONT_ANNOT_PRIMARY=4p,Helvetica --MAP_FRAME_PEN=0.5p --MAP_TICK_PEN_PRIMARY=0.5p -Dx0.25i/0.25i+w1.3i+h -S -Bx$(step_size) -Np -C$cpt_path")
    else
      println(f, "gmt colorbar --FONT_ANNOT_PRIMARY=4p,Helvetica --MAP_FRAME_PEN=0.5p --MAP_TICK_PEN_PRIMARY=0.5p -Dx0.25i/0.25i+w1.3i+h -S -Ba$(range/2) -Np -C$cpt_path")
    end

    println(f, "gmt end")

    if !pdf
      println(f, "pdftoppm $base_path.pdf $base_path -png -r 300 -singlefile")
      # reduce png size
      println(f, "which pngquant && pngquant 128 --nofs --ext -quantized.png $base_path.png && rm $base_path.png && mv $base_path-quantized.png $base_path.png")
      println(f, "which oxipng && oxipng  -o max --strip safe --libdeflater $base_path.png")
      println(f, "rm $base_path.pdf")
    end
    if vals != []
      println(f, "rm $base_path.nc")
      println(f, "rm $base_path.xyz")
    end
    !isnothing(sparse_vals)   && println(f, "rm $(base_path)_sparse.xyz")
    !endswith(colors, ".cpt") && println(f, "rm $base_path.cpt")
  end

  run(`sh $base_path.sh`)
  rm(base_path * ".sh")

  ()
end

function plot_one(base_path, station_vals, interpolation_path; zlow, zhigh, steps, colors, label_contours = true)
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

  plot_map(joinpath("plots", base_path), grid_latlons, grid_vals; title = base_path, sparse_vals = station_vals, zlow = zlow, zhigh = zhigh, steps = steps, colors = colors, label_contours = label_contours)
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
    @async plot_one("asos_gust_hours_per_year",         hour_station_vals,         asos_gust_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
    @async plot_one("asos_gust_fourhours_per_year",     fourhour_station_vals,     asos_gust_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
    @async plot_one("asos_gust_days_per_year",          day_station_vals,          asos_gust_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 5,   steps = 5, colors = colors_path_5)
    @async plot_one("asos_sig_gust_hours_per_year",     hour_sig_station_vals,     asos_sig_gust_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
    @async plot_one("asos_sig_gust_fourhours_per_year", fourhour_sig_station_vals, asos_sig_gust_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
    @async plot_one("asos_sig_gust_days_per_year",      day_sig_station_vals,      asos_sig_gust_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 0.5, steps = 5, colors = colors_path_0_5)
  end
end

function plot_reports()
  @sync begin
    @async plot_one("estimated_report_hours_per_year",         nothing, estimated_report_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("estimated_report_fourhours_per_year",     nothing, estimated_report_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("estimated_report_days_per_year",          nothing, estimated_report_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 40, steps = 10, colors = colors_path_40)
    @async plot_one("estimated_sig_report_hours_per_year",     nothing, estimated_sig_report_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
    @async plot_one("estimated_sig_report_fourhours_per_year", nothing, estimated_sig_report_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
    @async plot_one("estimated_sig_report_days_per_year",      nothing, estimated_sig_report_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 5,  steps = 5,  colors = colors_path_5)
  end

  @sync begin
    @async plot_one("measured_report_hours_per_year",         nothing, measured_report_hours_per_year_grid_130_cropped_blurred_path;         zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
    @async plot_one("measured_report_fourhours_per_year",     nothing, measured_report_fourhours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
    @async plot_one("measured_report_days_per_year",          nothing, measured_report_days_per_year_grid_130_cropped_blurred_path;          zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
    @async plot_one("measured_sig_report_hours_per_year",     nothing, measured_sig_report_hours_per_year_grid_130_cropped_blurred_path;     zlow = 0, zhigh = 2,  steps = 10,  colors = colors_path_2)
    @async plot_one("measured_sig_report_fourhours_per_year", nothing, measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path; zlow = 0, zhigh = 2,  steps = 10,  colors = colors_path_2)
    @async plot_one("measured_sig_report_days_per_year",      nothing, measured_sig_report_days_per_year_grid_130_cropped_blurred_path;      zlow = 0, zhigh = 2,  steps = 10,  colors = colors_path_2)
  end

  for correction_factor in 1:10
    @sync begin
      @async plot_one("hour_x$(correction_factor)_normalization",          nothing, hour_normalization_grid_130_cropped_path(correction_factor);          zlow = 0, zhigh = 1, steps = 10, colors = colors_path_normalization)
      @async plot_one("fourhour_x$(correction_factor)_normalization",      nothing, fourhour_normalization_grid_130_cropped_path(correction_factor);      zlow = 0, zhigh = 1, steps = 10, colors = colors_path_normalization)
      @async plot_one("day_x$(correction_factor)_normalization",           nothing, day_normalization_grid_130_cropped_path(correction_factor);           zlow = 0, zhigh = 1, steps = 10, colors = colors_path_normalization)
      @async plot_one("sig_hour_x$(correction_factor)_normalization",      nothing, sig_hour_normalization_grid_130_cropped_path(correction_factor);      zlow = 0, zhigh = 1, steps = 10, colors = colors_path_normalization)
      @async plot_one("sig_fourhour_x$(correction_factor)_normalization",  nothing, sig_fourhour_normalization_grid_130_cropped_path(correction_factor);  zlow = 0, zhigh = 1, steps = 10, colors = colors_path_normalization)
      @async plot_one("sig_day_x$(correction_factor)_normalization",       nothing, sig_day_normalization_grid_130_cropped_path(correction_factor);       zlow = 0, zhigh = 1, steps = 10, colors = colors_path_normalization)
    end

    @sync begin
      @async plot_one("estimated_x$(correction_factor)_normalized_report_hours_per_year",         nothing, estimated_normalized_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);         zlow = 0, zhigh = 10,  steps = 10, colors = colors_path_10)
      @async plot_one("estimated_x$(correction_factor)_normalized_report_fourhours_per_year",     nothing, estimated_normalized_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 10,  steps = 10, colors = colors_path_10)
      @async plot_one("estimated_x$(correction_factor)_normalized_report_days_per_year",          nothing, estimated_normalized_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);          zlow = 0, zhigh = 10,  steps = 10, colors = colors_path_10)
      @async plot_one("estimated_x$(correction_factor)_normalized_sig_report_hours_per_year",     nothing, estimated_normalized_sig_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 0.5, steps = 5,  colors = colors_path_0_5)
      @async plot_one("estimated_x$(correction_factor)_normalized_sig_report_fourhours_per_year", nothing, estimated_normalized_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor); zlow = 0, zhigh = 0.5, steps = 5,  colors = colors_path_0_5)
      @async plot_one("estimated_x$(correction_factor)_normalized_sig_report_days_per_year",      nothing, estimated_normalized_sig_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);      zlow = 0, zhigh = 0.5, steps = 5,  colors = colors_path_0_5)
    end

    @sync begin
      @async plot_one("estimated_x$(correction_factor)_normalized_plus_measured_report_hours_per_year",         nothing, estimated_normalized_plus_measured_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);         zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
      @async plot_one("estimated_x$(correction_factor)_normalized_plus_measured_report_fourhours_per_year",     nothing, estimated_normalized_plus_measured_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
      @async plot_one("estimated_x$(correction_factor)_normalized_plus_measured_report_days_per_year",          nothing, estimated_normalized_plus_measured_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);          zlow = 0, zhigh = 10, steps = 10, colors = colors_path_10)
      @async plot_one("estimated_x$(correction_factor)_normalized_plus_measured_sig_report_hours_per_year",     nothing, estimated_normalized_plus_measured_sig_report_hours_per_year_grid_130_cropped_blurred_path(correction_factor);     zlow = 0, zhigh = 2,  steps = 10, colors = colors_path_2)
      @async plot_one("estimated_x$(correction_factor)_normalized_plus_measured_sig_report_fourhours_per_year", nothing, estimated_normalized_plus_measured_sig_report_fourhours_per_year_grid_130_cropped_blurred_path(correction_factor); zlow = 0, zhigh = 2,  steps = 10, colors = colors_path_2)
      @async plot_one("estimated_x$(correction_factor)_normalized_plus_measured_sig_report_days_per_year",      nothing, estimated_normalized_plus_measured_sig_report_days_per_year_grid_130_cropped_blurred_path(correction_factor);      zlow = 0, zhigh = 2,  steps = 10, colors = colors_path_2)
    end
  end
end

# plot_asos()
plot_reports()

# @sync begin
#   @async plot_one("verifiability_mask",     nothing, joinpath(@__DIR__, "out", "verifiability_mask.csv");     zlow = 0, zhigh = 1, steps = 1, colors = colors_path_normalization, label_contours = false)
#   @async plot_one("verifiability_mask_sig", nothing, joinpath(@__DIR__, "out", "verifiability_mask_sig.csv"); zlow = 0, zhigh = 1, steps = 1, colors = colors_path_normalization, label_contours = false)
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
#     @async plot_map(joinpath("explorations", "within_25mi_of_$(n)_estimated_reports"),  conus_latlons, Float32.(report_counts .>= n) ; title = "within_25mi_of_$(n)_estimated_reports")
#   end
# end

# plot_near_est_report()