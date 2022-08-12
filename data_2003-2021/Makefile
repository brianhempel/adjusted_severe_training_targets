default:
	cat Makefile

get_asos_1_min_measured_gusts:
	# For parallel downloads, run these manually:
	# WORKER=1/5 ruby asos_1_min_measured_gusts/get_asos6405.rb
	# WORKER=2/5 ruby asos_1_min_measured_gusts/get_asos6405.rb
	# WORKER=3/5 ruby asos_1_min_measured_gusts/get_asos6405.rb
	# WORKER=4/5 ruby asos_1_min_measured_gusts/get_asos6405.rb
	# WORKER=5/5 ruby asos_1_min_measured_gusts/get_asos6405.rb
	# Check undownloadable_asos.txt, rename it, and rerun with ONLY_YEAR_MONTHS=2004-07,2005-04,2005-06,...
	# Repeat until undownloadable_asos.txt is empty.
	ruby asos_1_min_measured_gusts/get_asos6405.rb
	ruby deduplicate_sort_merge_csvs.rb asos_1_min_measured_gusts/gusts-20*.csv > asos_1_min_measured_gusts/gusts.csv
	cd asos_1_min_measured_gusts; gzip gusts.csv
	ruby which_asos_months_look_good.rb > which_asos_months_look_good.csv

get_storm_data_reports:
	# Storm Data labeling for estimated/measured sustained/gust isn't consistent until 2003
	START_YEAR=2003 STOP_YEAR=2021 BAD_LATLON_HANDLING=repair ruby storm_data_reports/get_wind_reports.rb storm_data_reports/wind_reports_2003-2021_downloaded.csv
	ruby deduplicate_sort_merge_csvs.rb storm_data_reports/wind_reports_2003-2021_downloaded.csv > storm_data_reports/wind_reports_2003-2021.csv # The merge deduplicates and sorts
	rm storm_data_reports/wind_reports_2003-2021_downloaded.csv

grid_mucape_at_least_one:
	julia mucape_at_least_one_gridded/grid_mucape_at_least_one.jl

grid_at_least_one_lightning_strike:
	julia at_least_one_lightning_strike_gridded/grid_lightning.jl

grid_wind_reports:
	julia at_least_one_wind_report_gridded/grid_wind_reports.jl

get_tropical_cyclones:
	julia tropical_cyclones/get_tropical_cyclones.jl

filter_gusts:
	julia asos_1_min_measured_gusts_filtered/filter_gusts.jl
	cd asos_1_min_measured_gusts_filtered; ruby one_gust_per_hour_per_station.rb gusts_at_least_50_knots_filtered_tc.csv > gusts_at_least_50_knots_filtered_tc_one_per_hour.csv
	cd asos_1_min_measured_gusts_filtered; ruby one_gust_per_hour_per_station.rb gusts_at_least_65_knots_filtered_tc.csv > gusts_at_least_65_knots_filtered_tc_one_per_hour.csv
