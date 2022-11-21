import Dates

push!(LOAD_PATH, @__DIR__)

import Grids
using Utils

push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "storm_data_reports"))

import WindReports

# begin_time_str,begin_time_seconds,end_time_str,end_time_seconds,kind,speed,speed_type,source,begin_lat,begin_lon,end_lat,end_lon
# 2003-01-22 05:45:00 UTC,1043214300,2003-01-22 06:15:00 UTC,1043216100,Thunderstorm Wind,65,E,,32.65,-85.36667,32.65,-85.36667
# 2003-02-03 17:10:00 UTC,1044292200,2003-02-03 17:15:00 UTC,1044292500,Thunderstorm Wind,52,gust,estimated,36.8,-89.95,36.85,-89.78333


mean(xs) = sum(xs) / length(xs)

const measured_reports  = filter(e -> e.measured,  WindReports.conus_severe_wind_reports)
const estimated_reports = filter(e -> !e.measured, WindReports.conus_severe_wind_reports)

length(estimated_reports)
# 249176

length(measured_reports)
# 31844

# const grid_236_conusish_latlons         = filter(Grids.is_in_conus_bounding_box, Grids.grid_236.latlons)
# const grid_130_cropped_conusish_latlons = filter(Grids.is_in_conus_bounding_box, Grids.grid_130_cropped.latlons)
const grid          = Grids.grid_130_cropped
const conus_bitmask = Grids.grid_130_cropped_conus_mask
const latlons       = grid.latlons



const MINUTE = 60
const HOUR   = 60*MINUTE
const DAY    = 24*HOUR
const WEEK   = 7*DAY

concat(xs)                  = collect(Iterators.flatten(xs))
count_unique_by(f, xs)      = length(unique(map(f, xs)))
count_unique_by_flat(f, xs) = length(unique(concat(map(f, xs))))

seconds_to_convective_day_i(sec)  = (sec - 12*HOUR) ÷ DAY
seconds_to_convective_week_i(sec) = (sec - 12*HOUR) ÷ WEEK # weeks here start on thursday...fine for our purposes
seconds_to_hour_i(sec)            = sec ÷ HOUR
seconds_to_fourhour_i(sec)        = sec ÷ (HOUR * 4)

const nyears     = 2022 - 2003
const ndays      = Int64((Dates.Date(2022) - Dates.Date(2003)) / Dates.Day(1))
const nhours     = ndays * 24
const nfourhours = nhours ÷ 4

const nfolds = 5

const nhours_in_fold     = round(nhours     / nfolds)
const nfourhours_in_fold = round(nfourhours / nfolds)
const ndays_in_fold      = round(ndays      / nfolds)
const nhours_out_of_fold     = nhours     - nhours_in_fold
const nfourhours_out_of_fold = nfourhours - nfourhours_in_fold
const ndays_out_of_fold      = ndays      - ndays_in_fold

# For the few events that straddle week boundaries, we will only put them in one of the weeks.
function is_in_fold(report, fold_i)
  mid_seconds = (report.start_seconds_from_epoch_utc + report.end_seconds_from_epoch_utc) ÷ 2

  (seconds_to_convective_week_i(mid_seconds) % nfolds) + 1 == fold_i
end

function count_gridded_reports(seconds_to_period_i, reports_gridded)
  parallel_map(reports_gridded) do pt_reports
    count_unique_by_flat(pt_reports) do report
      seconds_to_period_i(report.start_seconds_from_epoch_utc):seconds_to_period_i(report.end_seconds_from_epoch_utc)
    end
  end
end


function mad(vec1, vec2)
  sum(abs.(vec1 .- vec2)) / length(vec1)
end

function try_it(σ_km, reports_gridded)
  fold_mads = Float64[]

  for fold_i in 1:nfolds
    test_reports_gridded  = parallel_map(pt_reports -> filter(r ->  is_in_fold(r, fold_i), pt_reports), reports_gridded)
    train_reports_gridded = parallel_map(pt_reports -> filter(r -> !is_in_fold(r, fold_i), pt_reports), reports_gridded)

    test_nhours_with_reports_gridded      = count_gridded_reports(seconds_to_hour_i,           test_reports_gridded)
    test_nfourhours_with_reports_gridded  = count_gridded_reports(seconds_to_fourhour_i,       test_reports_gridded)
    test_ndays_with_reports_gridded       = count_gridded_reports(seconds_to_convective_day_i, test_reports_gridded)
    train_nhours_with_reports_gridded     = count_gridded_reports(seconds_to_hour_i,           train_reports_gridded)
    train_nfourhours_with_reports_gridded = count_gridded_reports(seconds_to_fourhour_i,       train_reports_gridded)
    train_ndays_with_reports_gridded      = count_gridded_reports(seconds_to_convective_day_i, train_reports_gridded)

    test_gustiness_by_hour_gridded      = test_nhours_with_reports_gridded      ./ nhours_in_fold
    test_gustiness_by_fourhour_gridded  = test_nfourhours_with_reports_gridded  ./ nfourhours_in_fold
    test_gustiness_by_day_gridded       = test_ndays_with_reports_gridded       ./ ndays_in_fold
    train_gustiness_by_hour_gridded     = train_nhours_with_reports_gridded     ./ nhours_out_of_fold
    train_gustiness_by_fourhour_gridded = train_nfourhours_with_reports_gridded ./ nfourhours_out_of_fold
    train_gustiness_by_day_gridded      = train_ndays_with_reports_gridded      ./ ndays_out_of_fold

    train_gustiness_by_hour_gridded_blurred     = Grids.gaussian_blur(σ_km, train_gustiness_by_hour_gridded,     only_in_conus = true)
    train_gustiness_by_fourhour_gridded_blurred = Grids.gaussian_blur(σ_km, train_gustiness_by_fourhour_gridded, only_in_conus = true)
    train_gustiness_by_day_gridded_blurred      = Grids.gaussian_blur(σ_km, train_gustiness_by_day_gridded,      only_in_conus = true)

    # println(stderr, "mean gusts/hour in fold: $(Float32(mean(test_gustiness_by_hour_gridded[conus_bitmask]))) out of fold: $(Float32(mean(train_gustiness_by_hour_gridded[conus_bitmask])))")

    hour_mad     = mad(test_gustiness_by_hour_gridded[conus_bitmask],     train_gustiness_by_hour_gridded_blurred[conus_bitmask])
    fourhour_mad = mad(test_gustiness_by_fourhour_gridded[conus_bitmask], train_gustiness_by_fourhour_gridded_blurred[conus_bitmask])
    day_mad      = mad(test_gustiness_by_day_gridded[conus_bitmask],      train_gustiness_by_day_gridded_blurred[conus_bitmask])

    push!(fold_mads, mean([hour_mad, fourhour_mad, day_mad]))
    # push!(fold_mads, mean([hour_mad]))
  end

  mean(fold_mads)
end


const σ_kms = [0, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 35, 50, 75, 100]

function cross_validate(name, reports_gridded)
  best = (Inf, 0)

  println(join(["σ_km", "$(name)_mean_mad"], "\t"))
  for σ_km in σ_kms
    mean_mad = try_it(σ_km, reports_gridded)

    println(join(Any[σ_km, Float32(mean_mad)], "\t"))

    if mean_mad < best[1]
      best = (mean_mad, σ_km)
    end
  end

  println("Best for $name is σ = $(best[2])km")
end


const measured_reports_gridded = WindReports.distribute_to_gridpoints(grid, measured_reports)
cross_validate("measured",  measured_reports_gridded)
# σ_km    measured_mean_mad
# 0.0     0.00037443647
# 3.0     0.00037443533
# 4.0     0.00037437532
# 5.0     0.00037412444
# 6.0     0.00037447826
# 7.0     0.00037600956
# 8.0     0.0003780273
# 9.0     0.00038003654
# 10.0    0.0003819243
# 15.0    0.00039056534
# 20.0    0.0003997349
# 25.0    0.00041036514
# 35.0    0.00043440246
# 50.0    0.00046692762
# 75.0    0.00050431327
# 100.0   0.00053016306
# Best for measured is σ = 5km

const estimated_reports_gridded = WindReports.distribute_to_gridpoints(grid, estimated_reports)
cross_validate("estimated", estimated_reports_gridded)
# σ_km    estimated_mean_mad
# 0.0     0.00082298584
# 3.0     0.0008229807
# 4.0     0.0008226805
# 5.0     0.0008210916
# 6.0     0.0008190563
# 7.0     0.00081818475
# 8.0     0.0008183349
# 9.0     0.00081894634
# 10.0    0.0008197847
# 15.0    0.00082634983
# 20.0    0.0008378112
# 25.0    0.0008546301
# 35.0    0.0008993902
# 50.0    0.0009725174
# 75.0    0.0010747197
# 100.0   0.0011530599
# Best for estimated is σ = 7km

const estimated_sig_reports_gridded = map(pt_reports -> filter(WindReports.is_sig_wind, pt_reports), estimated_reports_gridded)
const measured_sig_reports_gridded  = map(pt_reports -> filter(WindReports.is_sig_wind, pt_reports), measured_reports_gridded)

cross_validate("estimated_sig", estimated_sig_reports_gridded)
# σ_km    estimated_sig_mean_mad
# 0.0     0.00024350337
# 3.0     0.00024350185
# 4.0     0.00024341203
# 5.0     0.00024292295
# 6.0     0.0002420689
# 7.0     0.00024126652
# 8.0     0.00024069527
# 9.0     0.00024026594
# 10.0    0.00023990493
# 15.0    0.00023850043
# 20.0    0.00023767716
# 25.0    0.00023751003
# 35.0    0.00023886525
# 50.0    0.00024344535
# 75.0    0.00025270658
# 100.0   0.00026168476
# Best for estimated_sig is σ = 25km

cross_validate("measured_sig",  measured_sig_reports_gridded)
# σ_km    measured_sig_mean_mad
# 0.0     0.00010630425
# 3.0     0.000106304295
# 4.0     0.00010630663
# 5.0     0.00010631817
# 6.0     0.00010634175
# 7.0     0.000106385756
# 8.0     0.00010645329
# 9.0     0.00010652853
# 10.0    0.00010660533
# 15.0    0.00010698266
# 20.0    0.00010744229
# 25.0    0.00010806525
# 35.0    0.00010968364
# 50.0    0.000112086076
# 75.0    0.000115167866
# 100.0   0.000117675314
# Best for measured_sig is σ = 0km
