# Returns mshr_enhanced_wban_only.csv as a DataFrame
module StationInfos

import Dates
import CSV
using DataFrames

const stations_info_path = joinpath(@__DIR__, "mshr_enhanced_wban_only.csv")
const station_infos      = CSV.read(stations_info_path, DataFrame, types = Dict(:WBAN_ID => String))

# parse integer 19760630
int_to_date(n) = Dates.Date(n÷10000, mod(n÷100,100), mod(n,100))

station_infos.BEGIN_DATE = int_to_date.(station_infos.BEGIN_DATE)
station_infos.END_DATE   = int_to_date.(station_infos.END_DATE)
station_infos.OBS_ENV    = map(x -> ismissing(x) ? "" : x, station_infos.OBS_ENV)
station_infos.PLATFORM   = map(x -> ismissing(x) ? "" : x, station_infos.PLATFORM)

# Sometimes there are multiple stations for a time range.
# Try and filter down to just the ASOS stations (exlcuding e.g. upper air or radar sites).
function disambiguate_station_infos(infos)
  if nrow(infos) >= 2 && nrow(infos[occursin.("LANDSFC", infos.:OBS_ENV), :]) >= 1
    infos = infos[occursin.("LANDSFC", infos.:OBS_ENV), :]
  end
  if nrow(infos) >= 2 && nrow(infos[occursin.("ASOS", infos.:PLATFORM), :]) >= 1
    infos = infos[occursin.("ASOS", infos.:PLATFORM), :]
  end
  infos
end

end