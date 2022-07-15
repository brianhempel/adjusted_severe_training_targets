
get_measured_wind_gusts:
	ruby asos_1_min_measured_gusts/get_asos6405.rb
	ruby deduplicate_sort_merge_csvs.rb asos_1_min_measured_gusts/gusts-20*.csv > asos_1_min_measured_gusts/gusts.csv

wind_events_for_gustiness:
	# Storm Data labeling for estimated/measured sustained/gust isn't consistent until 2003
	START_YEAR=2003 STOP_YEAR=2021 BAD_LATLON_HANDLING=repair ruby storm_data_reports/get_wind_events.rb storm_data_reports/tornadoes_2003-2021_downloaded.csv storm_data_reports/wind_events_2003-2021_downloaded.csv storm_data_reports/hail_events_2003-2021_downloaded.csv
	ruby deduplicate_sort_merge_csvs.rb storm_data_reports/wind_events_2003-2021_downloaded.csv > storm_data_reports/wind_events_2003-2021.csv # The merge deduplicates and sorts
	rm storm_data_reports/tornadoes_2003-2021_downloaded.csv storm_data_reports/wind_events_2003-2021_downloaded.csv storm_data_reports/hail_events_2003-2021_downloaded.csv
