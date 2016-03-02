#!/bin/bash

##################################run_preprocess_Uber.bash##############################
####################### Authored by Max Elliott in its original form sometime in 2015 ####################

####Description####
#make swarm, run swarm through malloc fighter


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
	WarpAndSegment=$3 #either T or F,F assumes bulk section has been run, First time running this on a subject this should always be T
	ART=$4 #should be in form {integer indicating mm movement cutoff within TR}_{integer indicating sd of signal change cutoff}. Example) .25_3. Can also be F for no ART
	CompCorr=$5 #either T or F. Do you want CompCorr run on dataset
	motionReg=$6 #how many motion regressors do you want in preprocessing. See above for details
	smooth=$7 ##smoothing kernel, can be any integer
	numRest=$8 ##how many good rest scans do you have per subject
	surf=$9 ##Either T of F, Do you want Freesurfer and @Suma_Make_Spec_FS run on subject. Will check to see if it has already been run in the correct place of subs Tree
	warpTemp=${10} #this is the hardCoded name of the template files below, add another if the one you want isn't here
	tempFiles=${11}
	cwd=$(pwd)

	ID="A${ART}_C${CompCorr}_M${motionReg}"
	timeID=$(date "+%Y-%m-%d_%H:%M:%S")
	scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	#####Make Swarm####
	for i in $(less $subjList);do
		echo "cd $scriptsDir;bash ./preprocess_Uber.bash $wd $i $WarpAndSegment $ART $CompCorr $motionReg $smooth $numRest $surf $warpTemp $tempFiles &> ./LOGS/preProcess_Uber.$i.$ID" >> $cwd/swarm.preprocess_Uber_$timeID
	done
	####Run Swarm#####
	#now all swarm calls of preprocess_Uber are run through mallocFighter to avoid dumb mallocs
	bash ${scriptsDir}/mallocFighter.bash ${cwd}/swarm.preprocess_Uber_$timeID

	#Nothing below that is commented should be needed but keeping for now in case malloc fighter busts
	<<COMMENT
	jobID=$(swarm -f swarm.preprocess_Uber_$timeID -g 14 -t 4 --partition nimh --time 24:00:00 --logdir LOGS ##-noht  ##This may help solve malloc issue)

	###Run malloc fighter on LOGs that have been written to ./LOGS/preProcess_Uber.$i.$ID
	#Check if jobs are running, check for malloc until there are no jobs left. If malloc, kill job, send command to new swarm file, rerun swarm with malloc fighter for new swarm jobID
	numJobs=$(sjobs | grep $jobID | wc -l)
	while [ ${numJobs} -gt 0 ];do
		mallocList=""
		for i in $(cat swarm.preprocess_Uber_$timeID | cut -d " " -f5);do 
			checkMal=$(grep malloc ./LOGS/preProcess_Uber.${i}* | wc -w)
			if [[ $checkMal -gt 0 ]];then
				list=$(echo $list $i)
			fi
		done
		malLen=$(echo $mallocList | wc -w)
		if [[ $malLen -gt 0 ]];then
			for i in $(echo $mallocList);do
				jobNum=$(grep -n $i swarm.preprocess_Uber_$timeID)
				badJob=$(echo "$jobNum - 1" | bc)
				scancel ${jobID}_${badJob}
				newTimeID=$(date "+%Y-%m-%d_%H:%M:%S")
				grep -n $iswarm.preprocess_Uber_$timeID >> $cwd/swarm.preprocess_Uber_$newTimeID
			done
			#call command that you need to create that does the same thing you just did, but calls itself recursively so that it recylcels mallocs until they are done
			#takes a swarm file in and runs the swarm until it is done, while constructing a swarm file of mallocs, then calls itself
			
		fi
	
		#Use recursion to rerun malloc errors that emerged in this instance of calling mallocFighter
		bash ${scriptsDir}/mallocFighter.bash ${cwd}/swarm.preprocess_Uber_$newTimeID
		numJobs=$(sjobs | grep $jobID | wc -l)
	done
	COMMENT

fi

