# I actually never got this working. I don't know if I was close.
#
# You probably need more packages than this...this was just the diff for my machine.
brew install openmotif gcc@8 # Fortran 10 produces lots of errors, use Fortran 8
curl -L https://github.com/Unidata/gempak/archive/refs/tags/7.15.0.tar.gz | gunzip | tar -x
cd gempak-7.15.0
source Gemenviron.profile
grep Gemenviron.profile ~/.bash_profile || echo "source $(pwd)/Gemenviron.profile" >> ~/.bash_profile # Change to whatever your profile file is
env | grep NAWIPS # show that source above worked
sed -i '.orig' -e 's+/opt/local+/usr/local+g' -e 's+gfortran-8+gfortran+g' -e 's+gfortran+gfortran-8+g' config/Makeinc.darwin # Make sure we use fortran 8
# https://stackoverflow.com/questions/57734434/libiconv-or-iconv-undefined-symbol-on-mac-osx
sed -i '.orig' -e 's/$(GEMINC) -g/$(GEMINC) -liconv -g/g' config/Makeinc.darwin # need the -liconv flag for linking
sed -i '.orig' -e 's/define H5_HAVE_FEATURES_H 1/undef H5_HAVE_FEATURES_H/g' extlibs/netCDF/v4.3.3.1/include/H5pubconf.h # MacOS doesn't have features.h
make all 2>&1 | tee make.log
make install
