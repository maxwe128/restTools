#!/bin/bash

##################################seedZmap_bwulf.bash##############################
####################### Authored by Max Elliott 5/27/2016 ####################

####Description####
#Follows the structure of seedGroupDiff_bwulf.bash without the 3dttest++. Originally written for cases where you want to use 3dMVM instead of 3dttest. 
#Output are Z maps for each seed for each subject to be used in follow up modeling or significance testing

subList=$1 #just list of names
exampleData=$2 #should be the full path to a dataset, from which assumptions will be made to find prep dir, sub dirs and files from all subjects in first 2 args
outDir=$3 #needs to be full path
seedMask=$4
grayMask=$5
prefix=$6
tempFiles=$7 # T or F do you want to keep tmp files
maskSelector=$8

if [[ $maskSelector == "" ]];then
	maskSelector=1
fi
prefix=$prefix.$maskSelector
####Parse example data for important info
data=$(echo $exampleData | rev| cut -d "/" -f1 | rev)
prepDir=$(echo $exampleData | rev| cut -d "/" -f2 | rev)
baseDir=$(echo $exampleData | rev| cut -d "/" -f4- | rev)
#all data will be in the form of $baseDir/$sub/$prepDir/$data

for sub in $(cat $subList);do
	echo "extracting values for $sub"
	#${baseDir}/${sub}/${prepDir}
	subData=${baseDir}/${sub}/${prepDir}/$data
	if [[ ! -f ${outDir}/Zfiles/$prefix.$sub.maskConnData.Z.nii ]];then
		echo "mkdir -p $outDir/Zfiles;mkdir -p $outDir/tmp.$prefix;cd $outDir/tmp.${prefix};3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $subData > tmp.$prefix.$sub.maskData.1D;3dDeconvolve -quiet -input $subData -polort -1 -num_stimts 1 -stim_file 1 tmp.$prefix.$sub.maskData.1D -stim_label 1 maskData -tout -rout -bucket tmp.$prefix.$sub.maskData.decon.nii;3dcalc -a tmp.$prefix.$sub.maskData.decon.nii'[4]' -b tmp.$prefix.$sub.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix tmp.$prefix.$sub.maskData.R.nii;3dcalc -a tmp.$prefix.$sub.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix $prefix.$sub.maskConnData.Z.nii;mv $prefix.$sub.maskConnData.Z.nii ${outDir}/Zfiles/" >> $outDir/swarm.$prefix
	else
		echo "values previously extracted for $sub"
	fi	
done
jobID=$(swarm -f $outDir/swarm.$prefix --partition=nimh,b1,norm --time 1:00:00 --logdir ${outDir}/LOGS)
echo "#!/bin/bash" > $outDir/$prefix.seedZmapCleanup.bash
echo "cd $outDir;rm -r tmp.${prefix} swarm.$prefix $outDir/$prefix.seedZmapCleanup.bash" >> $outDir/$prefix.seedZmapCleanup.bash
sbatch --dependency=afterany:$jobID --partition nimh $outDir/$prefix.seedZmapCleanup.bash
