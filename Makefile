default:
	cat Makefile

.PHONY: plots

julia:
	julia --project

install_gempak_mac:
	# I actually never got this working.
	sh install_gempak_mac.sh

install_gempak_ubuntu:
	sh install_gempak_ubuntu.sh

grid_236.csv:
	echo "x,y,lat,lon" > grid_236.csv
	wgrib2 a_file_with_grid_236.grib2 -end -inv /dev/null -gridout - | ruby -e 'print STDIN.read.gsub(/ +/, "")' >> grid_236.csv

grid_130.csv:
	echo "x,y,lat,lon" > grid_130.csv
	wgrib2 a_file_with_grid_130.grib2 -end -inv /dev/null -gridout - | ruby -e 'print STDIN.read.gsub(/ +/, "")' >> grid_130.csv

a_file_with_grid_130_cropped.grib2:
	echo "Uncropped grid 130:"
	wgrib2 a_file_with_grid_130.grib2 -grid
	# https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/new_grid.html
	wgrib2 a_file_with_grid_130.grib2 -new_grid_winds grid -new_grid lambert:265.000000:25.000000:25.000000:25.000000 234.856:437:13545.000000 19.724:256:13545.000000 a_file_with_grid_130_cropped.grib2
	echo "Cropped grid 130:"
	wgrib2 a_file_with_grid_130_cropped.grib2 -grid
	# wgrib2 a_file_with_grid_130_cropped.grib2 -end -inv /dev/null -gridout - | ruby -e 'print STDIN.read.gsub(/ +/, "")' >> grid_130_cropped.csv



# Now run the tasks in data_2003-2021/Makefile

compute_asos_gustiness:
	JULIA_NUM_THREADS=${CORE_COUNT} julia ASOSGustiness.jl > out/asos_gustiness.csv

compute_CONUS_edge_correction_factors:
	# Points near the edge of CONUS won't have as many storm reports within 25mi. What should we multiply the storm report count by to compensate?
	JULIA_NUM_THREADS=${CORE_COUNT} julia CONUSEdgeCorrection.jl > out/conus_25mi_edge_correction_factors_grid_130_cropped.csv

compute_reports_gustiness:
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated > out/estimated_reports_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured > out/measured_reports_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl all > out/all_reports_gustiness.csv

# compute_reports_gustiness_halves:
# 	# even 9-year periods, so we don't cut a year in half. sorry 2012
# 	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2003-2011 julia ReportedGustiness.jl estimated > out/estimated_reports_gustiness_2003-2011.csv
# 	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2003-2011 julia ReportedGustiness.jl measured > out/measured_reports_gustiness_2003-2011.csv
# 	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2003-2011 julia ReportedGustiness.jl all > out/all_reports_gustiness_2003-2011.csv
# 	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2013-2021 julia ReportedGustiness.jl estimated > out/estimated_reports_gustiness_2013-2021.csv
# 	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2013-2021 julia ReportedGustiness.jl measured > out/measured_reports_gustiness_2013-2021.csv
# 	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2013-2021 julia ReportedGustiness.jl all > out/all_reports_gustiness_2013-2021.csv

find_best_blurs:
	JULIA_NUM_THREADS=${CORE_COUNT} julia FindBestASOSSpatialInterpolation.jl
	JULIA_NUM_THREADS=${CORE_COUNT} julia FindBestReportsBlur.jl

blur_gustiness:
	# Manually copy the blurring params found above into these scripts.
	JULIA_NUM_THREADS=${CORE_COUNT} julia ApplyBestASOSSpatialInterpolation.jl
	JULIA_NUM_THREADS=${CORE_COUNT} julia ApplyBestReportsBlur.jl

reweighting:
	JULIA_NUM_THREADS=${CORE_COUNT} julia MakeReweighting.jl 1
	# JULIA_NUM_THREADS=${CORE_COUNT} julia MakeReweighting.jl 1 2 3 4 5 6 10

compute_reports_reweighted_gustiness:
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x1_reweighting_grid_130_cropped > out/estimated_reports_x1_reweighted_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x2_reweighting_grid_130_cropped > out/estimated_reports_x2_reweighted_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x3_reweighting_grid_130_cropped > out/estimated_reports_x3_reweighted_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x4_reweighting_grid_130_cropped > out/estimated_reports_x4_reweighted_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x5_reweighting_grid_130_cropped > out/estimated_reports_x5_reweighted_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x6_reweighting_grid_130_cropped > out/estimated_reports_x6_reweighted_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_reweighted x10_reweighting_grid_130_cropped > out/estimated_reports_x10_reweighted_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x1_reweighting_grid_130_cropped > out/estimated_reports_x1_reweighted_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x2_reweighting_grid_130_cropped > out/estimated_reports_x2_reweighted_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x3_reweighting_grid_130_cropped > out/estimated_reports_x3_reweighted_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x4_reweighting_grid_130_cropped > out/estimated_reports_x4_reweighted_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x5_reweighting_grid_130_cropped > out/estimated_reports_x5_reweighted_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x6_reweighting_grid_130_cropped > out/estimated_reports_x6_reweighted_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_reweighted x10_reweighting_grid_130_cropped > out/estimated_reports_x10_reweighted_plus_measured_reports_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ApplyBestReportsBlur.jl

compute_verifiability_mask:
	# I don't think I'm going to use this.
	JULIA_NUM_THREADS=${CORE_COUNT} julia VerifiabilityMask.jl > out/verifiability_mask.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia VerifiabilityMask.jl sig > out/verifiability_mask_sig.csv

plots:
	JULIA_NUM_THREADS=${CORE_COUNT} julia Plot.jl