require 'csv'
require 'date'

IN_PATH = ARGV[0]

# time_str,time_seconds,wban_id,name,state,county,knots,gust_knots,lat,lon,near_any_wind_reports,near_hurricane_or_tropical_storm
# 2003-04-13 04:44:00 UTC,1050209040,94012,HAVRE CITY COUNTY AP,MT,HILL,29,52,48.5428,-109.7633,false,false
# 2003-04-15 21:37:00 UTC,1050442620,23042,LUBBOCK INTERNATIONAL AP,TX,LUBBOCK,38,50,33.6656,-101.8231,false,false

MINUTE = 60
HOUR   = 60*MINUTE

rows = CSV.read(IN_PATH, headers: true)

puts rows[1].headers.to_csv
rows
  .group_by { |r| r["wban_id"] }
  .flat_map do |wban_id, rows|
    rows
      .group_by { |r| r["time_seconds"].to_i / HOUR }
      .map do |_, hour_rows|
        # first max gust per hour
        hour_rows.max_by { |r| [r["gust_knots"].to_i, -r["time_seconds"].to_i] }
      end
  end
  .sort_by { |r| r["time_seconds"].to_i }
  .each    { |r| puts r.to_csv }
