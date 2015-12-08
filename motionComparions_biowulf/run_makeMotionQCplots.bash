#!/bin/bash

###Steps
#get maskaves of data with swarm, put files in one place. At the same time for each subject make carpet plot. wait for that swarm command to end then make QC-RSFC plot

##Dependencies
#/data/elliottml/rest10M/scripts/getMaskAve.bash, R, being on biowulf2,

###To generalize and make useable by other, use cut from right instead of left because that will be constant if they used your preprocessing,
#also add option that they didnt use your preprocessing and then they have to give you a lot more dataLists

###Args
dataList=$1 # all of the processed functional datasets that you want to make plots (1 will be output for QC-rsfsc plot along with 1 for each subject for their carpetPlot)
outDir=$2 #Where you want all plots to be placed, directory will be made if it doesnt already exist
prefix=$3 #name to be appended to all files
prepUber=$4
tmpFiles=$5

####Args needed if prepUber = F
subList=$6 #names of subjects in same order of dataList, will be used to name individual carpetPlots
subFD=$7 #average FD measurement to be used as motion summary for each individual. Has to be in same ofder as dataList

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

scriptsDir="/data/elliottml/rest10M/scripts"
cwd=$(pwd)
date=$(date "+%Y-%m-%d_%H:%M:%S")
timeID=${prefix}_$date

mkdir -p $outDir
cd $outDir
mkdir tmp
sed 's/concat_/concat_RAW_/g' $dataList > $outDir/dataList_RAW.txt
if [[ $prepUber = T ]];then
	for i in $(less $dataList);do
		name=$(echo $i | cut -d "/" -f6)
		base=$(echo $i | cut -d "/" -f1-6)
		rawBase=$(echo $i | cut -d "_" -f1-6)
		mask=$(ls $base/c1*)
		end=$(echo $i | cut -d "_" -f7-)
		#3dcalc -a $mask -expr 'ispositive(a-.25)' -prefix tmp/gmMask.$name.nii 
		echo "cd $scriptsDir; ./getMaskAve.bash $i $outDir ${name}_$prefix $mask &> ./LOGS/getMaskAve.${name}.${timeID}" >> ./swarm.getMaskAve_$timeID
		echo "cd $scriptsDir; ./getMaskAve.bash ${rawBase}_RAW_${end} $outDir ${name}_RAW_${prefix} $mask &> ./LOGS/getMaskAve.${name}.RAW.${timeID}" >> ./swarm.getMaskAve_$timeID #for comparison without preprocessing
	done
		

	###Start swarm and sbatch and deal with dependencies
	echo "#!/bin/bash" > sbatchCall.makeMotionQCplots.${timeID}
	echo "#!/bin/bash" > sbatchCall.makeMotionQCplots.${timeID}_RAW
	echo "${scriptsDir}/makeMotionQCplots.bash $dataList $outDir $prefix $prepUber $tmpFiles " >> sbatchCall.makeMotionQCplots.${timeID}
	jobID=$(swarm -f swarm.getMaskAve_$timeID --singleout --partition nimh)
	echo "waiting for maskAve swarm to finish, then will make plots" 
	sbatch --dependency=afterany:$jobID --partition nimh sbatchCall.makeMotionQCplots.${timeID}
else
	echo "have to use prepUber now, ask Max to make it more generalizeable if you want to use this functionality"
fi
fi
