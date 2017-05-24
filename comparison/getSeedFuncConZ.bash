#!/bin/bash

##################################getSeedFuncConZ.bash##############################
####################### Authored by Max Elliott 3/11/2016 ####################

####Description####
#made to speed up the extraction of Z scores from ROIs for purposes of seed diffs and cwas followups. Slow if not run on cluster

data=$1     ##Time series fMRI volume
seedMask=$2 ##mask volume
maskSelector=$3 ## index for your seed of interest, likely 1 unless there are multiple seeds in mask
outWD=$4		##Directory where you want output placed
prefix=$5		## prefix to be appended to .Z.nii.gz suffix

3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $data > $outWD/tmp.$prefix.maskData.1D
3dDeconvolve -quiet -input $data -polort -1 -num_stimts 1 \
	-stim_file 1 ${outWD}/tmp.$prefix.maskData.1D -stim_label 1 maskData \
	-tout -rout -bucket ${outWD}/tmp.$prefix.maskData.decon.nii
3dcalc -a ${outWD}/tmp.$prefix.maskData.decon.nii'[4]' -b ${outWD}/tmp.$prefix.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix $outWD/tmp.$prefix.maskData.R.nii
3dcalc -a ${outWD}/tmp.$prefix.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix ${outWD}/$prefix.Z.nii.gz
rm ${outWD}/tmp.${prefix}*
