import Dates

push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids

# Commented out parts are to figure out when severe gusts do not get coded as t-storm reports
#
# "filtered gusts vs wind reports by distance from cyclone track.png" has a copy of these results

# module WindEvents
#   import Dates
#   import DelimitedFiles

#   import Grids

#   const wind_events_path = joinpath(@__DIR__, "..", "storm_data_reports", "wind_events_2003-2021.csv")


#   MINUTE = 60
#   HOUR   = 60*MINUTE
#   # DAY    = 24*HOUR

#   struct Event
#     start_seconds_from_epoch_utc :: Int64
#     end_seconds_from_epoch_utc   :: Int64
#     start_latlon                 :: Tuple{Float64, Float64}
#     end_latlon                   :: Tuple{Float64, Float64}
#     knots     :: Float64
#     sustained :: Bool # false == gust
#     measured  :: Bool
#   end

#   is_severe_wind(wind_event) = wind_event.knots  >= 50.0
#   is_sig_wind(wind_event)    = wind_event.knots  >= 65.0

#   function event_looks_okay(event :: Event) :: Bool
#     duration = event.end_seconds_from_epoch_utc - event.start_seconds_from_epoch_utc
#     if duration >= 4*HOUR
#       println("Event starting $(Dates.unix2datetime(event.start_seconds_from_epoch_utc)) ending $(Dates.unix2datetime(event.end_seconds_from_epoch_utc)) is $(duration / HOUR) hours long! discarding")
#       false
#     elseif duration < 0
#       println("Event starting $(Dates.unix2datetime(event.start_seconds_from_epoch_utc)) ending $(Dates.unix2datetime(event.end_seconds_from_epoch_utc)) is $(duration / MINUTE) minutes long! discarding")
#       false
#     else
#       true
#     end
#   end

#   function read_events_csv(path) :: Vector{Event}
#     event_rows, event_headers = DelimitedFiles.readdlm(path, ','; header=true)

#     event_headers = event_headers[1,:] # 1x9 array to 9-element vector.

#     start_seconds_col_i = findfirst(isequal("begin_time_seconds"), event_headers)
#     end_seconds_col_i   = findfirst(isequal("end_time_seconds"), event_headers)
#     start_lat_col_i     = findfirst(isequal("begin_lat"), event_headers)
#     start_lon_col_i     = findfirst(isequal("begin_lon"), event_headers)
#     end_lat_col_i       = findfirst(isequal("end_lat"), event_headers)
#     end_lon_col_i       = findfirst(isequal("end_lon"), event_headers)
#     knots_col_i         = findfirst(isequal("speed"), event_headers)
#     speed_type_col_i    = findfirst(isequal("speed_type"), event_headers)
#     source_col_i        = findfirst(isequal("source"), event_headers)

#     row_to_event(row) = begin
#       start_seconds = row[start_seconds_col_i]
#       end_seconds   = row[end_seconds_col_i]

#       if isa(row[start_lat_col_i], Real)
#         start_latlon  = (row[start_lat_col_i], row[start_lon_col_i])
#         end_latlon    = (row[end_lat_col_i],   row[end_lon_col_i])
#       elseif row[start_lat_col_i] == "" || row[start_lat_col_i] == "LA" || row[start_lat_col_i] == "NJ" || row[start_lat_col_i] == "TN"
#         # Some wind events are not geocoded. One LSR event is geocoded as "LA,32.86,LA,32.86"
#         start_latlon = (NaN, NaN)
#         end_latlon   = (NaN, NaN)
#       else
#         # If some wind events are not geocoded, DelimitedFiles treats the column as strings, I believe.
#         start_latlon  = (parse(Float64, row[start_lat_col_i]), parse(Float64, row[start_lon_col_i]))
#         end_latlon    = (parse(Float64, row[end_lat_col_i]),   parse(Float64, row[end_lon_col_i]))
#       end

#       knots     = row[knots_col_i]      == -1 ? 50.0 : row[knots_col_i]
#       sustained = row[speed_type_col_i] == "sustained"
#       measured  = row[source_col_i]     == "measured"

#       Event(start_seconds, end_seconds, start_latlon, end_latlon, knots, sustained, measured)
#     end

#     events_raw = mapslices(row_to_event, event_rows, dims = [2])[:,1]
#     filter(event_looks_okay, events_raw)
#   end


#   function number_of_events_near_segment(events, radius_miles, begin_t, end_t, begin_latlon, end_latlon)

#     begin_seconds_from_utc_epoch = Int64(Dates.datetime2unix(begin_t))
#     end_seconds_from_utc_epoch   = Int64(Dates.datetime2unix(end_t))

#     latlons_on_segment = Tuple{Float64, Float64}[]

#     hour_count = abs(end_seconds_from_utc_epoch - begin_seconds_from_utc_epoch) ÷ HOUR

#     # Roughtly 1 test point per hour along segment.
#     for n in 1:(hour_count + 1)
#       push!(latlons_on_segment, Grids.ratio_on_segment(begin_latlon, end_latlon, (n-1) / hour_count))
#     end

#     mid_seconds_from_epoch = (begin_seconds_from_utc_epoch + end_seconds_from_utc_epoch) ÷ 2
#     half_window            = abs(end_seconds_from_utc_epoch - begin_seconds_from_utc_epoch) ÷ 2
#     event_segments         = Grids.event_segments_around_time(events, mid_seconds_from_epoch, half_window)

#     filter!(event_segments) do (latlon1, latlon2)
#       any(latlons_on_segment) do latlon
#         Grids.miles_to_line(latlon, latlon1, latlon2) <= radius_miles
#       end
#     end
#   end


#   wind_events = read_events_csv(wind_events_path)
#   conus_wind_events = filter(wind_events) do wind_event
#     # Exclude Alaska, Hawaii, Puerto Rico
#     Grids.is_in_conus_bounding_box(wind_event.start_latlon) || Grids.is_in_conus_bounding_box(wind_event.end_latlon)
#   end
#   conus_severe_wind_events = filter(is_severe_wind, conus_wind_events)
#   conus_sig_wind_events = filter(is_sig_wind, conus_wind_events)

# end

# module Gusts
#   # time_str,time_seconds,wban_id,name,state,county,knots,gust_knots,lat,lon,near_any_wind_reports
#   # 2003-04-13 04:44:00 UTC,1050209040,94012,HAVRE CITY COUNTY AP,MT,HILL,29,52,48.5428,-109.7633,false
#   # 2003-04-15 21:37:00 UTC,1050442620,23042,LUBBOCK INTERNATIONAL AP,TX,LUBBOCK,38,50,33.6656,-101.8231,false

#   import Dates
#   import DelimitedFiles

#   import Grids

#   const gusts_path = joinpath(@__DIR__, "..", "asos_1_min_measured_gusts_filtered", "gusts_at_least_50_knots_filtered.csv")

#   struct Gust
#     seconds_from_epoch_utc :: Int64
#     latlon                 :: Tuple{Float64, Float64}
#     knots                  :: Float64
#   end

#   function read_gusts_csv(path) :: Vector{Gust}
#     gust_rows, gust_headers = DelimitedFiles.readdlm(path, ',', String; header=true)

#     gust_headers = gust_headers[1,:] # 1x9 array to 9-element vector.

#     seconds_col_i = findfirst(isequal("time_seconds"), gust_headers)
#     lat_col_i     = findfirst(isequal("lat"),          gust_headers)
#     lon_col_i     = findfirst(isequal("lon"),          gust_headers)
#     knots_col_i   = findfirst(isequal("gust_knots"),   gust_headers)

#     row_to_gust(row) = Gust(
#       parse(Int64, row[seconds_col_i]),
#       parse.(Float64, (row[lat_col_i], row[lon_col_i])),
#       parse(Int64, row[knots_col_i]),
#     )

#     mapslices(row_to_gust, gust_rows, dims = [2])[:,1]
#   end

#   function number_of_gusts_near_segment(gusts, radius_miles, begin_t, end_t, begin_latlon, end_latlon)
#     begin_seconds_from_utc_epoch = Int64(Dates.datetime2unix(begin_t))
#     end_seconds_from_utc_epoch   = Int64(Dates.datetime2unix(end_t))

#     if begin_seconds_from_utc_epoch == end_seconds_from_utc_epoch
#       gusts_during_period = filter(gusts) do gust
#         gust.seconds_from_epoch_utc == begin_seconds_from_utc_epoch
#       end
#     else
#       gusts_during_period = filter(gusts) do gust
#         gust.seconds_from_epoch_utc >= begin_seconds_from_utc_epoch &&
#         gust.seconds_from_epoch_utc < end_seconds_from_utc_epoch
#       end
#     end

#     count(gusts_during_period) do gust
#       Grids.miles_to_line(gust.latlon, begin_latlon, end_latlon) <= radius_miles
#     end
#   end

#   severe_gusts = read_gusts_csv(gusts_path)
# end


# Soruce: https://www.nhc.noaa.gov/data/#hurdat
# Cite: Landsea, C. W. and J. L. Franklin, 2013: Atlantic Hurricane Database Uncertainty and Presentation of a New Database Format. Mon. Wea. Rev., 141, 3576-3592.
const atlantic_in_path = joinpath(@__DIR__, "hurdat2-1851-2021-041922.txt")
const pacific_in_path  = joinpath(@__DIR__, "hurdat2-nepac-1949-2021-042522.txt")
const out_path         = joinpath(@__DIR__, "tropical_cyclones_2003-2021.csv")

try_parse_i64(str) = try
  parse(Int64, str)
catch e
  -1
end

tracks_by_storm_id = Dict{String, Any}()

time_str(datetime) = replace(string(datetime),  "T" => " ") * " UTC"

function do_it()
  # There are two header lines. We can ignore the second
  headers      = nothing
  units_header = nothing
  storm_id     = nothing
  name         = nothing

  for line in eachline(`cat $atlantic_in_path $pacific_in_path`)
    row = strip.(split(line, ','))

    if length(row) == 4
      # new storm
      storm_id, name, _, _ = row
      continue
    else
      yyyymmdd, hhmm, _,
      status,
      lat_str, lon_str,
      knots,
      _mb,
      ne_34knot_radius_nm_str,
      se_34knot_radius_nm_str,
      sw_34knot_radius_nm_str,
      nw_34knot_radius_nm_str,
      _ = row
    end

    year  = parse(Int64, yyyymmdd[1:4])
    month = parse(Int64, yyyymmdd[5:6])
    day   = parse(Int64, yyyymmdd[7:8])
    hour  = parse(Int64, hhmm[1:2])
    min   = parse(Int64, hhmm[3:4])

    year >= 2003 && year <= 2021 || continue

    print("\r$(yyyymmdd)")

    lat_str = endswith(lat_str, "N") ?       replace(lat_str, "N" => "") : "-" * replace(lat_str, "S" => "")
    lon_str = endswith(lon_str, "W") ? "-" * replace(lon_str, "W" => "") :       replace(lon_str, "E" => "")

    radii = [
      parse(Int64, ne_34knot_radius_nm_str),
      parse(Int64, se_34knot_radius_nm_str),
      parse(Int64, sw_34knot_radius_nm_str),
      parse(Int64, nw_34knot_radius_nm_str),
    ]

    track_pt = (
      Dates.DateTime(year, month, day, hour, min),
      storm_id,
      name,
      status,
      lat_str,
      lon_str,
      parse(Int64, knots),
      maximum(radii)
    )

    if !haskey(tracks_by_storm_id, storm_id)
      tracks_by_storm_id[storm_id] = []
    end
    push!(tracks_by_storm_id[storm_id], track_pt)
  end

  open(out_path, "w") do out
    println(out, join([
      "begin_time_str",
      "begin_time_seconds",
      "end_time_str",
      "end_time_seconds",
      "id",
      "name",
      "status",
      "knots",
      "max_radius_34_knot_winds_nmiles",
      "begin_lat",
      "begin_lon",
      "end_lat",
      "end_lon",
      # "in_conus_bounding_box",
      # "wind_events_within_100mi",
      # "wind_events_within_200mi",
      # "wind_events_within_250mi",
      # "wind_events_within_300mi",
      # "wind_events_within_400mi",
      # "wind_events_within_500mi",
      # "severe_gusts_within_100mi",
      # "severe_gusts_within_200mi",
      # "severe_gusts_within_250mi",
      # "severe_gusts_within_300mi",
      # "severe_gusts_within_400mi",
      # "severe_gusts_within_500mi",
    ], ","))

    for (_, track_pts) in sort(collect(tracks_by_storm_id), by = (id_tps -> id_tps[2][1][1]))
      last_track_pt = nothing
      for track_pt in track_pts
        if !isnothing(last_track_pt)
          time_1, storm_id, name, status_1,  lat_str_1, lon_str_1, knots_1, radii_1 = last_track_pt
          time_2, _,        _,    _status_2, lat_str_2, lon_str_2, knots_2, radii_2 = track_pt

          print("\r$(time_str(time_1))")

          # begin_latlon = parse.(Float64, (lat_str_1, lon_str_1))
          # end_latlon   = parse.(Float64, (lat_str_2, lon_str_2))

          println(out, join([
            time_str(time_1),
            Int64(Dates.datetime2unix(time_1)),
            time_str(time_2),
            Int64(Dates.datetime2unix(time_2)),
            storm_id,
            name,
            status_1,
            max(knots_1, knots_2),
            max(radii_1, radii_2),
            lat_str_1,
            lon_str_1,
            lat_str_2,
            lon_str_2,
            # Grids.is_in_conus_bounding_box(begin_latlon) || Grids.is_in_conus_bounding_box(end_latlon),
            # length(WindEvents.number_of_events_near_segment(WindEvents.conus_severe_wind_events, 100, time_1, time_2, begin_latlon, end_latlon)),
            # length(WindEvents.number_of_events_near_segment(WindEvents.conus_severe_wind_events, 200, time_1, time_2, begin_latlon, end_latlon)),
            # length(WindEvents.number_of_events_near_segment(WindEvents.conus_severe_wind_events, 250, time_1, time_2, begin_latlon, end_latlon)),
            # length(WindEvents.number_of_events_near_segment(WindEvents.conus_severe_wind_events, 300, time_1, time_2, begin_latlon, end_latlon)),
            # length(WindEvents.number_of_events_near_segment(WindEvents.conus_severe_wind_events, 400, time_1, time_2, begin_latlon, end_latlon)),
            # length(WindEvents.number_of_events_near_segment(WindEvents.conus_severe_wind_events, 500, time_1, time_2, begin_latlon, end_latlon)),
            # Gusts.number_of_gusts_near_segment(Gusts.severe_gusts, 100, time_1, time_2, begin_latlon, end_latlon),
            # Gusts.number_of_gusts_near_segment(Gusts.severe_gusts, 200, time_1, time_2, begin_latlon, end_latlon),
            # Gusts.number_of_gusts_near_segment(Gusts.severe_gusts, 250, time_1, time_2, begin_latlon, end_latlon),
            # Gusts.number_of_gusts_near_segment(Gusts.severe_gusts, 300, time_1, time_2, begin_latlon, end_latlon),
            # Gusts.number_of_gusts_near_segment(Gusts.severe_gusts, 400, time_1, time_2, begin_latlon, end_latlon),
            # Gusts.number_of_gusts_near_segment(Gusts.severe_gusts, 500, time_1, time_2, begin_latlon, end_latlon),
          ], ","))
        end
        last_track_pt = track_pt
      end
    end
  end
end

do_it()