#!/bin/bash
data=$1
outDir=$2
prefix=$3
mask=$4

cd ${outDir}
3dresample -master $data -inset $mask -prefix tmp/$prefix.mask.resamp.nii

#if you change the seed below to other than PCC make sure to change naming in highVlowMotion.bash
3dmaskave -dball 2 51 27 6 -mask tmp/$prefix.mask.resamp.nii -q $data | tr '\n' ' ' > tmp/$prefix.PCCseedData.1D
###

3dDeconvolve -input $data -polort -1 -num_stimts 1 -stim_file 1 tmp/$prefix.PCCseedData.1D -stim_label 1 $prefix.PCC -tout -rout -bucket tmp/$prefix.PCC.Decon.nii.gz
3dcalc -a tmp/$prefix.PCC.Decon.nii.gz'[4]' -b tmp/$prefix.PCC.Decon.nii.gz'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix tmp/$prefix.PCC.R.nii
3dcalc -a tmp/$prefix.PCC.R.nii -expr 'log((1+a)/(1-a))/2' -prefix tmp/$prefix.PCC.Z.nii #put z-scores in 3dttest++
