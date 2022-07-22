import Dates
import DelimitedFiles
import Printf


push!(LOAD_PATH, joinpath(@__DIR__, "..", ".."))

import Grids

const wind_events_path = joinpath(@__DIR__, "..", "storm_data_reports", "wind_events_2003-2021.csv")
const out_dir          = @__DIR__


MINUTE = 60
HOUR   = 60*MINUTE
# DAY    = 24*HOUR


struct Event
  start_seconds_from_epoch_utc :: Int64
  end_seconds_from_epoch_utc   :: Int64
  start_latlon                 :: Tuple{Float64, Float64}
  end_latlon                   :: Tuple{Float64, Float64}
  knots     :: Float64
  sustained :: Bool # false == gust
  measured  :: Bool
end

is_severe_wind(wind_event) = wind_event.knots  >= 50.0
is_sig_wind(wind_event)    = wind_event.knots  >= 65.0

function event_looks_okay(event :: Event) :: Bool
  duration = event.end_seconds_from_epoch_utc - event.start_seconds_from_epoch_utc
  if duration >= 4*HOUR
    println("Event starting $(Dates.unix2datetime(event.start_seconds_from_epoch_utc)) ending $(Dates.unix2datetime(event.end_seconds_from_epoch_utc)) is $(duration / HOUR) hours long! discarding")
    false
  elseif duration < 0
    println("Event starting $(Dates.unix2datetime(event.start_seconds_from_epoch_utc)) ending $(Dates.unix2datetime(event.end_seconds_from_epoch_utc)) is $(duration / MINUTE) minutes long! discarding")
    false
  else
    true
  end
end

function read_events_csv(path) ::Vector{Event}
  event_rows, event_headers = DelimitedFiles.readdlm(path, ','; header=true)

  event_headers = event_headers[1,:] # 1x9 array to 9-element vector.

  start_seconds_col_i = findfirst(isequal("begin_time_seconds"), event_headers)
  end_seconds_col_i   = findfirst(isequal("end_time_seconds"), event_headers)
  start_lat_col_i     = findfirst(isequal("begin_lat"), event_headers)
  start_lon_col_i     = findfirst(isequal("begin_lon"), event_headers)
  end_lat_col_i       = findfirst(isequal("end_lat"), event_headers)
  end_lon_col_i       = findfirst(isequal("end_lon"), event_headers)
  knots_col_i         = findfirst(isequal("speed"), event_headers)
  speed_type_col_i    = findfirst(isequal("speed_type"), event_headers)
  source_col_i        = findfirst(isequal("source"), event_headers)

  row_to_event(row) = begin
    start_seconds = row[start_seconds_col_i]
    end_seconds   = row[end_seconds_col_i]

    if isa(row[start_lat_col_i], Real)
      start_latlon  = (row[start_lat_col_i], row[start_lon_col_i])
      end_latlon    = (row[end_lat_col_i],   row[end_lon_col_i])
    elseif row[start_lat_col_i] == "" || row[start_lat_col_i] == "LA" || row[start_lat_col_i] == "NJ" || row[start_lat_col_i] == "TN"
      # Some wind events are not geocoded. One LSR event is geocoded as "LA,32.86,LA,32.86"
      start_latlon = (NaN, NaN)
      end_latlon   = (NaN, NaN)
    else
      # If some wind events are not geocoded, DelimitedFiles treats the column as strings, I believe.
      start_latlon  = (parse(Float64, row[start_lat_col_i]), parse(Float64, row[start_lon_col_i]))
      end_latlon    = (parse(Float64, row[end_lat_col_i]),   parse(Float64, row[end_lon_col_i]))
    end

    knots     = row[knots_col_i]      == -1 ? 50.0 : row[knots_col_i]
    sustained = row[speed_type_col_i] == "sustained"
    measured  = row[source_col_i]     == "measured"

    Event(start_seconds, end_seconds, start_latlon, end_latlon, knots, sustained, measured)
  end

  events_raw = mapslices(row_to_event, event_rows, dims = [2])[:,1]
  filter(event_looks_okay, events_raw)
end

function event_segments_around_time(events :: Vector{Event}, seconds_from_utc_epoch :: Int64, seconds_before_and_after :: Int64) :: Vector{Tuple{Tuple{Float64, Float64}, Tuple{Float64, Float64}}}
  period_start_seconds = seconds_from_utc_epoch - seconds_before_and_after
  period_end_seconds   = seconds_from_utc_epoch + seconds_before_and_after

  is_relevant_event(event) = begin
    (event.end_seconds_from_epoch_utc  > period_start_seconds &&
    event.start_seconds_from_epoch_utc < period_end_seconds) ||
    # Zero-duration events exactly on the boundary count in the later period
    (event.start_seconds_from_epoch_utc == period_start_seconds && event.end_seconds_from_epoch_utc == period_start_seconds)
  end

  relevant_events = filter(is_relevant_event, events)

  event_to_segment(event) = begin
    start_seconds = event.start_seconds_from_epoch_utc
    end_seconds   = event.end_seconds_from_epoch_utc
    start_latlon  = event.start_latlon
    end_latlon    = event.end_latlon

    duration = event.end_seconds_from_epoch_utc - event.start_seconds_from_epoch_utc

    # Turns out no special case is needed for tornadoes of 0 duration.

    if start_seconds >= period_start_seconds
      seg_start_latlon = start_latlon
    else
      start_ratio = Float64(period_start_seconds - start_seconds) / duration
      seg_start_latlon = Grids.ratio_on_segment(start_latlon, end_latlon, start_ratio)
    end

    if end_seconds <= period_end_seconds
      seg_end_latlon = end_latlon
    else
      # This math is correct
      end_ratio = Float64(period_end_seconds - start_seconds) / duration
      seg_end_latlon = Grids.ratio_on_segment(start_latlon, end_latlon, end_ratio)
    end

    (seg_start_latlon, seg_end_latlon)
  end

  map(event_to_segment, relevant_events)
end


function do_it(events)
  t     = Dates.DateTime(2003,1,1,0)
  end_t = Dates.DateTime(2022,1,1,0)

  while t < end_t
    # yyyymm        = Printf.@sprintf "%04d%02d"            Dates.year(t) Dates.month(t)
    # yyyymmdd_hh00 = Printf.@sprintf "%04d%02d%02d_%02d00" Dates.year(t) Dates.month(t) Dates.day(t) Dates.hour(t)

    # mucape_path    = joinpath(mucape_at_least_one_gridded_dir, yyyymm, yyyymmdd_hh00 * ".bits")

    print("\r$t     ")

    # Events from t to t+1hr

    seconds_from_utc_epoch = Int64(Dates.datetime2unix(t))
    segments = event_segments_around_time(events, seconds_from_utc_epoch + 30*MINUTE, 30*MINUTE)

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


wind_events = read_events_csv(wind_events_path)
conus_wind_events = filter(wind_events) do wind_event
  # Exclude Alaska, Hawaii, Puerto Rico
  Grids.is_in_conus_bounding_box(wind_event.start_latlon) || Grids.is_in_conus_bounding_box(wind_event.end_latlon)
end
conus_severe_wind_events = filter(is_severe_wind, conus_wind_events)
conus_sig_wind_events = filter(is_sig_wind, conus_wind_events)

do_it(conus_severe_wind_events)
