require 'csv'
require 'date'
require 'fileutils'

key_to_ngood = {}

years  = 2003..2021
months = 1..12

MINUTES_PER_DAY = 60*24

Dir.glob("good_row_counts*.csv").sort.each do |good_row_counts_path|
  STDERR.print "#{good_row_counts_path}\r"

  CSV.read(good_row_counts_path, headers: true).each do |row|
    yyyy_mm = row["convective_date"][/\A\d\d\d\d-\d\d/]
    key = [yyyy_mm, row["wban_id"]]
    key_to_ngood[key] ||= 0
    key_to_ngood[key] += row["good_row_count"].to_i
  end
end


wbans = key_to_ngood.keys.map(&:last).uniq.sort

yyyy_mms            = years.flat_map { |yr| months.map { |mon| "%04d-%02d" % [yr, mon] } }
month_dates         = years.flat_map { |yr| months.map { |mon| Date.new(yr, mon) } }
month_minute_counts = years.flat_map { |yr| months.map { |mon| (Date.new(yr, mon).next_month - Date.new(yr, mon)).to_i * MINUTES_PER_DAY } }

puts (["wban_id", "begin_95%_uptime", "end_95%_uptime", "95%_exclude_months", "95%_days", "begin_90%_uptime", "end_90%_uptime", "90%_exclude_months", "90%_days"] + yyyy_mms).to_csv

def range_ndays(asdf, range)
  asdf.select { |month_date, ngood, _| range.cover?(month_date) && ngood >  0 }.map { |month_date, _, _| month_date.next_month - month_date }.sum.to_i
end

all_possible_ranges =
  month_dates.product(month_dates).select do |date1, date2|
    date2 >= date1
  end.map do |date1, date2|
    date1..date2
  end


STDERR.print "                                  \r"
wbans.sort.each do |wban|
  STDERR.print "#{wban}\r"

  month_ngoods = yyyy_mms.map do |yyyy_mm|
    key_to_ngood[[yyyy_mm, wban]] || 0
  end
  month_uptime_percentages = month_ngoods.zip(month_minute_counts).map do |ngood, month_minute_count|
    ngood.to_f / month_minute_count * 100
  end

  month_date_to_ngood = month_dates.zip(month_ngoods).to_h

  possible_ranges =
    all_possible_ranges.select do |range|
      month_date_to_ngood[range.begin] > 0 && month_date_to_ngood[range.end] > 0
    end

  # 95% threshold?
  # Smith et al 2013: "To be included in this study, ASOS/AWOS stations must have archived data available for ≥95% of the days during the 7-yr period (686 sites)."
  # but that's days, not obs...
  # 90% is a more reasonable threshold for obs

  asdf = month_dates.zip(month_ngoods, month_minute_counts)

  range_95 = possible_ranges.select do |range|
    in_range = asdf.select { |month_date, _, _| range.cover?(month_date) }
    ngood_in_range   = in_range.map { |_, ngood, _| ngood }.sum
    minutes_in_range = in_range.map { |_, ngood, mins| ngood > 0 ? mins : 0 }.sum
    ngood_in_range.to_f / minutes_in_range >= 0.95
  end.max_by do |range|
    range_ndays(asdf, range)
  end || [nil, nil]

  range_90 = possible_ranges.select do |range|
    in_range = asdf.select { |month_date, _, _| range.cover?(month_date) }
    ngood_in_range   = in_range.map { |_, ngood, _| ngood }.sum
    minutes_in_range = in_range.map { |_, ngood, mins| ngood > 0 ? mins : 0 }.sum
    ngood_in_range.to_f / minutes_in_range >= 0.9
  end.max_by do |range|
    range_ndays(asdf, range)
  end || [nil, nil]

  range_95_excluded_months = range_95.first && asdf.select { |month_date, ngood, _| range_95.cover?(month_date) && ngood == 0 }.map { |month_date, _, _| month_date }
  range_90_excluded_months = range_90.first && asdf.select { |month_date, ngood, _| range_90.cover?(month_date) && ngood == 0 }.map { |month_date, _, _| month_date }

  row = [
    wban,
    range_95.first&.strftime("%Y-%m"),
    range_95.last&.strftime("%Y-%m"),
    (range_95_excluded_months || []).map { |date| date.strftime("%Y-%m") }.join(" "),
    range_95.first && range_ndays(asdf, range_95),
    range_90.first&.strftime("%Y-%m"),
    range_90.last&.strftime("%Y-%m"),
    (range_90_excluded_months || []).map { |date| date.strftime("%Y-%m") }.join(" "),
    range_90.first && range_ndays(asdf, range_90),
  ] + month_uptime_percentages

  puts row.to_csv
end
