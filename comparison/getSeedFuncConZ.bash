#!/bin/bash

##################################getSeedFuncConZ.bash##############################
####################### Authored by Max Elliott 3/11/2016 ####################

####Description####

exampleData=$1
seedMask=$2
grayMask=$3


3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $subData > tmp.$prefix.$sub.maskData.1D
3dDeconvolve -quiet -input $subData -polort -1 -num_stimts 1 \
	-stim_file 1 tmp.$prefix.$sub.maskData.1D -stim_label 1 maskData \
	-tout -rout -bucket tmp.$prefix.$sub.maskData.decon.nii
3dcalc -a tmp.$prefix.$sub.maskData.decon.nii'[4]' -b tmp.$prefix.$sub.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix tmp.$prefix.$sub.maskData.R.nii
3dcalc -a tmp.$prefix.$sub.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix $prefix.$sub.maskConnData.Z.nii

