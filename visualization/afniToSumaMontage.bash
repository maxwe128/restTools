#!/bin/bash
func=$1
anat=$2 #can be same file as above
npb=19 #can change if you have a lot of afnis open
tvalue=$3
mesh=$4 # can be pial, inflated, sphere or white
surf=$5
Fsb=$6 #subbrick for func data
Tsb=$7 #subbrick that you want to threshold on
surfOlay=$8 #Has to be Right hemisphere of surface. typically the seed for a group difference map. Should either be F if you don't want this or the name of the dataset.
prefix=$9

if [[ $# < 9 ]];then
	echo "
	Not enough arguments passed need at least
	1)func
	2)anat
	3)tvalue
	4)mesh(pial,inflated,sphere or white)
	5)surface
	6)threshold subbrick
	"
else

afniAnat=$(echo $anat | rev | cut -d "/" -f1 | rev)
afniFunc=$(echo $func | rev | cut -d "/" -f1 | rev)
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

suma -niml -npb $npb -spec $surf -sv $anat &
afni -niml -yesplugouts -npb $npb $anat $func &
sleep 15
DriveSuma -npb $npb -com viewer_cont -key 't'
##load surf Olay if wanted, doing this first so volume tmap is underneath
sleep 5
#-com 'SET_FUNC_VISIBLE +'
if [[ $surfOlay != "F" ]];then
	DriveSuma -npb $npb -com surf_cont -load_dset $surfOlay
	DriveSuma -npb $npb -com surf_cont -1_only n #allow datasets to be viewed together
	DriveSuma -npb $npb -com surf_cont -switch_cmap green_monochrome #green seems to be the best color to make seeds stand out
fi
plugout_drive -npb $npb -com "SWITCH_UNDERLAY $afniAnat" -com "SWITCH_OVERLAY $afniFunc" -com 'SET_THRESHOLD .1 2' -com 'SET_PBAR_NUMBER 12' -com "SET_SUBBRICKS -1 $Fsb $Tsb" -com "SET_THRESHNEW A $tvalue" -quit
#sleep 10
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
plugout_drive -npb $npb -com "QUIT" -quit
DriveSuma -npb $npb -com kill_suma
sleep 2
fi
