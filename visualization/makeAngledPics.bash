#!/bin/bash
#makeAngledPics
ttest=$1 ###output of 3dttest++ for group comparison of seed
hemi=$2
spec=$3
prefix=$4
npb=23
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

suma -niml -npb $npb -spec $spec &
sleep 10
DriveSuma -npb $npb -com surf_cont -switch_surf std.141.$hemi.smoothwm.SS400.asc
DriveSuma -npb $npb -com viewer_cont -key F3 -com viewer_cont -key F4 -com viewer_cont -key F5 -com viewer_cont -key F9
DriveSuma -npb $npb -com surf_cont -load_dset $ttest
DriveSuma -npb $npb -com surf_cont -switch_cmap Spectrum:red_to_blue+gap
DriveSuma -npb $npb -com surf_cont -I_sb 1 \
	-com surf_cont -I_range 5 \
	-com surf_cont -T_sb 1 \
	-com surf_cont -T_val 2 \
	-com surf_cont -Clst -1 100 \
	-com surf_cont -UseClst y
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as $prefix.Lateral.$hemi.png
convert $prefix.Lateral.$hemi.00000.png -transparent black $prefix.Lateral.$hemi.transparent.png

DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as $prefix.Medial.$hemi.png
convert $prefix.Medial.$hemi.00001.png -transparent black $prefix.Medial.$hemi.transparent.png

DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/angledPosterior$hemi.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as $prefix.angledPosterior.$hemi.png
convert $prefix.angledPosterior.$hemi.00002.png -transparent black $prefix.angledPosterior.$hemi.transparent.png

DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/angledAnterior$hemi.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as $prefix.angledAnterior.$hemi.png
convert $prefix.angledAnterior.$hemi.00003.png -transparent black $prefix.angledAnterior.$hemi.transparent.png
DriveSuma -npb $npb -com kill_suma
rm $prefix.*.$hemi.000*.png
