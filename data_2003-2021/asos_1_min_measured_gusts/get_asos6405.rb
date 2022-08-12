# https://data.eol.ucar.edu/datafile/nph-get/113.029/td6405.pdf

# ftp ftp@ftp.ncdc.noaa.gov
# brianhempel@ou.edu
# cd /pub/data/asos-onemin/6405-2020
# prompt
# mget *.dat

require "fileutils"
require "csv"

year_months             = (ENV["ONLY_YEAR_MONTHS"] || "").split(",").map { |year_month_str| year_month_str.split("-").map(&:to_i) }
start_year, start_month = (ENV["START_YEAR_MONTH"] || "2003-1").split("-").map(&:to_i)
end_year,   end_month   = (ENV["END_YEAR_MONTH"]   || "2021-12").split("-").map(&:to_i)

# For parallel downloads...
# ftp.ncdc.noaa.gov allows up to 5 connections.
# WORKER=1/3
# WORKER=2/3
# WORKER=3/3
worker_number, worker_count = (ENV["WORKER"] || "1/1").split("/").map(&:to_i)


if year_months == []
  year_months = (start_year..end_year).to_a.product((1..12).to_a).select do |year, month|
    ([year, month] <=> [start_year, start_month]) >= 0 && ([year, month] <=> [end_year, end_month]) <= 0
  end
end

# Filter by worker number
year_months.sort!
year_months = year_months.each_slice(worker_count).filter_map do |slice|
  slice[worker_number - 1]
end



HERE           = File.expand_path("..", __FILE__)
PROCESS_SCRIPT = File.expand_path("../process_asos6405.rb", __FILE__)
UNDOWNLOADABLE = File.expand_path("../undownloadable_asos.txt", __FILE__)

def out_path(year, month)
  File.join(HERE, "gusts-%04d-%02d.csv" % [year, month])
end

def good_row_counts_path(year, month)
  File.join(HERE, "good_row_counts-%04d-%02d.csv" % [year, month])
end

FileUtils.cd HERE

# This doesn't have as many stations
# system("curl https://www.ncei.noaa.gov/pub/data/noaa/isd-history.csv > isd-history.csv")

# mshr_enhanced.txt is 15mb zipped, 500mb unzipped...lol...fixed-width columns filled with spaces
# Much larger database of stations than isd-history.csv above
system("curl https://www.ncei.noaa.gov/access/homr/file/mshr_enhanced.txt.zip > mshr_enhanced.txt.zip")
system("ruby mshr_enhanced_to_csv.rb > mshr_enhanced_wban_only.csv")

def wait_for_prompt(ftp)
  buf = ""
  loop do
    more_buf = ftp.readpartial(1_000_000)
    buf << more_buf
    print more_buf
    loop do
      sleep(0.5) # Data might still be coming
      break unless more_buf = (fswatch.read_nonblock(1_000_000) rescue nil)
      buf << more_buf
      print more_buf
      STDOUT.flush
    end
    break if buf.end_with?("ftp> ")
  end
  buf
end

def ftp_do(ftp, command)
  ftp.puts command # "password"
  puts command
  wait_for_prompt(ftp)
end

puts "What's your email address?"
EMAIL = gets.strip

exit(1) unless EMAIL =~ /\S+@\S+\.\S+/

def connect_and_do(year, cmd)
  sleep 1 # If we disconnect and reconnect too fast, the server may think we hit our connection limit.
  out = nil
  IO.popen("ftp --no-prompt --prompt -n ftp.ncdc.noaa.gov", "r+") do |ftp|
    wait_for_prompt(ftp)
    ftp_do(ftp, "user ftp #{EMAIL}") # password is email address
    ftp_do(ftp, "cd /pub/data/asos-onemin/6405-#{year}")
    out = ftp_do(ftp, cmd).sub("#{cmd}\n", "").sub("ftp> ", "")
    ftp.puts("quit")
    puts "quit"
  end
  out
end

File.write(UNDOWNLOADABLE, "") unless ENV["START_YEAR_MONTH"] || ENV["ONLY_YEAR_MONTHS"] # clear the file

process_thread = nil

years = year_months.map(&:first).uniq.sort
years.each do |year|
  year_listing = connect_and_do(year, "ls")

  year_files_to_get_and_size =
    year_listing.lines.map do |l|
      [l.split.last, l[32..41].to_i]
    end

  while year_files_to_get_and_size.size < 3015
    sleep 60

    year_listing = connect_and_do(year, "ls")

    year_files_to_get_and_size =
      year_listing.lines.map do |l|
        [l.split.last, l[32..41].to_i]
      end
  end

  year_months.select { |y, _| y == year }.sort.each do |_, month|

    puts "#{year}-#{month}"

    month_files_to_get_and_size =
      year_files_to_get_and_size.select do |name, size|
        name.end_with?("%02d.dat" % month)
      end

    FileUtils.cd HERE

    # Initialize new gusts.csv and good_row_counts.csv
    # These need to match process_asos6405.rb
    File.write(out_path(year, month), %w[
      time_str
      time_seconds
      wban_id
      name
      state
      knots
      gust_knots
    ].to_csv)

    File.write(good_row_counts_path(year, month), %w[
      convective_date
      convective_day_index
      wban_id
      good_row_count
    ].to_csv)

    month_dir = "asos/6405-#{year}#{month}"
    FileUtils.mkdir_p month_dir
    FileUtils.cd month_dir

    connect_and_do(year, "mget *%02d.dat" % month)

    loop do
      month_files_to_get_and_size.select! do |filename, size|
        (File.size(filename) rescue 0) != size
      end
      break if month_files_to_get_and_size.size == 0
      sleep 60
      month_files_to_get_and_size.each do |filename, _|
        connect_and_do(year, "get #{filename}")
      end
    end
    # File.open(UNDOWNLOADABLE, "a") do |undownloadable|
    #   month_files_to_get_and_size.each do |filename, _|
    #     File.exists?(filename) && system("rm #{filename}")
    #     undownloadable.puts(filename)
    #   end
    # end
    process_thread.join if process_thread

    # Generate CSV gust lines from all files, sort them, and write them to gusts.csv
    # But do it while we download more data
    dat_glob = File.join(HERE, month_dir, "*.dat")
    process_thread = Thread.new do
      cmd = "GOOD_ROW_COUNTS_PATH=#{good_row_counts_path(year, month)} ruby #{PROCESS_SCRIPT} #{dat_glob}"
      puts cmd
      buf = `#{cmd}`.lines.sort.join
      File.open(out_path(year, month), "a") { |out| out.print(buf) }
      # system("rm #{dat_glob}")
      system("bzip2 -f #{dat_glob}")
    end
  end
end

process_thread.join if process_thread
