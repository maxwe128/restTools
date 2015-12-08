#!/bin/bash

##allows 3dmaskAve and 3dDeconvolve to be swarmed then run_highVlowMotion tuns 3dttest++ and handles covariates

###Args
functionalData=$1
outDir=$2
prefix=$3
prepUber=$4
tmpFiles=$5
getNull=$6
module load R
if [[ $# < 5 ]];then
	echo "
	Not enough arguments passed need at least
	1)functionalDataList
	2)outDir
	3)prefix
	4)tmpFiles
	5)prepUber
	"
else

scriptsDir="/data/elliottml/rest10M/scripts"
cwd=$(pwd)
date=$(date "+%Y-%m-%d_%H:%M:%S")
timeID=${prefix}_$date

mkdir -p $outDir
cd $outDir

if [[ $prepUber = T ]];then
	#####split into groups and run 3dttest++, then count significant voxels and place into a txt file, maybe add functionality to do this iteratively and get a null distribution of significantly different voxels, like satterthwaite and power
	for i in $(less $functionalData);do
		name=$(echo $i | cut -d "/" -f6)
		base=$(echo $i | cut -d "/" -f1-7)
		meanFD=$(cat $base/meanFD.txt)
		echo $meanFD >> tmp/meanFDlist.$prefix.txt
	done
	paste -d "," $functionalData tmp/meanFDlist.$prefix.txt > tmp/functionalAndMotionData_$prefix.csv
	Rscript ${scriptsDir}/splitHighLowMotionSubs.R tmp/functionalAndMotionData_$prefix.csv ${prefix}
	for i in $(cut -d "," -f1 ${prefix}_highMotionSubs.csv);do
		name=$(echo $i | cut -d "/" -f6)
		mv tmp/${name}_$prefix.PCC.Z.nii tmp/${name}_$prefix.high.PCC.Z.nii ##need to change if we use new seeds
	done
	for i in $(cut -d "," -f1 ${prefix}_lowMotionSubs.csv);do
		name=$(echo $i | cut -d "/" -f6)
		mv tmp/${name}_$prefix.PCC.Z.nii tmp/${name}_$prefix.low.PCC.Z.nii ##need to change if we use new seeds
	done
	3dttest++ -setA tmp/*_$prefix.high.PCC.Z.nii -setB tmp/*_$prefix.low.PCC.Z.nii  -labelA highMotion -labelB lowMotion -prefix highVlow.$prefix.ttest.nii
	3dttest++ -setA tmp/*_$prefix.*.PCC.Z.nii  -labelA all -prefix all.PCC.$prefix.ttest.nii
	3dcalc -a highVlow.$prefix.ttest.nii -expr 'ispositive(abs(a)-2.052)' -prefix tmp/threshHighVlow.$prefix.nii
	3dBrickStat tmp/threshHighVlow.$prefix.nii > numSigVox.txt
	if [[ tmpFiles == F ]];then
		rm -r tmp
	fi

else
	echo "have to use prepUber now, ask Max to make it more generalizeable if you want to use this functionality"

fi
fi
