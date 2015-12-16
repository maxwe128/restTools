#!/bin/bash
###make swarm, run swarm

export OMP_NUM_THREADS=4
if [[ $# < 10 ]];then
	echo "
	######Call structure############

	preprocess_Uber.bash {working Directory} {subject list} {warp and segment?} {Art params} {CompCorr?} {motion params} {smoothing kernel} {number Rest per Person} {run Surface pipeline} {keep Temp files?}
	
	Example) run_preprocess_Uber.bash ../data_V1/ 10MInclusiveList F .25_3 F 24 10 2 F
	##############Intro################
	This script automates the running of preprocess_Uber.bash so that you can easily preprocess large groups of people with different preprocessing params.
	It will make a swarm file, write it to the current directory and run the swarm file

	#options that can change: WarpAndSegment- this is made to save space. After it has been ran once on a subject the subject will then have the important files in their parent directory. Then all other preprocessing schemes will rely on these files and you no longer need matlab licences and things move much faster,ART-can adjust censoring params mm and g, COMPcorr-True or False, MOTION REGRESSORS-0, 6(typical),12(adds temproral derivative),18(adds quadratic) or 24(adds temporal derivative of quadratic), BLURRING-FWHM kernel(can be any integer)
	#
	#
	#####input
	"
else
	wd=$1 #begginning of tree, assumes that all subjects have their own folder within this dir
	subjList=$2 #Assumes that in subject folder is a file called anat.nii.gz, rest1.nii.gz and rest2.nii.gz, this is also where I keep FS and SUMA dirs
	WarpAndSegment=$3 #either T or F, this is for the case where you are modifying or adding to preprocessing that has already been run, assumes bulk section below has been run
	ART=$4 #should be in form {integer indicating mm movement cutoff within TR}_{integer indicating sd of signal change cutoff}. Example) .25_3. Can also be F for no ART
	CompCorr=$5 #either T or F. Do you want CompCorr run of dataset
	motionReg=$6 #how many motion regressors do you want in preprocessing. See above for details
	smooth=$7 ##smoothing kernel, can be any integer
	numRest=$8
	surf=$9
	tempFiles=$10
	cwd=$(pwd)

	ID="A${ART}_C${CompCorr}_M${motionReg}"
	timeID=$(date "+%Y-%m-%d_%H:%M:%S")
	#####Make Swarm####
	for i in $(less $subjList);do
		echo "cd /data/elliottml/rest10M/scripts; ./preprocess_Uber.bash $wd $i $WarpAndSegment $ART $CompCorr $motionReg $smooth $numRest $tempFiles &> ./LOGS/preProcess_Uber.$i.$ID" >> $cwd/swarm.preprocess_Uber_$timeID
	done
	####Run Swarm#####
	if [[ $WarpAndSegment == T ]];then
		swarm -f swarm.preprocess_Uber_$timeID -g 14 -t 4 --partition nimh --sbatch "--license=matlab" --singleout
	else
		swarm -f swarm.preprocess_Uber_$timeID -g 14 -t 4 --partition nimh --singleout
	fi
fi
