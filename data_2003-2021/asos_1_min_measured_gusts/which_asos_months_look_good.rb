require 'csv'
require 'fileutils'

stuffs = {}

Dir.glob("good_row_counts*.csv").each do |good_row_counts_path|
  STDERR.puts good_row_counts_path

  CSV.read(good_row_counts_path, headers: true).each do |row|
    yyyy_mm = row["convective_date"][/\A\d\d\d\d-\d\d/]
    key = [yyyy_mm, row["wban_id"]]
    stuffs[key] ||= 0
    stuffs[key] += row["good_row_count"].to_i
  end
end

wbans = stuffs.keys.map(&:last).uniq.sort

wbans.each do |wban|
  stuffs.keys.select do |yyyy_mm, stuff_wban|
    stuff_wban == wban
  end.sort.each do |yyyy_mm, _|
    puts "#{wban}\t#{yyyy_mm}\t#{stuffs[[yyyy_mm, wban]]}"
  end
end

STDERR.puts stuffs.values.map { |x| x / 1000 * 1000 }.tally.inspect
