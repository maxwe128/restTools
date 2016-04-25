#!/bin/bash

##################################seedGroupDiff.bash##############################
####################### Authored by Max Elliott 3/11/2016 ####################

####Description####
#Made to assume your pipeline of preprocess_Uber.bash was run and from that grabs relevant information to efficently find needed information and create covariates to run 3dttest++

group1SubList=$1
group2SubList=$2
exampleData=$3 #should be the full path to a dataset, from assumptions will be made to find prep dir, sub dirs and files from all subjects in first 2 args
outDir=$4 #needs to be full path
covCodes=$5 # format is age.sex.motionFD, where each is a T or F, for example if you want just age and sex covariates you would input T.T.F
seedMask=$6
grayMask=$7
prefix=$8
tempFiles=$9 # T or F do you want to keep tmp files
maskSelector=${10}

if [[ $maskSelector == "" ]];then
	maskSelector=1
fi
prefix=$prefix.$maskSelector
####Parse example data for important info
data=$(echo $exampleData | rev| cut -d "/" -f1 | rev)
prepDir=$(echo $exampleData | rev| cut -d "/" -f2 | rev)
baseDir=$(echo $exampleData | rev| cut -d "/" -f4- | rev)
#all data will be in the form of $baseDir/$sub/$prepDir/$data


echo "#!/bin/bash" > $outDir/$prefix.$covCodes.ttestCommand.bash
echo "3dttest++ -setA Group1 \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
for sub in $(cat $group1SubList);do
	echo "extracting values for $sub"
	#${baseDir}/${sub}/${prepDir}
	subData=${baseDir}/${sub}/${prepDir}/$data
	if [[ ! -f ${outDir}/Zfiles/$prefix.$sub.maskConnData.Z.nii ]];then
		echo "mkdir -p $outDir/Zfiles;mkdir -p $outDir/tmp.$prefix;cd $outDir/tmp.${prefix};3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $subData > tmp.$prefix.$sub.maskData.1D;3dDeconvolve -quiet -input $subData -polort -1 -num_stimts 1 -stim_file 1 tmp.$prefix.$sub.maskData.1D -stim_label 1 maskData -tout -rout -bucket tmp.$prefix.$sub.maskData.decon.nii;3dcalc -a tmp.$prefix.$sub.maskData.decon.nii'[4]' -b tmp.$prefix.$sub.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix tmp.$prefix.$sub.maskData.R.nii;3dcalc -a tmp.$prefix.$sub.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix $prefix.$sub.maskConnData.Z.nii;mv $prefix.$sub.maskConnData.Z.nii ${outDir}/Zfiles/" >> $outDir/swarm.$prefix
	else
		echo "values previously extracted for $sub"
	fi
	echo -e "\t$sub $outDir/Zfiles/$prefix.$sub.maskConnData.Z.nii \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash	
done
echo -e "\t-labelA Group1 \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
echo -e "\t-setB Group2 \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash	
for sub in $(cat $group2SubList);do
	echo "extracting values for $sub"
	#${baseDir}/${sub}/${prepDir}
	subData=${baseDir}/${sub}/${prepDir}/$data
	if [[ ! -f ${outDir}/Zfiles/$prefix.$sub.maskConnData.Z.nii ]];then
		echo "mkdir -p $outDir/Zfiles;mkdir -p $outDir/tmp.$prefix;cd $outDir/tmp.$prefix;3dmaskave -quiet -mrange $maskSelector $maskSelector -mask $seedMask $subData > tmp.$prefix.$sub.maskData.1D;3dDeconvolve -quiet -input $subData -polort -1 -num_stimts 1 -stim_file 1 tmp.$prefix.$sub.maskData.1D -stim_label 1 maskData -tout -rout -bucket tmp.$prefix.$sub.maskData.decon.nii;3dcalc -a tmp.$prefix.$sub.maskData.decon.nii'[4]' -b tmp.$prefix.$sub.maskData.decon.nii'[2]' -expr 'ispositive(b)*sqrt(a)-isnegative(b)*sqrt(a)' -prefix tmp.$prefix.$sub.maskData.R.nii;3dcalc -a tmp.$prefix.$sub.maskData.R.nii -expr 'log((1+a)/(1-a))/2' -prefix $prefix.$sub.maskConnData.Z.nii;mv $prefix.$sub.maskConnData.Z.nii ${outDir}/Zfiles/" >> $outDir/swarm.$prefix
	else
		echo "values previously extracted for $sub"
	fi
	echo -e "\t$sub $outDir/Zfiles/$prefix.$sub.maskConnData.Z.nii \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash	
done
echo -e "\t-labelB Group2 \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
echo -e "\t-center same \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
echo -e "\t-mask $grayMask \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
echo -e "\t-toz \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
echo -e "\t-prefix $prefix.$covCodes.ttest.nii \\" >> $outDir/$prefix.$covCodes.ttestCommand.bash
cd $outDir

###STill need to make covariate file, start here when working on this
#make covariate file with each of the requested coviarates
age=$(echo $covCodes | cut -d "." -f1 | awk '{print toupper($0)}')
sex=$(echo $covCodes | cut -d "." -f2 | awk '{print toupper($0)}')
motion=$(echo $covCodes | cut -d "." -f3 | awk '{print toupper($0)}')

if [[ $age == "T" ]] || [[ $sex == "T" ]] || [[ $motion == "T" ]];then
	#construct covariate file
	mkdir -p $outDir/tmp.$prefix
	echo "Subj" >> $outDir/tmp.${prefix}/firstColumn.subs.covFile.txt
	helix=$(echo $baseDir | cut -d "/" -f2) #check if you are on helix or biowulf
	if [[ $helix == "helix" ]];then
		linkPointer="local"
	else
		linkPointer="bwulf"
	fi
	for sub in $(cat $group1SubList $group2SubList);do
		#make Subj column
		echo $sub | cut -c1-12 >> $outDir/tmp.${prefix}/firstColumn.subs.covFile.txt
	done 
	#use if statements to add the rest of the covariate columns
	if [[ $age == "T" ]];then
		echo "Age" >> $outDir/tmp.${prefix}/column.age.covFile.txt
		for sub in $(cat $group1SubList $group2SubList);do
			subAge=$(grep scanAge ${baseDir}/${sub}/info.rest1_${linkPointer}.txt | cut -d "=" -f2 | cut -c1-4)
			echo $subAge >> $outDir/tmp.${prefix}/column.age.covFile.txt
		done
		
	fi
	if [[ $sex == "T" ]];then
		echo "Sex" >> $outDir/tmp.${prefix}/column.sex.covFile.txt
		for sub in $(cat $group1SubList $group2SubList);do
			subSex=$(grep "sex=" ${baseDir}/${sub}/info.${sub}_${linkPointer}.txt | cut -d "=" -f2 | awk '{print tolower($0)}' | cut -c1)
			if [[ $subSex == "m" ]];then
				subSexNum=1
			elif [[ $subSex == "f" ]];then
				subSexNum=2
			else
				echo "inaccurate sex input for $sub in this file: ${baseDir}/${sub}/info.${sub}_${linkPointer}.txt, fix this issue and restart"
				exit
			fi
			echo $subSexNum >> $outDir/tmp.${prefix}/column.sex.covFile.txt
		done
		
	fi
	if [[ $motion == "T" ]];then
		echo "Motion" >> $outDir/tmp.${prefix}/column.motion.covFile.txt
		echo "using Censored motion FD measurement, if this isnt what you want then rewrite this script"
		for sub in $(cat $group1SubList $group2SubList);do
			subMotion=$(cat ${baseDir}/${sub}/${prepDir}/meanFD_cens.txt)
			echo $subMotion >> $outDir/tmp.${prefix}/column.motion.covFile.txt
		done
		
	fi
	paste -d " " $outDir/tmp.${prefix}/firstColumn.subs.covFile.txt $outDir/tmp.${prefix}/column.*.covFile.txt > $outDir/$prefix.covFile.txt
	echo -e "\t-covariates $outDir/$prefix.covFile.txt" >> $outDir/$prefix.$covCodes.ttestCommand.bash
else
	echo "no covariates requested"
fi
#run swarm command then wait for it to finish before running 3dttest++
echo "swarming Zscore calculation for each subject; after this is done 3dttest will be run"
jobID=$(swarm -f $outDir/swarm.$prefix --partition nimh --time 1:00:00 --logdir ${outDir}/LOGS)

if [[ $tempFiles == F ]];then
	cd $outDir
	rm -r tmp.${prefix}
fi
echo "starting 3dttest++, double check all $prefix files to make sure this script is running 3dttest++ how you would wish"
sbatch --dependency=afterany:$jobID --partition nimh $prefix.$covCodes.ttestCommand.bash
