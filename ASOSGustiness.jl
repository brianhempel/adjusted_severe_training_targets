
import Dates

push!(LOAD_PATH, @__DIR__)

import ASOSStations
import Grids
using Utils

push!(LOAD_PATH, joinpath(@__DIR__, "data_2003-2021", "storm_data_reports"))

import WindReports

const estimated_reports = filter(e -> !e.measured, WindReports.conus_severe_wind_reports)


report_to_hour_is(report)           = seconds_to_hour_i(report.start_seconds_from_epoch_utc):seconds_to_hour_i(report.end_seconds_from_epoch_utc)
report_to_fourhour_is(report)       = seconds_to_fourhour_i(report.start_seconds_from_epoch_utc):seconds_to_fourhour_i(report.end_seconds_from_epoch_utc)
report_to_convective_day_is(report) = seconds_to_convective_day_i(report.start_seconds_from_epoch_utc):seconds_to_convective_day_i(report.end_seconds_from_epoch_utc)


function make_row(wban_id, name, state, latlon, legit_hours, legit_fourhours, legit_convective_days, ndays, gust_hours, gust_fourhours, gust_convective_days, sig_gust_hours, sig_gust_fourhours, sig_gust_convective_days)

  @assert ndays      == length(legit_convective_days)
  @assert ndays * 6  == length(legit_fourhours)
  @assert ndays * 24 == length(legit_hours)

  nhours_with_gusts         = count_unique(gust_hours)
  nfourhours_with_gusts     = count_unique(gust_fourhours)
  ndays_with_gusts          = count_unique(gust_convective_days)
  nhours_with_sig_gusts     = count_unique(sig_gust_hours)
  nfourhours_with_sig_gusts = count_unique(sig_gust_fourhours)
  ndays_with_sig_gusts      = count_unique(sig_gust_convective_days)

  station_est_reports = filter(estimated_reports) do report
    any(hour_i -> hour_i in legit_hours, report_to_hour_is(report)) &&
    WindReports.report_is_within_25mi(latlon, report)
  end
  station_est_sig_reports = filter(WindReports.is_sig_wind, station_est_reports)

  # reports overlapping the time boundary can spill over, so need the extra filtering step
  est_report_hours               = filter(i -> i in legit_hours,           concat_map(report_to_hour_is,           station_est_reports))
  est_report_fourhours           = filter(i -> i in legit_fourhours,       concat_map(report_to_fourhour_is,       station_est_reports))
  est_report_convective_days     = filter(i -> i in legit_convective_days, concat_map(report_to_convective_day_is, station_est_reports))
  est_sig_report_hours           = filter(i -> i in legit_hours,           concat_map(report_to_hour_is,           station_est_sig_reports))
  est_sig_report_fourhours       = filter(i -> i in legit_fourhours,       concat_map(report_to_fourhour_is,       station_est_sig_reports))
  est_sig_report_convective_days = filter(i -> i in legit_convective_days, concat_map(report_to_convective_day_is, station_est_sig_reports))

  nhours_with_est_reports         = count_unique(est_report_hours)
  nfourhours_with_est_reports     = count_unique(est_report_fourhours)
  ndays_with_est_reports          = count_unique(est_report_convective_days)
  nhours_with_est_sig_reports     = count_unique(est_sig_report_hours)
  nfourhours_with_est_sig_reports = count_unique(est_sig_report_fourhours)
  ndays_with_est_sig_reports      = count_unique(est_sig_report_convective_days)

  est_report_hours_tally               = tally(est_report_hours)
  est_report_fourhours_tally           = tally(est_report_fourhours)
  est_report_convective_days_tally     = tally(est_report_convective_days)
  est_sig_report_hours_tally           = tally(est_sig_report_hours)
  est_sig_report_fourhours_tally       = tally(est_sig_report_fourhours)
  est_sig_report_convective_days_tally = tally(est_sig_report_convective_days)

  mean_est_reports_in_hours_with_est_reports                   = mean(values(est_report_hours_tally))
  mean_est_reports_in_fourhours_with_est_reports               = mean(values(est_report_fourhours_tally))
  mean_est_reports_in_convective_days_with_est_reports         = mean(values(est_report_convective_days_tally))
  mean_est_sig_reports_in_hours_with_est_sig_reports           = mean(values(est_sig_report_hours_tally))
  mean_est_sig_reports_in_fourhours_with_est_sig_reports       = mean(values(est_sig_report_fourhours_tally))
  mean_est_sig_reports_in_convective_days_with_est_sig_reports = mean(values(est_sig_report_convective_days_tally))

  mean_est_reports_in_report_hours_with_gusts                   = mean(filter(n -> n > 0, map(i -> get(est_report_hours_tally,               i, 0), unique(gust_hours)))) # heh, gust_hours will already be unique
  mean_est_reports_in_report_fourhours_with_gusts               = mean(filter(n -> n > 0, map(i -> get(est_report_fourhours_tally,           i, 0), unique(gust_fourhours))))
  mean_est_reports_in_report_convective_days_with_gusts         = mean(filter(n -> n > 0, map(i -> get(est_report_convective_days_tally,     i, 0), unique(gust_convective_days))))
  mean_est_sig_reports_in_report_hours_with_sig_gusts           = mean(filter(n -> n > 0, map(i -> get(est_sig_report_hours_tally,           i, 0), unique(sig_gust_hours)))) # heh, sig_gust_hours will already be unique
  mean_est_sig_reports_in_report_fourhours_with_sig_gusts       = mean(filter(n -> n > 0, map(i -> get(est_sig_report_fourhours_tally,       i, 0), unique(sig_gust_fourhours))))
  mean_est_sig_reports_in_report_convective_days_with_sig_gusts = mean(filter(n -> n > 0, map(i -> get(est_sig_report_convective_days_tally, i, 0), unique(sig_gust_convective_days))))

  # choose 1.0 here to be conservative about our question: does the number of reports predict severe gusts?
  mean_est_reports_in_report_hours_with_gusts                   = nhours_with_est_reports         > 0 && isnan(mean_est_reports_in_report_hours_with_gusts)                   ? 1.0 : mean_est_reports_in_report_hours_with_gusts
  mean_est_reports_in_report_fourhours_with_gusts               = nfourhours_with_est_reports     > 0 && isnan(mean_est_reports_in_report_fourhours_with_gusts)               ? 1.0 : mean_est_reports_in_report_fourhours_with_gusts
  mean_est_reports_in_report_convective_days_with_gusts         = ndays_with_est_reports          > 0 && isnan(mean_est_reports_in_report_convective_days_with_gusts)         ? 1.0 : mean_est_reports_in_report_convective_days_with_gusts
  mean_est_sig_reports_in_report_hours_with_sig_gusts           = nhours_with_est_sig_reports     > 0 && isnan(mean_est_sig_reports_in_report_hours_with_sig_gusts)           ? 1.0 : mean_est_sig_reports_in_report_hours_with_sig_gusts
  mean_est_sig_reports_in_report_fourhours_with_sig_gusts       = nfourhours_with_est_sig_reports > 0 && isnan(mean_est_sig_reports_in_report_fourhours_with_sig_gusts)       ? 1.0 : mean_est_sig_reports_in_report_fourhours_with_sig_gusts
  mean_est_sig_reports_in_report_convective_days_with_sig_gusts = ndays_with_est_sig_reports      > 0 && isnan(mean_est_sig_reports_in_report_convective_days_with_sig_gusts) ? 1.0 : mean_est_sig_reports_in_report_convective_days_with_sig_gusts

  prob_asos_gust_hour_given_0_est_reports          = mean([i in gust_hours           ? 1 : 0 for i in legit_hours           if get(est_report_hours_tally,           i, 0) == 0])
  prob_asos_gust_hour_given_1_est_reports          = mean([i in gust_hours           ? 1 : 0 for i in legit_hours           if get(est_report_hours_tally,           i, 0) == 1])
  prob_asos_gust_hour_given_2_est_reports          = mean([i in gust_hours           ? 1 : 0 for i in legit_hours           if get(est_report_hours_tally,           i, 0) == 2])
  prob_asos_gust_hour_given_3_est_reports          = mean([i in gust_hours           ? 1 : 0 for i in legit_hours           if get(est_report_hours_tally,           i, 0) == 3])
  prob_asos_gust_hour_given_at_least_4_est_reports = mean([i in gust_hours           ? 1 : 0 for i in legit_hours           if get(est_report_hours_tally,           i, 0) >= 4])
  prob_asos_gust_day_given_0_est_reports           = mean([i in gust_convective_days ? 1 : 0 for i in legit_convective_days if get(est_report_convective_days_tally, i, 0) == 0])
  prob_asos_gust_day_given_1_est_reports           = mean([i in gust_convective_days ? 1 : 0 for i in legit_convective_days if get(est_report_convective_days_tally, i, 0) == 1])
  prob_asos_gust_day_given_2_est_reports           = mean([i in gust_convective_days ? 1 : 0 for i in legit_convective_days if get(est_report_convective_days_tally, i, 0) == 2])
  prob_asos_gust_day_given_3_est_reports           = mean([i in gust_convective_days ? 1 : 0 for i in legit_convective_days if get(est_report_convective_days_tally, i, 0) == 3])
  prob_asos_gust_day_given_at_least_4_est_reports  = mean([i in gust_convective_days ? 1 : 0 for i in legit_convective_days if get(est_report_convective_days_tally, i, 0) >= 4])

  nyears = ndays / 365.25
  row = Any[
    wban_id,
    name,
    state,
    latlon[1],
    latlon[2],
    ndays,
    nhours_with_gusts,
    nfourhours_with_gusts,
    ndays_with_gusts,
    nhours_with_sig_gusts,
    nfourhours_with_sig_gusts,
    ndays_with_sig_gusts,
    Float32(nhours_with_gusts         / nyears),
    Float32(nfourhours_with_gusts     / nyears),
    Float32(ndays_with_gusts          / nyears),
    Float32(nhours_with_sig_gusts     / nyears),
    Float32(nfourhours_with_sig_gusts / nyears),
    Float32(ndays_with_sig_gusts      / nyears),
    nhours_with_est_reports,
    nfourhours_with_est_reports,
    ndays_with_est_reports,
    nhours_with_est_sig_reports,
    nfourhours_with_est_sig_reports,
    ndays_with_est_sig_reports,
    Float32(mean_est_reports_in_hours_with_est_reports),
    Float32(mean_est_reports_in_fourhours_with_est_reports),
    Float32(mean_est_reports_in_convective_days_with_est_reports),
    Float32(mean_est_sig_reports_in_hours_with_est_sig_reports),
    Float32(mean_est_sig_reports_in_fourhours_with_est_sig_reports),
    Float32(mean_est_sig_reports_in_convective_days_with_est_sig_reports),
    Float32(mean_est_reports_in_report_hours_with_gusts),
    Float32(mean_est_reports_in_report_fourhours_with_gusts),
    Float32(mean_est_reports_in_report_convective_days_with_gusts),
    Float32(mean_est_sig_reports_in_report_hours_with_sig_gusts),
    Float32(mean_est_sig_reports_in_report_fourhours_with_sig_gusts),
    Float32(mean_est_sig_reports_in_report_convective_days_with_sig_gusts),
    length(station_est_reports),
    Float32(length(station_est_reports) / nyears),
    prob_asos_gust_hour_given_0_est_reports,
    prob_asos_gust_hour_given_1_est_reports,
    prob_asos_gust_hour_given_2_est_reports,
    prob_asos_gust_hour_given_3_est_reports,
    prob_asos_gust_hour_given_at_least_4_est_reports,
    prob_asos_gust_day_given_0_est_reports,
    prob_asos_gust_day_given_1_est_reports,
    prob_asos_gust_day_given_2_est_reports,
    prob_asos_gust_day_given_3_est_reports,
    prob_asos_gust_day_given_at_least_4_est_reports,
  ]
  println(join(row, ','))
end

println(join(
  [
    "wban_id",
    "name",
    "state",
    "lat",
    "lon",
    "ndays",
    "nhours_with_gusts",
    "nfourhours_with_gusts",
    "ndays_with_gusts",
    "nhours_with_sig_gusts",
    "nfourhours_with_sig_gusts",
    "ndays_with_sig_gusts",
    "gust_hours_per_year",
    "gust_fourhours_per_year",
    "gust_days_per_year",
    "sig_gust_hours_per_year",
    "sig_gust_fourhours_per_year",
    "sig_gust_days_per_year",
    "nhours_with_est_reports",
    "nfourhours_with_est_reports",
    "ndays_with_est_reports",
    "nhours_with_est_sig_reports",
    "nfourhours_with_est_sig_reports",
    "ndays_with_est_sig_reports",
    "mean_est_reports_in_hours_with_est_reports",
    "mean_est_reports_in_fourhours_with_est_reports",
    "mean_est_reports_in_convective_days_with_est_reports",
    "mean_est_sig_reports_in_hours_with_est_sig_reports",
    "mean_est_sig_reports_in_fourhours_with_est_sig_reports",
    "mean_est_sig_reports_in_convective_days_with_est_sig_reports",
    "mean_est_reports_in_report_hours_with_gusts",
    "mean_est_reports_in_report_fourhours_with_gusts",
    "mean_est_reports_in_report_convective_days_with_gusts",
    "mean_est_sig_reports_in_report_hours_with_sig_gusts",
    "mean_est_sig_reports_in_report_fourhours_with_sig_gusts",
    "mean_est_sig_reports_in_report_convective_days_with_sig_gusts",
    "nest_reports", # number of estimated reports
    "est_reports_per_year",
    "prob_asos_gust_hour_given_0_est_reports",
    "prob_asos_gust_hour_given_1_est_reports",
    "prob_asos_gust_hour_given_2_est_reports",
    "prob_asos_gust_hour_given_3_est_reports",
    "prob_asos_gust_hour_given_4+_est_reports",
    "prob_asos_gust_day_given_0_est_reports",
    "prob_asos_gust_day_given_1_est_reports",
    "prob_asos_gust_day_given_2_est_reports",
    "prob_asos_gust_day_given_3_est_reports",
    "prob_asos_gust_day_given_4+_est_reports",
  ], ","
))

for station in sort(ASOSStations.stations, by = (s -> -(length(s.gusts) + 0.001) / s.ndays))
  make_row(
    station.wban_id,
    station.name,
    station.state,
    station.latlon,
    station.legit_hours,
    station.legit_fourhours,
    station.legit_convective_days,
    station.ndays,
    station.gust_hours,
    station.gust_fourhours,
    station.gust_convective_days,
    station.sig_gust_hours,
    station.sig_gust_fourhours,
    station.sig_gust_convective_days,
  )
end
