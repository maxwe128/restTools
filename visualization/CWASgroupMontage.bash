#!/bin/bash


##Assumes you want partially inflated
######CWASgroupConnectMont.bash
ttest=$1 ###output of 3dttest++ for group comparison of seed
seed=$2
seedHemi=$3
spec=$4
prefix=$5
npb=23
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

suma -niml -npb $npb -spec $spec &
sleep 10
DriveSuma -npb $npb -com surf_cont -switch_surf std.141.lh.smoothwm.SS400.asc
DriveSuma -npb $npb -com viewer_cont -key F3 -com viewer_cont -key F4 -com viewer_cont -key F5 -com viewer_cont -key F9
DriveSuma -npb $npb -com surf_cont -load_dset $ttest
###Make Group1 Connectivity###
DriveSuma -npb $npb -com surf_cont -I_sb 6 \
	-com surf_cont -I_range .5 \
	-com surf_cont -T_sb 6 \
	-com surf_cont -T_val .3 \
	-com surf_cont -Clst -1 50 \
	-com surf_cont -UseClst y
DriveSuma -npb $npb -com surf_cont -load_dset $seed
DriveSuma -npb $npb -com surf_cont -1_only n #allow datasets to be viewed together
DriveSuma -npb $npb -com surf_cont -switch_cmap green_monochrome #green seems to be the best color to make seeds stand out
DriveSuma -npb $npb -com surf_cont -switch_dset $ttest
if [[ $seedHemi == "lh" ]];then
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewMedial.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key ] \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp1.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp2.png
	DriveSuma -npb $npb -com viewer_cont -key ]
elif [[ $seedHemi == "rh" ]];then
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp1.png
		DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewMedial.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key [ \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp2.png
	DriveSuma -npb $npb -com viewer_cont -key [
else
	echo "bad seedHemi input needs to be lh or rh"
fi
####Make group Diff left hemi
DriveSuma -npb $npb -com surf_cont -UseClst n
DriveSuma -npb $npb -com surf_cont -load_dset $ttest
DriveSuma -npb $npb -com surf_cont -switch_cmap Spectrum:red_to_blue+gap
DriveSuma -npb $npb -com surf_cont -I_sb 0 \
	-com surf_cont -T_sb 1 \
	-com surf_cont -T_val 2.81 \
	-com surf_cont -Clst -1 50 \
	-com surf_cont -UseClst y
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewMedial.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key ] \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp3.png
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp4.png
DriveSuma -npb $npb -com viewer_cont -key ]
DriveSuma -npb $npb -com surf_cont -UseClst n

###Make Group2 Connectivity
DriveSuma -npb $npb -com surf_cont -load_dset $ttest
DriveSuma -npb $npb -com surf_cont -I_sb 12 \
	-com surf_cont -I_range .5 \
	-com surf_cont -T_sb 12 \
	-com surf_cont -T_val .3 \
	-com surf_cont -Clst -1 50 \
	-com surf_cont -UseClst y
DriveSuma -npb $npb -com surf_cont -load_dset $seed
DriveSuma -npb $npb -com surf_cont -1_only n #allow datasets to be viewed together
DriveSuma -npb $npb -com surf_cont -switch_cmap green_monochrome #green seems to be the best color to make seeds stand out
DriveSuma -npb $npb -com surf_cont -switch_dset $ttest
if [[ $seedHemi == "lh" ]];then
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewMedial.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key ] \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp5.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp6.png
	DriveSuma -npb $npb -com viewer_cont -key ]
elif [[ $seedHemi == "rh" ]];then
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp5.png
		DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewMedial.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key [ \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp6.png
	DriveSuma -npb $npb -com viewer_cont -key [
else
	echo "bad seedHemi input needs to be lh or rh"
fi
####Make group Diff Right hemi
DriveSuma -npb $npb -com surf_cont -UseClst n
DriveSuma -npb $npb -com surf_cont -load_dset $ttest
DriveSuma -npb $npb -com surf_cont -switch_cmap Spectrum:red_to_blue+gap
DriveSuma -npb $npb -com surf_cont -I_sb 0 \
	-com surf_cont -T_sb 1 \
	-com surf_cont -T_val 2.81 \
	-com surf_cont -Clst -1 50 \
	-com surf_cont -UseClst y
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewLateral.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp7.png
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/partInfViewMedial.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp8.png

imcat -prefix $prefix -matrix 4 2 tmp*.png
convert $prefix.ppm $prefix.png
rm tmp* $prefix.ppm
DriveSuma -npb $npb -com kill_suma

