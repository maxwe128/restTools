#!/bin/bash

##################################run_preprocess_Uber.bash##############################
####################### Authored by Max Elliott in its original form sometime in 2015 ####################

####Description####
#make swarm, run swarm through malloc fighter


export OMP_NUM_THREADS=4
nargs=$#
if [[ $nargs -lt 7 ]];then
	echo "
	########Requirements###########
	1)Ants needs to be downloaded and in your path
	2)spm12sa needs to be downloaded and in your path
	3)Freesurfer needs to be downloaded and in your path
	######Call structure############

	preprocess_Uber.bash -w {working Directory} -l {subject list} -a {Art params} -c {CompCorr?} -m {motion params} -s {smoothing kernel} -n (numberRest} -f {surface?} -t {warpTemplate} -r {keep Temp files?}
	
	Example) run_preprocess_Uber.bash -a .5_3 -w /data/elliottml/3TC_rest/prep/ -l /data/elliottml/3TC_rest/lists/allRestSubs_052516 -c T -m 6 -s 6 -n 2 -f T -t n7.WSTDDUP.MNI
	##############Intro################
	This script automates the running of preprocess_Uber.bash so that you can easily preprocess large groups of people with different preprocessing params.
	It will make a swarm file, write it to the current directory and run the swarm file

	#options that can change: 
		-a :ART-can adjust censoring params mm and g structure "mm_global" (Required)
		-c :COMPcorr-T of F  (Required)
		-m :MOTION REGRESSORS-0, 6(typical),12(adds temproral derivative),18(adds quadratic) or 24(adds temporal derivative of quadratic)  (Optional, Defaults to 6)
		-s :BLURRING-FWHM kernel(can be any integer)  (Optional, Defaults to 6)
		-n :numberRest-typically 1 or 2 but depending on the dataset you may have many runs of rest you want to concat together (Required)
		-f :surface- T or F, do you want freesurfer and suma_make_Spec to be run on all subjects and rest data to be processed on surface as well as volume (Required)
		-t :warpTemplate- options are hard coded into script based on input to warpTemp. Check the preprocess_Uber.bash script to see what template suites your needs. If none do feel free to add in a hardcoded template using regMask, template, striptemplate and brainmask structure. Look at script for examples (Required)
		-e :extraRegressors- this is used if you want to regress out additional things from your data. Could be task design if you want to make pseudo-rest scans
		-r :-keepTempFiles?- T or F, typically answer is F, this will save space. but if you want to debug or see how intermediate files are made than use T (Optional, Defaults to F)
	####################################
	"
else
	###Set up argument defaults
	wd="" #begginning of tree, assumes that all subjects have their own folder within this dir
	subjList="" #Assumes that in subject folder is a file called anat.nii.gz, rest1.nii.gz and rest2.nii.gz, this is also where I keep FS and SUMA dirs
	ART="" #should be in form {integer indicating mm movement cutoff within TR}_{integer indicating sd of signal change cutoff}. Example) .25_3. Can also be F for no ART
	CompCorr="" #either T or F. Do you want CompCorr run on dataset
	motionReg=6 #how many motion regressors do you want in preprocessing. See above for details. Default is 6
	smooth=6 ##smoothing kernel, can be any integer, default is 6mm FWHM
	numRest="" ##how many good rest scans do you have per subject
	surf="" ##Either T of F, Do you want Freesurfer and @Suma_Make_Spec_FS run on subject. Will check to see if it has already been run in the correct place of subs Tree
	warpTemp="" #this is the hardCoded name of the template files below, add another if the one you want isn't here
	extraReg=""
	tempFiles=F # do you want to keep extra files, default is False and will delete temp files
	cwd=$(pwd)
	  while getopts "a:c:e:f:l:m:n:r:s:t:w:" OPT;do
	      case $OPT in
		  a) #ART parameters
	       		ART=$OPTARG
			echo "ART=$ART"
	       		;;
		  c) # CompCorr
	       		CompCorr=$OPTARG
			echo "CompCorr=$CompCorr"
			if [[ ${CompCorr} != "T" && ${CompCorr} != "F" ]];then
		   		echo " Error:  Argument -c (CompCorr) must be either T or F "
		   	exit
			fi
	       		;;
		  e) #extra regressors that you want added to the final 3dTproject command. This file needs to be the same number of rows as final concatenated scan TRs and will be added to allRegressors file as extra columns. This was originally created for adding task design to make pseudo-rest scans with task regressed out
	       		extraReg=$OPTARG
			echo "extraReg=$extraReg"
	       		;;
		  f) #Freesurfer + SUMA, do you want surface Run
	       		surf=$OPTARG
			echo "surf=$surf"
			if [[ ${surf} != "T" && ${surf} != "F" ]];then
		   		echo " Error:  Argument -f (Surface) must be either T or F "
		   		exit 
			fi
	       		;;
		  l) #List or subjList
	       		subjList=$OPTARG
			echo "subjList=$subjList"
	       		;;
		  m) #number of Motion Regressors
	       		motionReg=$OPTARG
			echo "motionReg=$motionReg"
	       		;;
		  n) #number of rest scans
	       		numRest=$OPTARG
			echo "numRest=$numRest"
	       		;;
		  r) #keep Temp Files? tempFiles
	       		tempFiles=$OPTARG
			echo "tempFiles=$tempFiles"
			if [[ ${tempFiles} != "T" && ${tempFiles} != "F" ]];then
		   		echo " Error:  Argument -r (tempFiles) must be either T or F "
		   		exit
			fi
	       		;;
		  s) #smoothing
	       		smooth=$OPTARG
			echo "smooth=$smooth"
	       		;;
		  t) # template to warp rest to
	       		warpTemp=$OPTARG
			echo "warpTemp=$warpTemp"
	       		;;
		  w) #working directory
	       		wd=$OPTARG
			echo "wd=$wd"
	       		;;
		  *) # getopts issues an error message
	       		echo "ERROR:  unrecognized option -$OPT $OPTARG"
	       		exit
	       		;;
	      esac
	  done
	ID="A${ART}_C${CompCorr}_M${motionReg}"
	timeID=$(date "+%Y-%m-%d_%H:%M:%S")
	scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	mkdir -p ${scriptsDir}/LOGS
	#####Make Swarm####
	for i in $(less $subjList);do
		#echo "cd $scriptsDir;bash ./preprocess_Uber.bash $wd $i $ART $CompCorr $motionReg $smooth $numRest $surf $warpTemp $extraReg $tempFile" > ${scriptsDir}/LOGS/preProcess_Uber.$i.$ID
		echo "cd $scriptsDir;bash ./preprocess_Uber.bash $wd $i $ART $CompCorr $motionReg $smooth $numRest $surf $warpTemp $extraReg $tempFiles &> ./LOGS/preProcess_Uber.$i.$ID.$warpTemp" >> $cwd/swarm.preprocess_Uber_$timeID
	done

	###Dont think I need mallocFigher anymore
	swarm -f $cwd/swarm.preprocess_Uber_$timeID -g 14 -t 4 --partition nimh,b1,norm --time 24:00:00 --logdir ${scriptsDir}/LOGS
	
	####Run Swarm#####
	#now all swarm calls of preprocess_Uber are run through mallocFighter to avoid dumb mallocs
	#bash ${scriptsDir}/mallocFighter.bash ${cwd}/swarm.preprocess_Uber_$timeID

	#Nothing below that is commented should be needed but keeping for now in case malloc fighter busts

fi

