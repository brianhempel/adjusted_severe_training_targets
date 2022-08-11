import Dates
import Printf

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids

push!(LOAD_PATH, joinpath(@__DIR__, "..", "storm_data_reports"))

import WindReports

const out_dir = @__DIR__

MINUTE = 60

function do_it(reports)
  t     = Dates.DateTime(2003,1,1,0)
  end_t = Dates.DateTime(2022,1,1,0)

  while t < end_t
    # yyyymm        = Printf.@sprintf "%04d%02d"            Dates.year(t) Dates.month(t)
    # yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" Dates.year(t) Dates.month(t) Dates.day(t) Dates.hour(t)

    # mucape_path    = joinpath(mucape_at_least_one_gridded_dir, yyyymm, yyyymmdd_hh00 * ".bits")

    print("\r$t     ")

    # Reports from t to t+1hr

    seconds_from_utc_epoch = Int64(Dates.datetime2unix(t))
    segments = Grids.event_segments_around_time(reports, seconds_from_utc_epoch + 30*MINUTE, 30*MINUTE)

    latlons_in_hour = Tuple{Float64, Float64}[]

    for (latlon1, latlon2) in segments
      if latlon1 == latlon2
        push!(latlons_in_hour, latlon1)
      else
        # start, end, and 25%, 50%, and 75% intermediate points on segment
        push!(latlons_in_hour, latlon1)
        push!(latlons_in_hour, Grids.ratio_on_segment(latlon1, latlon2, 0.25))
        push!(latlons_in_hour, Grids.ratio_on_segment(latlon1, latlon2, 0.5))
        push!(latlons_in_hour, Grids.ratio_on_segment(latlon1, latlon2, 0.75))
        push!(latlons_in_hour, latlon2)
      end
    end

    mask = Grids.mask_from_latlons(Grids.grid_236, latlons_in_hour)

    print(Float32(count(mask) / length(mask))*100)
    print("%         ")

    yyyymm        = Printf.@sprintf "%04d%02d"            Dates.year(t) Dates.month(t)
    yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" Dates.year(t) Dates.month(t) Dates.day(t) Dates.hour(t)

    mkpath(joinpath(out_dir, yyyymm))
    out_path = joinpath(out_dir, yyyymm, yyyymmdd_hh00 * ".bits")
    write(out_path, mask)

    t += Dates.Hour(1)
  end
end

do_it(WindReports.conus_severe_wind_reports)
