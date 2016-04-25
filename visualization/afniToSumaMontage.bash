#!/bin/bash
justPic=$1
func=$2
anat=$3 #can be same file as above
npb=19 #can change if you have a lot of afnis open
tvalue=$4
clustThresh=$5
mesh=$6 # can be pial, inflated, sphere or white or smoothwm.SS400 if the makeParInfSpec.bash has been run Or partInf for 
surf=$7
Fsb=$8 #subbrick for func data
Tsb=$9 #subbrick that you want to threshold on
surfOlay=${10} #Has to be Right hemisphere of surface. typically the seed for a group difference map. Should either be F if you don't want this or the name of the dataset.
prefix=${11}

if [[ $# < 10 ]];then
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

if [[ $justPic == "F" ]];then
if [[ $clustThresh != "F" ]];then
	funcThresh=$(echo "${func}[$Tsb]")
	funcData=$(echo "${func}[$Fsb])")
	clustCommand=$(echo "8 -savemask tmp_ClustMaskFull.nii 1.01 $clustThresh $funcThresh")
	$clustCommand
	3dcalc -a tmp_ClustMaskFull.nii -b $funcData -expr 'ispositive(a)*b' -prefix tmp_VisMap.nii
	afni -niml -yesplugouts -npb $npb $anat tmp_VisMap.nii &
else
	afni -niml -yesplugouts -npb $npb $anat $func &
fi
suma -niml -npb $npb -spec $surf -sv $anat &
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
if [[ $clustThresh != "F" ]];then
	plugout_drive -npb $npb -com "SWITCH_UNDERLAY $afniAnat" -com "SWITCH_OVERLAY tmp_VisMap.nii" -com 'SET_THRESHOLD .1 2' -com 'SET_PBAR_NUMBER 12' -com "SET_SUBBRICKS -1 0 0" -com "SET_THRESHNEW A 0" -quit
else
	plugout_drive -npb $npb -com "SWITCH_UNDERLAY $afniAnat" -com "SWITCH_OVERLAY $afniFunc" -com 'SET_THRESHOLD .1 2' -com 'SET_PBAR_NUMBER 12' -com "SET_SUBBRICKS -1 $Fsb $Tsb" -com "SET_THRESHNEW A $tvalue" -quit
fi

#sleep 10
DriveSuma -npb $npb -com surf_cont -switch_surf lh.${mesh}
sleep 600
else
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewLateral.niml.vvs
DriveSuma -npb $npb -com viewer_cont -key F4 -com viewer_cont -key F5 -com viewer_cont -key F9

DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp1.png
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp2.png
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewDorsal.niml.vvs
if [[ $justPic == "F" ]];then
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+up -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right \
	-com viewer_cont -key r
else
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+up \
	-com viewer_cont -key r
fi
DriveSuma -npb $npb -com  recorder_cont -save_as tmp3.png
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewPosterior.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+up \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp4.png
if [[ $justPic == "F" ]];then
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewMedial.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key ] \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp5.png
DriveSuma -npb $npb  -com viewer_cont -key ] \
	-com viewer_cont -key [ \
	-com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp6.png
else
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewMedial.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp5.png
DriveSuma -npb $npb  -com viewer_cont -key [ \
	-com viewer_cont -key ] \
	-com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp6.png
DriveSuma -npb $npb  -com viewer_cont -key [ \
	-com viewer_cont -key ]
fi
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewVentral.niml.vvs
if [[ $justPic == "F" ]];then
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+down -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right -com viewer_cont -key ctrl+shift+right \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
else
	DriveSuma -npb $npb  -com viewer_cont -key ctrl+down \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
fi
DriveSuma -npb $npb -com  recorder_cont -save_as tmp7.png
DriveSuma -npb $npb -com viewer_cont -load_view ${scriptsDir}/${mesh}ViewAnterior.niml.vvs
DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+down \
	-com viewer_cont -key r
DriveSuma -npb $npb -com  recorder_cont -save_as tmp8.png

imcat -prefix $prefix -matrix 4 2 tmp*.png

convert $prefix.ppm $prefix.png
rm tmp* $prefix.ppm $prefix.tmp*
if [[ $justPic == "F" ]];then
	plugout_drive -npb $npb -com "QUIT" -quit
	DriveSuma -npb $npb -com kill_suma
sleep 2
fi
fi
fi
