#!/bin/bash
image=$1
npb=$2
tvalue=$3
mesh=$4 # can be pial, inflated, sphere or white
surf=$5
prefix=$6

#surf=/home/gregorymd/suma_MNI_new/suma_MNI_N27/std.141.MNI_N27_both.spec
if [[ $mesh = inflated ]];then
	view=/x/wmn18/elliottml/sulcalDepth10M/scripts/inflatedView.niml.vvs
else
	view=/x/wmn18/elliottml/sulcalDepth10M/scripts/pialView5.niml.vvs
fi

suma -niml -npb $npb -spec $surf &

DriveSuma -npb $npb -com viewer_cont -load_view $view

DriveSuma -npb $npb -com viewer_cont -key F9
DriveSuma -npb $npb -com surf_cont -load_dset $image
DriveSuma -npb $npb -com surf_cont -T_sb 1
DriveSuma -npb $npb -com surf_cont -T_val $tvalue
DriveSuma -npb $npb -com surf_cont -I_sb 1
DriveSuma -npb $npb -com surf_cont -switch_cmap Spectrum:yellow_to_cyan #ROI_i32
DriveSuma -npb $npb -com surf_cont -I_range -10 10
DriveSuma -npb $npb -com viewer_cont '-key:v54R' j
DriveSuma -npb $npb -com surf_cont -I_range -16 16
DriveSuma -npb $npb -com surf_cont -switch_surf lh.$mesh

DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+up \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+up \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ] \
	-com viewer_cont -key [ \
	-com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+down \
	-com viewer_cont -key ] \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+down \
	-com viewer_cont -key r
#sleep 20
DriveSuma -com recorder_cont -save_as tmp.$prefix.png -save_range 0 7 -npb $npb
imcat -nx 4 -ny 2 -prefix $prefix tmp.$prefix*
rm tmp.$prefix*
DriveSuma -npb $npb -com kill_suma
