# Based on https://github.com/Unidata/gempak/issues/57#issuecomment-1066984367
# and https://github.com/whatheway/GEMPAK/blob/main/GEMPAK-Install.sh
sudo apt install make autoconf automake libtool gcc build-essential gfortran libx11-dev libxt-dev libxext-dev libmotif-dev libxft-dev libxtst-dev xorg xbitmaps flex byacc locate libmotif-common libmotif-dev xfonts-100dpi xfonts-75dpi xfonts-cyrillic libxpm4 libxpm-dev gfortran-8
curl -L https://github.com/Unidata/gempak/archive/refs/tags/7.15.0.tar.gz | gunzip | tar -x
cd gempak-7.15.0
source Gemenviron.profile
env | grep NAWIPS
mv config/Makeinc.linux64_gfortran config/Makeinc.linux64_gfortran.orig
ln -s Makeinc.linux64_gfortran_ubuntu config/Makeinc.linux64_gfortran
make all 2>&1 | tee make.log
make install
grep Gemenviron.profile ~/.profile || echo "source $(pwd)/Gemenviron.profile" >> ~/.profile # Change to whatever your profile file is
