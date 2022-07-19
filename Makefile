default:
	cat Makefile

julia:
	julia --project

install_gempak_mac:
	sh install_gempak_mac.sh

install_gempak_ubuntu:
	sh install_gempak_ubuntu.sh

grid_236.csv:
	echo "x,y,lat,lon" > grid_236.csv
	wgrib2 a_file_with_grid_236.grib2 -end -inv /dev/null -gridout - | ruby -e 'print STDIN.read.gsub(/ +/, "")' >> grid_236.csv
