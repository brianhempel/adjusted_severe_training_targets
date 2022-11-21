default:
	cat Makefile

get_population_data:
	# You must get the following files by hand, because it requires a login.
	#
	# gpw-v4-population-count-rev11_2010_2pt5_min_asc.zip
	#
	# Single Year, ASCII, 2.5min, 2010
	open https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-count-rev11
	#
	# No need to unzip

plots:
	julia Casualties.jl