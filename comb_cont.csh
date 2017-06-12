#!/bin/csh
#creates the parfile for a particular study set for variable contrasts 

  set cont = 1.5 # minimum contrast
  set iter = ${argv[1]}
  set blur = ${argv[2]}
  set typ = ${argv[3]}
  set studyset = 1
  

echo ${cont} ${iter} ${blur} ${studyset} 
#
#Check study set #
if (( ${studyset} != 1 ) && ( ${studyset} != 2 ) && ( ${studyset} != 3 )) then
  echo "Incorrect study set: ${studyset}"
  exit
endif

set ldir = /galveston2/prostate_spect_full_study/human_spect_ct_study/StudyPrep

# Create combined contrast file lists for lesion present noisy images

set fil1 = ${ldir}/${typ}_cont_${cont}_blur_${blur}_iter_${iter}_set${studyset}
sed -n '/lesion_1/p' ${fil1} > temppar
./vary_contrast ${cont}

# Add cases of lesion absent and noise-free
sed 's/y_lesion_1/y_lesion_0/' temppar > temppar2
sed 's/lesion_1/lesion_0/' temppar2 > temppar3
rm temppar2
sed 's/cont_[0-9].[0-9]/cont_nap/' temppar3 > temppar2
rm temppar3
sed 's/cont_[0-9].[0-9]/cont_nap/' temppar2 > temppar3
rm temppar2
awk '{ print $1 }' temppar3 >> temppar
rm temppar3

sed 's/noise_1/noise_0/' temppar > temppar2
sed 's/counts_[0-9].[0-9][0-9]/counts_nan/' temppar2 > temppar3
rm temppar2

awk '{ print $1 }' temppar3 >> temppar
rm temppar3






