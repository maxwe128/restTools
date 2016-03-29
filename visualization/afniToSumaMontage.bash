#!/bin/bash
func=$1
anat=$2 #can be same file as above
npb=19 #can change if you have a lot of afnis open
tvalue=$3
mesh=$4 # can be pial, inflated, sphere or white
surf=$5
Tsb=$6 #subbrick that you want to threshold on

if [[ $# < 5 ]];then
	echo "
	Not enough arguments passed need at least
	1)dataList
	2)outDir
	3)prefix
	4)prepUber
	5)tmpFiles
	"
else

afniAnat=$(echo $anat | rev | cut -d "/" -f1 | rev)
afniFunc=$(echo $func | rev | cut -d "/" -f1 | rev)
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ $mesh = inflated ]];then
	view=${scriptsDir}/inflatedView3.vvs
else
	view=${scriptsDir}/inflatedView2.vvs
fi

suma -niml -npb $npb -spec $surf -sv $anat &
afni -niml -yesplugouts -npb $npb $anat $func &
sleep 15
DriveSuma -npb $npb -com viewer_cont -key 't'
sleep 5
#-com 'SET_FUNC_VISIBLE +'
plugout_drive -npb $npb -com "SWITCH_UNDERLAY $afniAnat" -com "SWITCH_OVERLAY $afniFunc" -com 'SET_THRESHOLD .1 2' -com 'SET_PBAR_NUMBER 12' -com "SET_THRESHNEW A $tvalue"  -quit
DriveSuma -npb $npb -com surf_cont -switch_surf lh.${mesh}
DriveSuma -npb $npb -com viewer_cont -load_view $view

DriveSuma -npb $npb  -com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+up \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+up \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+right \
	-com viewer_cont -key ] \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ] \
	-com viewer_cont -key [ \
	-com viewer_cont -key ctrl+left \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+down \
	-com viewer_cont -key [ \
	-com viewer_cont -key r
DriveSuma -npb $npb  -com viewer_cont -key ctrl+shift+down \
	-com viewer_cont -key r
fi
