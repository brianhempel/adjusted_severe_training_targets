module ASOSStations

import Dates

push!(LOAD_PATH, @__DIR__)
push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "asos_1_min_measured_gusts"))

import Grids
using Utils

import StationInfos
const station_infos = StationInfos.station_infos
const nrow          = StationInfos.DataFrames.nrow

const min_years_of_data_to_count = 5

# time_str,time_seconds,wban_id,name,state,knots,gust_knots,near_any_wind_reports,near_hurricane_or_tropical_storm
# 2003-04-13 04:44:00 UTC,1050209040,94012,HAVRE CITY COUNTY AP,MT,29,52,false,false
# 2003-04-15 21:51:00 UTC,1050443460,23042,LUBBOCK INTERNATIONAL AP,TX,39,51,false,false
# 2003-04-15 22:05:00 UTC,1050444300,23042,LUBBOCK INTERNATIONAL AP,TX,43,52,false,false
# 2003-04-15 23:54:00 UTC,1050450840,23042,LUBBOCK INTERNATIONAL AP,TX,46,58,false,false

struct Gust
  time                   :: Dates.DateTime
  # seconds_from_epoch_utc :: Int64
  wban_id                :: String
  gust_knots             :: Float32
end

function get_gusts(path)
  gusts = Gust[]

  headers = nothing
  for line in eachline(path)
    if isnothing(headers)
      headers = split(line, ',')
      continue
    end
    time_str, time_seconds_str, wban_id, name, state, knots_str, gust_knots_str, near_any_wind_reports, near_hurricane_or_tropical_storm = split(line, ',')

    push!(gusts,
      Gust(
        parse(Dates.DateTime, replace(time_str, " UTC" => "", " " => "T")),
        wban_id,
        parse.(Float64, gust_knots_str)
      )
    )
  end

  gusts
end

gusts = get_gusts((@__DIR__) * "/data_2003-2021/asos_1_min_measured_gusts_filtered/gusts_at_least_50_knots_filtered_tc_one_per_hour.csv")

const gusts_by_wban = Dict{String, Vector{Gust}}()

for gust in gusts
  gs = get(gusts_by_wban, gust.wban_id, Gust[])
  push!(gs, gust)
  gusts_by_wban[gust.wban_id] = gs
end



struct Station
  wban_id                  :: String
  name                     :: String
  state                    :: String
  latlon                   :: Tuple{Float64, Float64}
  distance_error_meters    :: Float64
  begin_time               :: Dates.DateTime
  end_time                 :: Dates.DateTime
  exclude_months           :: Vector{Dates.Date}
  legit_hours              :: Set{Int64}
  legit_fourhours          :: Set{Int64}
  legit_convective_days    :: Set{Int64}
  ndays                    :: Int64
  gusts                    :: Vector{Gust}
  sig_gusts                :: Vector{Gust}
  gust_hours               :: Vector{Int64}
  gust_fourhours           :: Vector{Int64}
  gust_convective_days     :: Vector{Int64}
  sig_gust_hours           :: Vector{Int64}
  sig_gust_fourhours       :: Vector{Int64}
  sig_gust_convective_days :: Vector{Int64}
end

const stations_uptime_path = (@__DIR__) * "/data_2003-2021/asos_1_min_measured_gusts/which_asos_months_look_good.csv"


# "2022-10"
function month_str_to_date(str)
  year, month = parse.(Int64, split(str, '-'))
  Dates.Date(year, month)
end

function is_in_convective_month(time, month_date)
  time >= (Dates.DateTime(month_date) + Dates.Hour(12)) && time <= Dates.DateTime(month_date) + Dates.Month(1) + Dates.Hour(12) - Dates.Second(1)
end


gust_to_hour_i(gust)           = time_to_hour_i(gust.time)
gust_to_fourhour_i(gust)       = time_to_fourhour_i(gust.time)
gust_to_convective_day_i(gust) = time_to_convective_day_i(gust.time)

function convective_month_hour_is(month_date)
  time_to_hour_i(Dates.DateTime(month_date) + Dates.Hour(12)) : time_to_hour_i(Dates.DateTime(month_date) + Dates.Month(1) + Dates.Hour(12) - Dates.Second(1))
end

function convective_month_fourhour_is(month_date)
  time_to_fourhour_i(Dates.DateTime(month_date) + Dates.Hour(12)) : time_to_fourhour_i(Dates.DateTime(month_date) + Dates.Month(1) + Dates.Hour(12) - Dates.Second(1))
end

function convective_month_convective_day_is(month_date)
  time_to_convective_day_i(Dates.DateTime(month_date) + Dates.Hour(12)) : time_to_convective_day_i(Dates.DateTime(month_date) + Dates.Month(1) + Dates.Hour(12) - Dates.Second(1))
end


function get_stations()
  stations = Station[]

  # sometimes stations move, but we are pretending they have a single location.
  # what is the worst case?
  max_asos_distance_error = 0.0
  ngusts_discarded        = 0

  headers = nothing
  for line in eachline(stations_uptime_path)
    if isnothing(headers)
      headers = split(line, ',')
      continue
    end
    wban_id, begin_95pct_uptime, end_95pct_uptime, exclude_months_95pct, ndays_95pct, begin_90pct_uptime, end_90pct_uptime, exclude_months_90pct, ndays_90pct, _ = split(line, ',')

    station_gusts = get(gusts_by_wban, wban_id, Gust[])

    if begin_90pct_uptime == ""
      println(stderr, "WBAN $wban_id data quality to low. skipping its $(length(station_gusts)) gusts")
      ngusts_discarded += length(station_gusts)
      continue
    end

    ndays = parse(Int64, ndays_90pct)

    if ndays / 365.25 < min_years_of_data_to_count
      println(stderr, "WBAN $wban_id only has $ndays days of data (not $min_years_of_data_to_count years). skipping its $(length(station_gusts)) gusts")
      ngusts_discarded += length(station_gusts)
      continue
    end

    begin_date         = month_str_to_date(begin_90pct_uptime)
    end_date_exclusive = month_str_to_date(end_90pct_uptime) + Dates.Month(1)

    infos = station_infos[station_infos.WBAN_ID .== wban_id, :]

    valid_infos = infos[.!(infos.END_DATE .< begin_date) .&& .!(infos.BEGIN_DATE .>= end_date_exclusive), :]

    # Sometimes there are multiple stations for a time range.
    # Try and filter down to just the ASOS stations (exlcuding e.g. upper air or radar sites).
    valid_infos = StationInfos.disambiguate_station_infos(valid_infos)

    # If there's still ambiguity, only look at stations during gust times
    if nrow(valid_infos) >= 2
      is = filter(1:nrow(valid_infos)) do i
        any(station_gusts) do gust
          valid_infos[i, :BEGIN_DATE] <= gust.time && valid_infos[i, :END_DATE] + Dates.Day(1) >= gust.time
        end
      end
      if length(is) >= 1
        valid_infos = valid_infos[is, :]
      end
    end

    if nrow(valid_infos) > 0
      lats = valid_infos.LAT_DEC
      lons = valid_infos.LON_DEC

      mean_latlon = (mean(lats), mean(lons))

      distances = map(ll -> Grids.instantish_distance(ll, mean_latlon), zip(lats, lons))

      distance_error_meters = maximum(distances)

      exclude_months = month_str_to_date.(split(replace(exclude_months_90pct, "\"\"" => "")))

      # the time ranges are by convective day (except for 2021-12-31)
      begin_time = Dates.DateTime(begin_date)         + Dates.Hour(12)
      end_time   = Dates.DateTime(end_date_exclusive) + Dates.Hour(12) - Dates.Second(1)

      exclude_month_hour_is = Set(vcat(convective_month_hour_is.(exclude_months)...))
      legit_hours = Set(filter(time_to_hour_i(begin_time):time_to_hour_i(end_time)) do hour_i
        !(hour_i in exclude_month_hour_is)
      end)
      exclude_month_fourhour_is = Set(vcat(convective_month_fourhour_is.(exclude_months)...))
      legit_fourhours = Set(filter(time_to_fourhour_i(begin_time):time_to_fourhour_i(end_time)) do fourhour_i
        !(fourhour_i in exclude_month_fourhour_is)
      end)
      exclude_month_convective_day_is = Set(vcat(convective_month_convective_day_is.(exclude_months)...))
      legit_convective_days = Set(filter(time_to_convective_day_i(begin_time):time_to_convective_day_i(end_time)) do convective_day_i
        !(convective_day_i in exclude_month_convective_day_is)
      end)

      @assert ndays == length(legit_convective_days)

      filter!(station_gusts) do gust
        # There *should* be no gusts in the exclude_months because the station has no data for those months
        this_shouldnt_happen = any(exclude_months) do month_date
          is_in_convective_month(gust.time, month_date)
        end
        if this_shouldnt_happen
          println(stderr, "WBAN $(wban_id) should have no data at $(gust.time) but it had a wind gust then!")
          @assert this_shouldnt_happen
        end

        if !(gust.time >= begin_time && gust.time <= end_time)
          println(stderr, "Excluding gust at $(gust.time) for WBAN $(wban_id)")
          ngusts_discarded += 1
          false
        else
          true
        end
      end

      # We retained the strongest gust per hour, so all sig gusts hours will be represented.
      station_sig_gusts = filter(g -> g.gust_knots >= 65, station_gusts)

      gust_hours               = map(gust_to_hour_i,           station_gusts)
      gust_fourhours           = map(gust_to_fourhour_i,       station_gusts)
      gust_convective_days     = map(gust_to_convective_day_i, station_gusts)
      sig_gust_hours           = map(gust_to_hour_i,           station_sig_gusts)
      sig_gust_fourhours       = map(gust_to_fourhour_i,       station_sig_gusts)
      sig_gust_convective_days = map(gust_to_convective_day_i, station_sig_gusts)


      push!(stations,
        Station(
          wban_id,
          valid_infos[1, :NAME_PRINCIPAL],
          valid_infos[1, :STATE_PROV],
          mean_latlon,
          distance_error_meters,
          begin_time,
          end_time,
          exclude_months,
          legit_hours,
          legit_fourhours,
          legit_convective_days,
          ndays,
          station_gusts,
          station_sig_gusts,
          gust_hours,
          gust_fourhours,
          gust_convective_days,
          sig_gust_hours,
          sig_gust_fourhours,
          sig_gust_convective_days,
        )
      )
    else
      println(stderr, "WBAN $wban_id not found! skipping its $(length(station_gusts)) gusts")
      ngusts_discarded += length(station_gusts)
    end
  end

  println(stderr, "$ngusts_discarded gusts discarded (from bad stations or bad time ranges)")

  println(stderr, "Max ASOS station distance errors:")

  for station in Iterators.take(sort(stations, by = (s -> -s.distance_error_meters)), 10)
    println(stderr, "$(station.wban_id)\t$(Float32(station.distance_error_meters)) meters\t$(station.latlon)")
  end

  stations
end

const stations = get_stations()

# Excluding gust at 2019-07-02T00:07:00 for WBAN 03028
# Excluding gust at 2020-06-02T22:56:00 for WBAN 03028
# Excluding gust at 2020-07-08T00:34:00 for WBAN 03028
# Excluding gust at 2020-07-15T02:15:00 for WBAN 03028
# Excluding gust at 2020-07-18T03:28:00 for WBAN 03028
# Excluding gust at 2020-08-15T00:24:00 for WBAN 03028
# Excluding gust at 2021-05-02T23:29:00 for WBAN 03028
# Excluding gust at 2021-05-09T01:56:00 for WBAN 03028
# Excluding gust at 2021-05-09T02:05:00 for WBAN 03028
# Excluding gust at 2005-08-04T22:29:00 for WBAN 03031
# Excluding gust at 2007-05-02T14:50:00 for WBAN 03031
# Excluding gust at 2007-06-27T04:54:00 for WBAN 03031
# Excluding gust at 2007-06-27T05:19:00 for WBAN 03031
# Excluding gust at 2008-06-18T05:44:00 for WBAN 03031
# Excluding gust at 2008-08-11T22:30:00 for WBAN 03031
# Excluding gust at 2009-07-29T06:59:00 for WBAN 03031
# Excluding gust at 2009-07-29T07:00:00 for WBAN 03031
# Excluding gust at 2014-06-19T01:35:00 for WBAN 03031
# Excluding gust at 2014-08-10T22:55:00 for WBAN 03031
# Excluding gust at 2015-04-12T22:24:00 for WBAN 03032
# Excluding gust at 2015-12-27T04:49:00 for WBAN 03032
# Excluding gust at 2016-07-26T22:43:00 for WBAN 03032
# Excluding gust at 2018-08-10T19:46:00 for WBAN 03032
# Excluding gust at 2021-05-28T01:15:00 for WBAN 03032
# Excluding gust at 2007-08-02T01:49:00 for WBAN 03068
# Excluding gust at 2007-08-23T00:24:00 for WBAN 03068
# Excluding gust at 2008-05-23T19:34:00 for WBAN 03068
# Excluding gust at 2008-08-12T23:56:00 for WBAN 03068
# WBAN 03124 only has 243 days of data (not 5 years). skipping its 3 gusts
# WBAN 03154 data quality to low. skipping its 0 gusts
# Excluding gust at 2020-08-23T23:13:00 for WBAN 03160
# Excluding gust at 2021-07-25T03:09:00 for WBAN 03160
# Excluding gust at 2021-07-26T04:29:00 for WBAN 03160
# Excluding gust at 2019-01-17T22:37:00 for WBAN 03170
# WBAN 03185 only has 975 days of data (not 5 years). skipping its 3 gusts
# WBAN 03749 only has 792 days of data (not 5 years). skipping its 1 gusts
# Excluding gust at 2012-06-30T03:30:00 for WBAN 03757
# WBAN 03804 only has 1704 days of data (not 5 years). skipping its 2 gusts
# Excluding gust at 2012-07-06T12:07:00 for WBAN 03855
# Excluding gust at 2012-07-12T02:37:00 for WBAN 03855
# Excluding gust at 2012-06-29T22:56:00 for WBAN 03860
# Excluding gust at 2008-04-04T19:13:00 for WBAN 03866
# Excluding gust at 2018-04-14T16:09:00 for WBAN 03866
# Excluding gust at 2020-04-08T20:00:00 for WBAN 03866
# Excluding gust at 2020-11-27T20:20:00 for WBAN 03866
# WBAN 03882 only has 1126 days of data (not 5 years). skipping its 4 gusts
# WBAN 03902 only has 274 days of data (not 5 years). skipping its 2 gusts
# WBAN 03933 only has 92 days of data (not 5 years). skipping its 2 gusts
# WBAN 03949 only has 700 days of data (not 5 years). skipping its 0 gusts
# WBAN 03951 data quality to low. skipping its 0 gusts
# Excluding gust at 2017-05-11T00:59:00 for WBAN 03981
# Excluding gust at 2017-07-04T02:50:00 for WBAN 03981
# Excluding gust at 2018-06-30T18:37:00 for WBAN 03981
# Excluding gust at 2018-08-17T22:55:00 for WBAN 03981
# Excluding gust at 2018-08-17T23:00:00 for WBAN 03981
# Excluding gust at 2019-06-19T05:43:00 for WBAN 03981
# Excluding gust at 2007-06-18T07:38:00 for WBAN 03991
# Excluding gust at 2008-04-10T08:32:00 for WBAN 03991
# Excluding gust at 2018-06-07T22:09:00 for WBAN 03991
# Excluding gust at 2018-08-18T23:27:00 for WBAN 03991
# Excluding gust at 2019-04-18T04:36:00 for WBAN 03991
# Excluding gust at 2019-06-09T17:57:00 for WBAN 03991
# Excluding gust at 2019-07-10T22:38:00 for WBAN 03991
# Excluding gust at 2019-10-21T04:48:00 for WBAN 03991
# Excluding gust at 2020-06-20T00:43:00 for WBAN 03991
# Excluding gust at 2020-08-16T23:24:00 for WBAN 03991
# Excluding gust at 2021-05-17T05:57:00 for WBAN 03991
# Excluding gust at 2021-05-17T06:00:00 for WBAN 03991
# Excluding gust at 2021-10-27T07:48:00 for WBAN 03991
# WBAN 04134 only has 60 days of data (not 5 years). skipping its 11 gusts
# Excluding gust at 2016-07-30T22:09:00 for WBAN 04847
# Excluding gust at 2011-09-04T01:36:00 for WBAN 04850
# Excluding gust at 2013-06-26T21:00:00 for WBAN 04850
# Excluding gust at 2015-08-03T06:14:00 for WBAN 04850
# Excluding gust at 2016-06-23T04:28:00 for WBAN 04850
# Excluding gust at 2017-01-11T01:48:00 for WBAN 04850
# Excluding gust at 2020-03-03T22:52:00 for WBAN 04850
# Excluding gust at 2020-05-10T19:02:00 for WBAN 04850
# WBAN 11630 only has 485 days of data (not 5 years). skipping its 0 gusts
# WBAN 11640 only has 1491 days of data (not 5 years). skipping its 0 gusts
# WBAN 12850 only has 1006 days of data (not 5 years). skipping its 1 gusts
# Excluding gust at 2005-04-01T12:51:00 for WBAN 12884
# Excluding gust at 2007-04-04T14:29:00 for WBAN 12926
# Excluding gust at 2007-05-03T07:37:00 for WBAN 12926
# Excluding gust at 2009-05-26T11:16:00 for WBAN 12926
# Excluding gust at 2009-10-26T17:34:00 for WBAN 12926
# Excluding gust at 2010-05-18T10:19:00 for WBAN 12926
# Excluding gust at 2010-06-08T07:04:00 for WBAN 12926
# Excluding gust at 2010-09-08T07:31:00 for WBAN 12926
# Excluding gust at 2010-09-08T10:25:00 for WBAN 12926
# Excluding gust at 2010-09-17T05:37:00 for WBAN 12926
# Excluding gust at 2010-09-17T06:11:00 for WBAN 12926
# Excluding gust at 2010-09-25T11:17:00 for WBAN 12926
# Excluding gust at 2021-05-12T05:56:00 for WBAN 12926
# Excluding gust at 2021-05-12T06:02:00 for WBAN 12926
# WBAN 12944 data quality to low. skipping its 0 gusts
# WBAN 12946 only has 334 days of data (not 5 years). skipping its 4 gusts
# Excluding gust at 2017-05-20T20:44:00 for WBAN 12947
# Excluding gust at 2018-03-29T03:07:00 for WBAN 12947
# Excluding gust at 2020-05-16T03:45:00 for WBAN 12947
# Excluding gust at 2020-06-10T04:47:00 for WBAN 12947
# WBAN 12958 only has 244 days of data (not 5 years). skipping its 12 gusts
# WBAN 12968 only has 1522 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2007-07-19T19:56:00 for WBAN 13721
# Excluding gust at 2008-06-05T03:46:00 for WBAN 13721
# Excluding gust at 2008-08-06T22:11:00 for WBAN 13721
# Excluding gust at 2009-07-23T22:51:00 for WBAN 13721
# WBAN 13743 only has 1491 days of data (not 5 years). skipping its 7 gusts
# WBAN 13752 only has 579 days of data (not 5 years). skipping its 5 gusts
# Excluding gust at 2007-08-09T14:26:00 for WBAN 13754
# Excluding gust at 2008-06-28T10:22:00 for WBAN 13754
# Excluding gust at 2008-10-25T21:59:00 for WBAN 13754
# Excluding gust at 2009-02-19T03:56:00 for WBAN 13754
# Excluding gust at 2009-03-28T14:55:00 for WBAN 13754
# Excluding gust at 2009-06-13T04:07:00 for WBAN 13754
# Excluding gust at 2008-03-05T06:52:00 for WBAN 13762
# Excluding gust at 2007-04-27T19:53:00 for WBAN 13769
# Excluding gust at 2009-01-08T00:29:00 for WBAN 13769
# Excluding gust at 2009-07-17T20:37:00 for WBAN 13769
# Excluding gust at 2009-11-12T22:02:00 for WBAN 13769
# Excluding gust at 2009-11-12T23:14:00 for WBAN 13769
# Excluding gust at 2009-11-13T00:15:00 for WBAN 13769
# WBAN 13773 only has 577 days of data (not 5 years). skipping its 6 gusts
# WBAN 13911 only has 1399 days of data (not 5 years). skipping its 14 gusts
# WBAN 13947 data quality to low. skipping its 0 gusts
# Excluding gust at 2003-08-02T01:58:00 for WBAN 13964
# Excluding gust at 2003-08-02T02:05:00 for WBAN 13964
# Excluding gust at 2005-07-04T07:10:00 for WBAN 13967
# Excluding gust at 2007-12-10T04:42:00 for WBAN 13967
# Excluding gust at 2008-05-02T05:31:00 for WBAN 13967
# Excluding gust at 2008-06-06T02:42:00 for WBAN 13967
# Excluding gust at 2020-05-28T19:43:00 for WBAN 13973
# Excluding gust at 2021-03-14T04:36:00 for WBAN 13973
# Excluding gust at 2020-08-11T01:19:00 for WBAN 13975
# Excluding gust at 2020-11-24T20:53:00 for WBAN 13975
# Excluding gust at 2021-03-14T04:17:00 for WBAN 13975
# Excluding gust at 2019-05-19T12:03:00 for WBAN 13976
# Excluding gust at 2017-04-30T14:37:00 for WBAN 13978
# Excluding gust at 2021-05-04T18:48:00 for WBAN 13978
# Excluding gust at 2016-07-08T07:10:00 for WBAN 13997
# Excluding gust at 2017-04-26T08:27:00 for WBAN 13997
# Excluding gust at 2017-05-19T08:50:00 for WBAN 13997
# Excluding gust at 2019-05-21T21:42:00 for WBAN 13997
# Excluding gust at 2021-05-27T18:02:00 for WBAN 13997
# Excluding gust at 2021-12-11T00:54:00 for WBAN 13997
# WBAN 14611 only has 275 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2019-08-08T09:04:00 for WBAN 14756
# Excluding gust at 2020-10-07T23:41:00 for WBAN 14756
# WBAN 14793 only has 244 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2020-11-15T18:25:00 for WBAN 14813
# Excluding gust at 2020-05-10T17:37:00 for WBAN 14827
# Excluding gust at 2020-06-10T19:41:00 for WBAN 14827
# Excluding gust at 2020-06-10T21:51:00 for WBAN 14827
# Excluding gust at 2020-07-08T19:53:00 for WBAN 14827
# Excluding gust at 2020-07-19T18:52:00 for WBAN 14827
# Excluding gust at 2019-09-03T01:13:00 for WBAN 14910
# Excluding gust at 2020-07-09T07:30:00 for WBAN 14910
# Excluding gust at 2020-07-26T08:10:00 for WBAN 14910
# Excluding gust at 2021-08-20T21:48:00 for WBAN 14910
# Excluding gust at 2021-05-03T23:57:00 for WBAN 23009
# Excluding gust at 2021-05-15T00:38:00 for WBAN 23009
# Excluding gust at 2021-05-23T00:04:00 for WBAN 23009
# Excluding gust at 2016-05-21T22:56:00 for WBAN 23040
# Excluding gust at 2016-08-02T21:25:00 for WBAN 23040
# Excluding gust at 2017-03-28T23:18:00 for WBAN 23040
# Excluding gust at 2017-05-23T01:39:00 for WBAN 23040
# Excluding gust at 2017-07-05T04:07:00 for WBAN 23040
# Excluding gust at 2017-08-07T02:59:00 for WBAN 23040
# Excluding gust at 2017-08-07T03:00:00 for WBAN 23040
# Excluding gust at 2018-06-04T03:39:00 for WBAN 23040
# Excluding gust at 2019-09-29T22:30:00 for WBAN 23040
# Excluding gust at 2006-04-05T23:39:00 for WBAN 23054
# Excluding gust at 2006-06-15T22:55:00 for WBAN 23054
# Excluding gust at 2006-06-15T23:23:00 for WBAN 23054
# Excluding gust at 2007-06-15T22:03:00 for WBAN 23054
# Excluding gust at 2021-05-17T21:37:00 for WBAN 23054
# WBAN 23055 only has 730 days of data (not 5 years). skipping its 56 gusts
# Excluding gust at 2020-05-30T22:50:00 for WBAN 23160
# Excluding gust at 2021-07-11T02:04:00 for WBAN 23160
# Excluding gust at 2021-07-31T03:14:00 for WBAN 23160
# Excluding gust at 2008-08-09T03:58:00 for WBAN 23179
# Excluding gust at 2009-07-22T07:39:00 for WBAN 23179
# Excluding gust at 2011-07-06T06:55:00 for WBAN 23179
# Excluding gust at 2011-07-06T07:08:00 for WBAN 23179
# Excluding gust at 2021-10-12T01:56:00 for WBAN 23179
# WBAN 23187 only has 1461 days of data (not 5 years). skipping its 1 gusts
# WBAN 23199 only has 427 days of data (not 5 years). skipping its 1 gusts
# WBAN 23254 only has 1645 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2005-06-19T06:23:00 for WBAN 24012
# Excluding gust at 2013-05-14T08:00:00 for WBAN 24012
# Excluding gust at 2015-03-28T23:26:00 for WBAN 24012
# Excluding gust at 2015-10-02T22:39:00 for WBAN 24012
# Excluding gust at 2015-10-02T23:06:00 for WBAN 24012
# Excluding gust at 2016-06-17T07:20:00 for WBAN 24012
# Excluding gust at 2016-07-06T23:37:00 for WBAN 24012
# Excluding gust at 2016-07-10T23:44:00 for WBAN 24012
# Excluding gust at 2018-06-01T23:06:00 for WBAN 24012
# Excluding gust at 2018-07-03T07:58:00 for WBAN 24012
# Excluding gust at 2018-07-04T03:46:00 for WBAN 24012
# Excluding gust at 2019-07-15T05:59:00 for WBAN 24012
# Excluding gust at 2019-07-15T06:02:00 for WBAN 24012
# Excluding gust at 2020-07-31T19:24:00 for WBAN 24012
# Excluding gust at 2020-10-12T23:32:00 for WBAN 24012
# Excluding gust at 2021-06-06T04:02:00 for WBAN 24012
# Excluding gust at 2021-06-09T00:33:00 for WBAN 24012
# Excluding gust at 2021-06-09T01:37:00 for WBAN 24012
# Excluding gust at 2021-06-09T02:14:00 for WBAN 24012
# Excluding gust at 2021-06-09T04:33:00 for WBAN 24012
# Excluding gust at 2021-06-09T05:10:00 for WBAN 24012
# Excluding gust at 2021-06-11T04:33:00 for WBAN 24012
# Excluding gust at 2021-06-11T10:15:00 for WBAN 24012
# Excluding gust at 2021-06-11T01:16:00 for WBAN 24037
# Excluding gust at 2021-08-09T01:58:00 for WBAN 24037
# Excluding gust at 2021-08-09T02:16:00 for WBAN 24037
# WBAN 24112 only has 730 days of data (not 5 years). skipping its 7 gusts
# Excluding gust at 2005-03-28T21:13:00 for WBAN 24150
# Excluding gust at 2005-06-23T02:55:00 for WBAN 24150
# Excluding gust at 2005-07-16T02:06:00 for WBAN 24150
# Excluding gust at 2006-06-04T23:13:00 for WBAN 24150
# Excluding gust at 2007-04-30T01:05:00 for WBAN 24150
# Excluding gust at 2007-04-30T02:00:00 for WBAN 24150
# Excluding gust at 2008-06-26T00:58:00 for WBAN 24150
# Excluding gust at 2008-07-01T22:55:00 for WBAN 24150
# Excluding gust at 2008-08-08T00:46:00 for WBAN 24150
# Excluding gust at 2008-08-09T20:44:00 for WBAN 24150
# Excluding gust at 2009-06-30T22:47:00 for WBAN 24150
# Excluding gust at 2009-06-30T23:07:00 for WBAN 24150
# Excluding gust at 2009-09-06T00:56:00 for WBAN 24150
# Excluding gust at 2010-07-31T20:57:00 for WBAN 24150
# Excluding gust at 2010-08-08T23:25:00 for WBAN 24150
# Excluding gust at 2018-05-31T19:34:00 for WBAN 24153
# Excluding gust at 2021-07-01T23:55:00 for WBAN 24153
# WBAN 24154 only has 942 days of data (not 5 years). skipping its 0 gusts
# WBAN 24237 only has 183 days of data (not 5 years). skipping its 0 gusts
# WBAN 25367 only has 516 days of data (not 5 years). skipping its 0 gusts
# WBAN 25624 only has 62 days of data (not 5 years). skipping its 0 gusts
# WBAN 25628 only has 457 days of data (not 5 years). skipping its 0 gusts
# WBAN 25713 data quality to low. skipping its 0 gusts
# WBAN 26422 only has 1006 days of data (not 5 years). skipping its 0 gusts
# WBAN 26502 only has 1611 days of data (not 5 years). skipping its 0 gusts
# WBAN 26642 only has 31 days of data (not 5 years). skipping its 0 gusts
# WBAN 26643 only has 61 days of data (not 5 years). skipping its 0 gusts
# WBAN 27503 only has 426 days of data (not 5 years). skipping its 0 gusts
# WBAN 27515 only has 1310 days of data (not 5 years). skipping its 0 gusts
# WBAN 53120 only has 669 days of data (not 5 years). skipping its 1 gusts
# WBAN 53144 only has 273 days of data (not 5 years). skipping its 0 gusts
# WBAN 53145 only has 273 days of data (not 5 years). skipping its 1 gusts
# WBAN 53146 only has 61 days of data (not 5 years). skipping its 7 gusts
# WBAN 53842 only has 1095 days of data (not 5 years). skipping its 1 gusts
# WBAN 53843 only has 670 days of data (not 5 years). skipping its 2 gusts
# WBAN 53847 only has 946 days of data (not 5 years). skipping its 1 gusts
# WBAN 53848 only has 913 days of data (not 5 years). skipping its 3 gusts
# Excluding gust at 2020-10-09T23:00:00 for WBAN 53915
# Excluding gust at 2021-03-17T20:47:00 for WBAN 53915
# Excluding gust at 2019-06-21T12:51:00 for WBAN 53916
# WBAN 53988 only has 122 days of data (not 5 years). skipping its 0 gusts
# WBAN 53989 only has 215 days of data (not 5 years). skipping its 0 gusts
# WBAN 54742 only has 123 days of data (not 5 years). skipping its 0 gusts
# WBAN 54771 only has 1675 days of data (not 5 years). skipping its 0 gusts
# WBAN 54779 only has 1826 days of data (not 5 years). skipping its 0 gusts
# WBAN 63870 only has 244 days of data (not 5 years). skipping its 0 gusts
# WBAN 63871 only has 1248 days of data (not 5 years). skipping its 0 gusts
# WBAN 63872 only has 1310 days of data (not 5 years). skipping its 1 gusts
# WBAN 63873 only has 31 days of data (not 5 years). skipping its 1 gusts
# WBAN 63874 only has 822 days of data (not 5 years). skipping its 0 gusts
# WBAN 63890 only has 1734 days of data (not 5 years). skipping its 2 gusts
# Excluding gust at 2021-04-10T13:52:00 for WBAN 73805
# Excluding gust at 2021-07-29T22:15:00 for WBAN 73805
# Excluding gust at 2005-07-03T21:36:00 for WBAN 93026
# Excluding gust at 2012-08-20T00:00:00 for WBAN 93026
# Excluding gust at 2012-08-28T00:38:00 for WBAN 93026
# Excluding gust at 2013-08-06T19:58:00 for WBAN 93026
# Excluding gust at 2015-06-17T01:25:00 for WBAN 93026
# Excluding gust at 2015-06-23T01:58:00 for WBAN 93026
# Excluding gust at 2016-07-25T03:22:00 for WBAN 93026
# Excluding gust at 2016-08-06T23:31:00 for WBAN 93026
# Excluding gust at 2017-07-14T00:37:00 for WBAN 93026
# Excluding gust at 2017-07-15T21:06:00 for WBAN 93026
# Excluding gust at 2018-06-09T00:58:00 for WBAN 93026
# Excluding gust at 2018-07-27T02:15:00 for WBAN 93026
# Excluding gust at 2019-08-23T23:41:00 for WBAN 93026
# Excluding gust at 2005-07-08T00:19:00 for WBAN 93033
# Excluding gust at 2015-04-08T21:49:00 for WBAN 93033
# Excluding gust at 2017-01-02T00:17:00 for WBAN 93033
# Excluding gust at 2017-07-30T03:18:00 for WBAN 93033
# Excluding gust at 2018-06-04T02:11:00 for WBAN 93033
# Excluding gust at 2018-06-16T18:32:00 for WBAN 93033
# Excluding gust at 2005-04-05T19:21:00 for WBAN 93042
# Excluding gust at 2021-05-07T22:13:00 for WBAN 93042
# Excluding gust at 2021-06-13T04:32:00 for WBAN 93042
# WBAN 93057 only has 1034 days of data (not 5 years). skipping its 1 gusts
# Excluding gust at 2007-07-11T22:38:00 for WBAN 93102
# Excluding gust at 2008-06-21T21:25:00 for WBAN 93102
# Excluding gust at 2012-04-23T00:52:00 for WBAN 93102
# WBAN 93104 only has 1369 days of data (not 5 years). skipping its 0 gusts
# WBAN 93107 only has 275 days of data (not 5 years). skipping its 0 gusts
# WBAN 93111 only has 853 days of data (not 5 years). skipping its 0 gusts
# WBAN 93115 only has 975 days of data (not 5 years). skipping its 0 gusts
# WBAN 93116 only has 731 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2016-06-27T23:29:00 for WBAN 93167
# Excluding gust at 2017-04-03T22:28:00 for WBAN 93167
# Excluding gust at 2017-09-03T01:10:00 for WBAN 93167
# Excluding gust at 2018-07-10T00:40:00 for WBAN 93167
# Excluding gust at 2021-06-18T02:35:00 for WBAN 93167
# Excluding gust at 2021-07-13T13:45:00 for WBAN 93167
# Excluding gust at 2021-07-25T23:58:00 for WBAN 93167
# Excluding gust at 2021-07-26T00:01:00 for WBAN 93167
# Excluding gust at 2021-10-05T17:48:00 for WBAN 93167
# Excluding gust at 2021-12-15T03:07:00 for WBAN 93167
# WBAN 93226 data quality to low. skipping its 0 gusts
# Excluding gust at 2016-06-08T16:43:00 for WBAN 93730
# Excluding gust at 2020-03-04T03:29:00 for WBAN 93730
# Excluding gust at 2020-04-21T19:18:00 for WBAN 93730
# Excluding gust at 2020-07-22T23:46:00 for WBAN 93730
# Excluding gust at 2021-04-21T18:48:00 for WBAN 93730
# WBAN 93743 only has 1279 days of data (not 5 years). skipping its 2 gusts
# WBAN 93781 only has 1369 days of data (not 5 years). skipping its 1 gusts
# Excluding gust at 2007-07-11T21:44:00 for WBAN 93831
# WBAN 93841 only has 609 days of data (not 5 years). skipping its 5 gusts
# WBAN 93915 only has 1157 days of data (not 5 years). skipping its 3 gusts
# Excluding gust at 2021-06-09T01:47:00 for WBAN 94017
# Excluding gust at 2021-06-11T02:11:00 for WBAN 94017
# Excluding gust at 2021-07-23T01:32:00 for WBAN 94017
# Excluding gust at 2005-07-03T02:19:00 for WBAN 94038
# Excluding gust at 2005-07-21T22:18:00 for WBAN 94038
# Excluding gust at 2021-06-06T05:12:00 for WBAN 94041
# Excluding gust at 2005-06-29T01:17:00 for WBAN 94051
# Excluding gust at 2005-08-10T01:21:00 for WBAN 94054
# Excluding gust at 2006-06-20T02:16:00 for WBAN 94054
# Excluding gust at 2006-11-23T21:07:00 for WBAN 94054
# Excluding gust at 2007-04-18T21:30:00 for WBAN 94054
# Excluding gust at 2008-06-26T10:24:00 for WBAN 94054
# Excluding gust at 2008-07-26T22:15:00 for WBAN 94054
# Excluding gust at 2018-07-28T01:27:00 for WBAN 94054
# Excluding gust at 2020-07-10T18:47:00 for WBAN 94054
# Excluding gust at 2020-07-10T19:32:00 for WBAN 94054
# Excluding gust at 2005-06-07T02:26:00 for WBAN 94056
# Excluding gust at 2005-07-03T02:39:00 for WBAN 94056
# Excluding gust at 2006-08-09T01:53:00 for WBAN 94056
# Excluding gust at 2006-12-14T03:55:00 for WBAN 94056
# Excluding gust at 2007-07-08T04:08:00 for WBAN 94056
# Excluding gust at 2008-11-05T21:21:00 for WBAN 94056
# Excluding gust at 2009-05-12T23:24:00 for WBAN 94056
# Excluding gust at 2010-05-24T21:54:00 for WBAN 94056
# Excluding gust at 2010-05-24T22:01:00 for WBAN 94056
# Excluding gust at 2010-08-02T07:07:00 for WBAN 94056
# Excluding gust at 2010-09-10T00:24:00 for WBAN 94056
# Excluding gust at 2011-07-26T01:08:00 for WBAN 94056
# Excluding gust at 2011-08-01T22:26:00 for WBAN 94056
# Excluding gust at 2015-07-16T00:49:00 for WBAN 94057
# Excluding gust at 2017-06-27T20:50:00 for WBAN 94057
# Excluding gust at 2019-08-05T02:28:00 for WBAN 94057
# Excluding gust at 2019-10-05T05:54:00 for WBAN 94057
# Excluding gust at 2020-06-06T22:22:00 for WBAN 94057
# Excluding gust at 2020-06-21T22:47:00 for WBAN 94057
# Excluding gust at 2020-06-25T21:44:00 for WBAN 94057
# Excluding gust at 2020-07-13T02:08:00 for WBAN 94057
# Excluding gust at 2021-01-14T00:39:00 for WBAN 94057
# Excluding gust at 2021-01-14T01:29:00 for WBAN 94057
# Excluding gust at 2021-05-01T23:46:00 for WBAN 94057
# Excluding gust at 2021-06-20T00:10:00 for WBAN 94057
# WBAN 94099 data quality to low. skipping its 12 gusts
# WBAN 94107 only has 1125 days of data (not 5 years). skipping its 8 gusts
# Excluding gust at 2015-12-07T04:53:00 for WBAN 94225
# Excluding gust at 2016-10-14T19:09:00 for WBAN 94225
# Excluding gust at 2021-11-15T15:21:00 for WBAN 94225
# Excluding gust at 2021-11-15T16:48:00 for WBAN 94225
# Excluding gust at 2021-08-06T01:17:00 for WBAN 94299
# WBAN 94728 only has 1065 days of data (not 5 years). skipping its 0 gusts
# WBAN 94733 only has 699 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2021-09-02T00:59:00 for WBAN 94741
# WBAN 94794 only has 640 days of data (not 5 years). skipping its 0 gusts
# Excluding gust at 2005-06-29T10:43:00 for WBAN 94943
# 490 gusts discarded (from bad stations or bad time ranges)
# Max ASOS station distance errors:
# 03965 3889.816  meters (36.1312,            -97.0697)
# 23081 3262.2146 meters (35.5160775,         -108.78259)
# 26451 2850.1172 meters (61.17190111111111,  -150.0250955555556)
# 13841 2682.4297 meters (39.423809999999996, -83.80677333333334)
# 94846 2579.9368 meters (41.983396666666664, -87.93294666666667)
# 26412 2121.8218 meters (62.961545,          -141.945985)
# 14939 2005.6553 meters (40.84702,           -96.75318499999999)
# 94823 1873.23   meters (40.487958000000006, -80.21774200000002)
# 26616 1733.5525 meters (66.87277999999999,  -162.62111000000002)
# 12916 1719.7272 meters (29.99450333333333,  -90.25990333333334)

end