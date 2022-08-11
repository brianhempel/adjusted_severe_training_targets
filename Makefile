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

grid_227.csv:
	echo "x,y,lat,lon" > grid_227.csv
	wgrib2 a_file_with_grid_227.grib2 -end -inv /dev/null -gridout - | ruby -e 'print STDIN.read.gsub(/ +/, "")' >> grid_227.csv

compute_asos_gustiness:
	JULIA_NUM_THREADS=${CORE_COUNT} julia ASOSGustiness.jl > out/asos_gustiness.csv

compute_CONUS_edge_correction_factors:
	JULIA_NUM_THREADS=${CORE_COUNT} julia CONUSEdgeCorrection.jl > out/conus_25mi_edge_correction_factors_grid_130_cropped.csv

compute_reports_gustiness:
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated > out/estimated_reports_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured > out/measured_reports_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl all > out/all_reports_gustiness.csv

compute_reports_gustiness_halves:
	# even 9-year periods, so we don't cut a year in half. sorry 2012
	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2003-2011 julia ReportedGustiness.jl estimated > out/estimated_reports_gustiness_2003-2011.csv
	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2003-2011 julia ReportedGustiness.jl measured > out/measured_reports_gustiness_2003-2011.csv
	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2003-2011 julia ReportedGustiness.jl all > out/all_reports_gustiness_2003-2011.csv
	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2013-2021 julia ReportedGustiness.jl estimated > out/estimated_reports_gustiness_2013-2021.csv
	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2013-2021 julia ReportedGustiness.jl measured > out/measured_reports_gustiness_2013-2021.csv
	JULIA_NUM_THREADS=${CORE_COUNT} YEAR_RANGE=2013-2021 julia ReportedGustiness.jl all > out/all_reports_gustiness_2013-2021.csv

find_best_blurs:
	JULIA_NUM_THREADS=${CORE_COUNT} julia FindBestASOSSpatialInterpolation.jl
	JULIA_NUM_THREADS=${CORE_COUNT} julia FindBestReportsBlur.jl

blur_gustiness:
	# manually copy the blurring params found above into these scripts
	JULIA_NUM_THREADS=${CORE_COUNT} julia ApplyBestASOSSpatialInterpolation.jl
	JULIA_NUM_THREADS=${CORE_COUNT} julia ApplyBestReportsBlur.jl

# compute_gust_point_to_neighborhood_correction:
# 	JULIA_NUM_THREADS=${CORE_COUNT} julia PointToNeighborhoodCorrection.jl > out/point_to_neighborhood_correction.txt

# compute_gust_point_to_neighborhood_correction_v2:
# 	JULIA_NUM_THREADS=${CORE_COUNT} julia PointToNeighborhoodCorrectionV2.jl > out/point_to_neighborhood_correction_v2.txt

# compute_simple_weight_shifting_correction:
# 	JULIA_NUM_THREADS=${CORE_COUNT} julia WeightShiftingCorrection.jl > out/weight_shifting_correction.txt

normalization:
	JULIA_NUM_THREADS=${CORE_COUNT} julia MakeNormalization.jl 1
	# JULIA_NUM_THREADS=${CORE_COUNT} julia MakeNormalization.jl 1 2 3 4 5 6 10

compute_reports_normalized_gustiness:
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x1_normalization_grid_130_cropped > out/estimated_reports_x1_normalized_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x2_normalization_grid_130_cropped > out/estimated_reports_x2_normalized_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x3_normalization_grid_130_cropped > out/estimated_reports_x3_normalized_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x4_normalization_grid_130_cropped > out/estimated_reports_x4_normalized_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x5_normalization_grid_130_cropped > out/estimated_reports_x5_normalized_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x6_normalization_grid_130_cropped > out/estimated_reports_x6_normalized_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl estimated_normalized x10_normalization_grid_130_cropped > out/estimated_reports_x10_normalized_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x1_normalization_grid_130_cropped > out/estimated_reports_x1_normalized_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x2_normalization_grid_130_cropped > out/estimated_reports_x2_normalized_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x3_normalization_grid_130_cropped > out/estimated_reports_x3_normalized_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x4_normalization_grid_130_cropped > out/estimated_reports_x4_normalized_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x5_normalization_grid_130_cropped > out/estimated_reports_x5_normalized_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x6_normalization_grid_130_cropped > out/estimated_reports_x6_normalized_plus_measured_reports_gustiness.csv
	# JULIA_NUM_THREADS=${CORE_COUNT} julia ReportedGustiness.jl measured+estimated_normalized x10_normalization_grid_130_cropped > out/estimated_reports_x10_normalized_plus_measured_reports_gustiness.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia ApplyBestReportsBlur.jl

compute_verifiability_mask:
	JULIA_NUM_THREADS=${CORE_COUNT} julia VerifiabilityMask.jl > out/verifiability_mask.csv
	JULIA_NUM_THREADS=${CORE_COUNT} julia VerifiabilityMask.jl sig > out/verifiability_mask_sig.csv

plots:
	JULIA_NUM_THREADS=${CORE_COUNT} julia Plot.jl