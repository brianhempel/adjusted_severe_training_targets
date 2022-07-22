default:
	cat Makefile

get_asos_1_min_measured_gusts:
	ruby asos_1_min_measured_gusts/get_asos6405.rb
	ruby deduplicate_sort_merge_csvs.rb asos_1_min_measured_gusts/gusts-20*.csv > asos_1_min_measured_gusts/gusts.csv

get_storm_data_reports:
	# Storm Data labeling for estimated/measured sustained/gust isn't consistent until 2003
	START_YEAR=2003 STOP_YEAR=2021 BAD_LATLON_HANDLING=repair ruby storm_data_reports/get_wind_events.rb storm_data_reports/tornadoes_2003-2021_downloaded.csv storm_data_reports/wind_events_2003-2021_downloaded.csv storm_data_reports/hail_events_2003-2021_downloaded.csv
	ruby deduplicate_sort_merge_csvs.rb storm_data_reports/wind_events_2003-2021_downloaded.csv > storm_data_reports/wind_events_2003-2021.csv # The merge deduplicates and sorts
	rm storm_data_reports/tornadoes_2003-2021_downloaded.csv storm_data_reports/wind_events_2003-2021_downloaded.csv storm_data_reports/hail_events_2003-2021_downloaded.csv

grid_mucape_at_least_one:
	julia mucape_at_least_one_gridded/grid_mucape_at_least_one.jl

grid_at_least_one_lightning_strike:
	julia at_least_one_lightning_strike_gridded/grid_lightning.jl

grid_wind_events:
	julia grid_wind_events.jl

filter_gusts:
	julia asos_1_min_measured_gusts_filtered/filter_gusts.jl
