#!/bin/bash

##################################SumaMontage.bash##############################
####################### Authored by Max Elliott 3/31/2016 ####################

####Description####
#whatever is currently loaded in SUMA is rotated to create a 4X2 matrix of images

npb=$1
prefix=$2
withAfni=$3 #T or false do you have afni connected to SUMA now. If you are connected with afni orientation is altered so different commands will take the correct pictures
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $withAfni == T ]];then
	DriveSuma -npb $npb -com surf_cont -switch_surf lh.${mesh}
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewLateral.niml.vvs
	DriveSuma -npb $npb -com viewer_cont -key F4 -com viewer_cont -key F5 -com viewer_cont -key F9

	DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp1.png
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp2.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewDorsal.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+up -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp3.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewPosterior.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+up \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp4.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewMedial.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key ] \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp5.png
	DriveSuma -npb $npb  -com viewer_cont -key ] \
		-com viewer_cont -key [ \
		-com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp6.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewVentral.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+down -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right \
		-com viewer_cont -key [ \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp7.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewAnterior.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+down \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp8.png

	imcat -prefix $prefix -matrix 4 2 tmp*.png

	convert $prefix.ppm $prefix.png
	rm tmp*.png $prefix.ppm
else
	DriveSuma -npb $npb -com surf_cont -switch_surf lh.${mesh}
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewLateral.niml.vvs
	DriveSuma -npb $npb -com viewer_cont -key F4 -com viewer_cont -key F5 -com viewer_cont -key F9

	DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp1.png
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp2.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewDorsal.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+up \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp3.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewPosterior.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+up \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp4.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewMedial.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
		-com viewer_cont -key [ \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp5.png
	DriveSuma -npb $npb  -com viewer_cont -key ] \
		-com viewer_cont -key [ \
		-com viewer_cont -key ctrl+left \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp6.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewVentral.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+down \
		-com viewer_cont -key ] \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp7.png
	DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/inflatedViewAnterior.niml.vvs
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+down \
		-com viewer_cont -key r
	DriveSuma -npb $npb -com  recorder_cont -save_as tmp8.png

	imcat -prefix $prefix -matrix 4 2 tmp*.png

	convert $prefix.ppm $prefix.png
	rm tmp*.png $prefix.ppm
fi
rm tmp*.png
