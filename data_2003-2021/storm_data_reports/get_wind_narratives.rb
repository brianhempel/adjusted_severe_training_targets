require "date"
require "csv"

# Fetches the storm events database from (ENV["START_YEAR"] || 2014) through
# the current year (or ENV["STOP_YEAR"]) and outputs all the tornado, wind, and hail events.
#
# Primarily uses the storm events database because it has start and end times and locations.
#
# The previous year is finalized near the end of Spring of the following year.
#
# If ARGV[3] is "--add_spc_storm_reports", then SPC storm reports from the
# end of the storm events database until one week ago are included.
#
# To run this script, see the Makefile at the project root.


START_YEAR = Integer(ENV["START_YEAR"] || "2003")
STOP_YEAR  = Integer(ENV["STOP_YEAR"]  || Time.now.year)

# Some longitudes are encoded with their decimal point apparently off by one (e.g. -812.15 instead of, presumably -81.215)
# Whether it's an insertion error or an off by one error is not clear so repair is attempted by assuming the start/end longitude
# should be the same and using the other if it looks good. Not perfect, but more reasonable for climatological purposes than
# discarding or not fixing.
DO_REPAIR_LATLONS = (ENV["BAD_LATLON_HANDLING"] == "repair")


# Part 1: Storm Events Database

ROOT_URL = "https://www1.ncdc.noaa.gov/pub/data/swdi/stormevents/csvfiles/"

file_names = `curl #{ROOT_URL}`.scan(/StormEvents_details-ftp_v1\.0_d\d\d\d\d_c\d+\.csv\.gz/).uniq

if file_names.empty?
  STDERR.puts "Could not retreive storm event database file list from https://www1.ncdc.noaa.gov/pub/data/swdi/stormevents/csvfiles/"
  exit 1
end


BEGIN_END_TIMES_HEADERS = %w[
  begin_time_str
  begin_time_seconds
  end_time_str
  end_time_seconds
]

LAT_LON_HEADERS = %w[
  begin_lat
  begin_lon
  end_lat
  end_lon
]

# print (BEGIN_END_TIMES_HEADERS + %w[kind speed speed_type source] + LAT_LON_HEADERS).to_csv

# Event types:
# Astronomical Low Tide
# Avalanche
# Blizzard
# Coastal Flood
# Cold/Wind Chill
# Debris Flow
# Dense Fog
# Dense Smoke
# Drought
# Dust Devil
# Dust Storm
# Excessive Heat
# Extreme Cold/Wind Chill
# Flash Flood
# Flood
# Freezing Fog
# Frost/Freeze
# Funnel Cloud
# Hail
# Heat
# Heavy Rain
# Heavy Snow
# High Surf
# High Wind (Not geocoded!)
# Hurricane
# Ice Storm
# Lake-Effect Snow
# Lakeshore Flood
# Lightning
# Marine Hail
# Marine High Wind
# Marine Hurricane/Typhoon
# Marine Strong Wind (weaker than "high wind")
# Marine Thunderstorm Wind
# Marine Tropical Depression
# Marine Tropical Storm
# Rip Current
# Seiche
# Sleet
# Sneakerwave
# Storm Surge/Tide
# Strong Wind (weaker than "high wind")
# Thunderstorm Wind *
# Tornado
# Tropical Depression
# Tropical Storm
# Volcanic Ashfall
# Waterspout
# Wildfire
# Winter Storm
# Winter Weather

def begin_end_times(row)
  begin_year_month_str = row["BEGIN_YEARMONTH"]
  begin_day_str        = row["BEGIN_DAY"]
  begin_time_str       = row["BEGIN_TIME"]
  end_year_month_str   = row["END_YEARMONTH"]
  end_day_str          = row["END_DAY"]
  end_time_str         = row["END_TIME"]
  tz_offset_hrs        = row["CZ_TIMEZONE"][/-?\d+/].to_i

  begin_time = Time.new(begin_year_month_str.to_i / 100, begin_year_month_str.to_i % 100, begin_day_str.to_i, begin_time_str.to_i / 100, begin_time_str.to_i % 100, 00, "%+03d:00" % tz_offset_hrs)
  end_time   = Time.new(  end_year_month_str.to_i / 100,   end_year_month_str.to_i % 100,   end_day_str.to_i,   end_time_str.to_i / 100,   end_time_str.to_i % 100, 00, "%+03d:00" % tz_offset_hrs)

  [begin_time, end_time]
end

# begin_time_str,begin_time_seconds,end_time_str,end_time_seconds
# 2014-01-11 12:37:00 UTC,1389443820,2014-01-11 12:41:00 UTC,1389444060
def row_to_begin_end_time_cells(row)
  begin_time, end_time = begin_end_times(row)

  begin_end_time_cells(begin_time, end_time)
end


def begin_end_time_cells(begin_time, end_time)
  [
    begin_time.utc.to_s,
    begin_time.utc.to_i,
    end_time.utc.to_s,
    end_time.utc.to_i
  ]
end

# begin_lat,begin_lon,end_lat,end_lon
# 34.3328,-84.5286,34.3476,-84.4811
def row_to_lat_lon_cells(row)
  [
    row["BEGIN_LAT"] || row["Lat"],
    row["BEGIN_LON"] || row["Lon"],
    row["END_LAT"] || row["Lat"],
    row["END_LON"] || row["Lon"]
  ]
end

def valid_lat?(lat)
  (1..90).cover?(lat)
end

def valid_lon?(lon)
  (-180..-2).cover?(lon)
end

# Mutates row.
def perhaps_repair_latlons!(row)
  if DO_REPAIR_LATLONS
    if row["BEGIN_LAT"] && row["END_LAT"]
      if valid_lat?(row["BEGIN_LAT"].to_f) && !valid_lat?(row["END_LAT"].to_f)
        STDERR.puts "Repairing latitude #{row["END_LAT"]} to #{row["BEGIN_LAT"]}"
        row["END_LAT"] = row["BEGIN_LAT"]
      elsif !valid_lat?(row["BEGIN_LAT"].to_f) && valid_lat?(row["END_LAT"].to_f)
        STDERR.puts "Repairing latitude #{row["BEGIN_LAT"]} to #{row["END_LAT"]}"
        row["BEGIN_LAT"] = row["END_LAT"]
      end
    end
    if row["BEGIN_LON"] && row["END_LON"]
      if valid_lon?(row["BEGIN_LON"].to_f) && !valid_lon?(row["END_LON"].to_f)
        STDERR.puts "Repairing longitude #{row["END_LON"]} to #{row["BEGIN_LON"]}"
        row["END_LON"] = row["BEGIN_LON"]
      elsif !valid_lon?(row["BEGIN_LON"].to_f) && valid_lon?(row["END_LON"].to_f)
        STDERR.puts "Repairing longitude #{row["BEGIN_LON"]} to #{row["END_LON"]}"
        row["BEGIN_LON"] = row["END_LON"]
      end
    end
  end
end

def valid_lat_lon?(row)
  valid_lat?((row["BEGIN_LAT"] || row["Lat"]).to_f) &&
  valid_lon?((row["BEGIN_LON"] || row["Lon"]).to_f) &&
  valid_lat?((row["END_LAT"]   || row["Lat"]).to_f) &&
  valid_lon?((row["END_LON"]   || row["Lon"]).to_f)
end


(START_YEAR..STOP_YEAR).each do |year|
  file_name = file_names.grep(/v1\.0_d#{year}_/).last

  next unless file_name

  rows = CSV.parse(`curl #{ROOT_URL + file_name} | gunzip`, headers: true)

  # STDERR.puts "Event types: #{rows.map { |row| row["EVENT_TYPE"] }.uniq.sort}"

  wind_rows = rows.select { |row| row["EVENT_TYPE"].strip == "Thunderstorm Wind" }

  STDERR.puts "#{wind_rows.count} thunderstorm wind events in #{year}"

  # EG = Estimated Gust, MG = Measured Gust, ES = Estimated Sustained, MS = Measured Sustained
  wind_type = {
    "EG" => "gust",
    "MG" => "gust",
    "ES" => "sustained",
    "MS" => "sustained",
  }

  wind_source = {
    "EG" => "estimated",
    "MG" => "measured",
    "ES" => "estimated",
    "MS" => "measured",
  }

  # Although we might use wind hours without geocodes for negative data, we aren't yet.
  wind_rows.select! { |row| perhaps_repair_latlons!(row); valid_lat_lon?(row) }
  # There are so few "sustained" thunderstorm winds events, and they all look like short events so no reason to worry about including or excluding them.
  # wind_rows.select! { |row| (wind_type[row["MAGNITUDE_TYPE"]] || row["MAGNITUDE_TYPE"]) != "sustained" }
  wind_rows.map! do |row|
    row_to_begin_end_time_cells(row) +
    [
      row["EVENT_TYPE"], # kind
      (row["MAGNITUDE"].to_s)[/[\d\.]+/] || "-1", # speed
      wind_type[row["MAGNITUDE_TYPE"]] || row["MAGNITUDE_TYPE"], # speed_type
      wind_source[row["MAGNITUDE_TYPE"]]
    ] +
    row_to_lat_lon_cells(row) +
    [
      row["EVENT_NARRATIVE"]
    ]
  end

  wind_rows.map(&:to_csv).sort.each do |row_csv_str|
    print row_csv_str
  end
end
