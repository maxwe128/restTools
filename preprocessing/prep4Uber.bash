#!/bin/bash

##################################prep4Uber.bash##############################
####################### Authored by Max Elliott 1/13/2016 ####################

####Description
#program to bridge between grabRestAndAnatFrom4Queries.bash and preprocess_Uber.bash

#run on biowulf, will speed up processing a lot. This will automatically make and submit the swarm file for you

#For each subject it will output links to the best 2 scans across all scans that have 
#QC of 3 or 4, however these 2 best scans must be within XX days of each other where XX is an input arg




#Args Required
#1)subject list
#2)number of Rest scans wanted for preprocess_Uber.bash (number concatenated together in the end)
#3)max number of days for 2 scans to be put together. Set the limit for scans to be concatenated together in preprocess_Uber.bash
#4)working directory, where raw data is now. Wherever grabRestandAnatFrom4Queries was run.
#5)output directory where preprocess Uber will be run, Should be same as WD input to preprocess_Uber. a directory will be made here for each subject


####Future Directions
#adapt for Patient processing by finding best patient scans and then finding healthy scans that match on age and sex
#adapt for longitudinal processing 

####Assumptions
#naming of files is the same as output from grabRestandAnatFrom4Queries.bash
#all subs have a folder in $wd with scans in that folder

#Input Args
subList=$1
numRest=$2
maxDaysApart=$3
wd=$4
outDir=$5

scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
mkdir -p $scriptsDir/LOGS
date=$(date "+%Y-%m-%d_%H:%M:%S")
log=${scriptsDir}/LOGS/prep4Uber_${date}.LOG

###Check Each subject for best XX scans and make Swarm for scans that need motion Info to decide.
cd $wd
for sub in $(cat $subList);do
	cd ${wd}/${sub}
	#check to see if this has already been run for sub
	if [[ -d ${outDir}/${sub} ]];then
		echo "!!!!!!!!!!!!!!already run for $sub, will not run again!!!!!!!!!!!!!!!!!!"
	else
		restScans=$(ls rest.*)
		mkdir ${outDir}/${sub}
		mkdir ${outDir}/${sub}/tmp
		ls -1 rest.* > ${outDir}/${sub}/tmp/restList #Use this for keeping track of rest scans
		##find sets of scans that are within $maxDaysApart
		numRestLeft=$(cat ${outDir}/${sub}/tmp/restList | wc -l)
		maxSecs=$(echo "${maxDaysApart}*24*60*60" | bc)
		matchCount=0
		while [ $numRestLeft -gt 1 ];do
			firstRest=$(head -n1 ${outDir}/${sub}/tmp/restList)
			firstDate=$(echo $firstRest | cut -d "." -f2)
			infoFile=$(echo "info.$firstRest" | sed 's/nii.gz/txt/g')
			qcCheck=$(grep "QC=" ${wd}/${sub}/${infoFile} | cut -d "=" -f2)
			matchCheck=0
			if [[ $qcCheck == 3 ]] || [[ $qcCheck == 4 ]] || [[ $qcCheck == $nothing ]];then ##Allows for the case where you didnt QC scans(might be dangerous)
				if [[$qcCheck == $nothing ]];then
					echo "WARNING: ${wd}/${sub}/$firstRest is not QCed, Assuming that it is okay for preprocessing. You might want to double check this. WARNING"
				fi
				#Loop through all of subjects scans to find sets that were collected close to each other				
				tail -n+2 ${outDir}/${sub}/tmp/restList > ${outDir}/${sub}/tmp/dateCheck
				for i in $(cat ${outDir}/${sub}/tmp/dateCheck);do
					
					scanDate=$(cut -f2 -d "." $i)
					meetsDaysCrit=$(echo "($(date --date="$scanDate" +%s) - $(date --date="$firstDate" +%s)) < $maxSecs " | bc)
					secDiff=$(echo "($(date --date="$scanDate" +%s) - $(date --date="$firstDate" +%s))" | bc)
					if [[ $secDiff -lt 0 ]];then
						echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
						echo "The dates aren't sorting the way Max hoped, script needs to be change to not assume a positive difference between scan dates"
						echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
						exit
					elif [[ $meetsDaysCrit == 1 ]];then
						sed -i '/'$i'/d' ${outDir}/${sub}/tmp/restList #remove scan from restList because you know it has a match
						ln -s ${wd}/${sub}/${i} ${outDir}/${sub}/tmp/
						matchCheck=$(echo "${matchCheck} + 1" | bc) #check to see if any of the other rests are close enough the first Rest
					fi
				done
				rm ${outDir}/${sub}/tmp/dateCheck
				if [[ $matchCheck -gt 0 ]];then # are there any matches for the current first rest
					matchCount=$(echo "${matchCount} + 1" | bc)
					mkdir ${outDir}/${sub}/tmp/restTimePoint${matchCount}
					mv ${outDir}/${sub}/tmp/rest.* ${outDir}/${sub}/tmp/restTimePoint${matchCount}/
					restDate=$(ls ${outDir}/${sub}/tmp/restTimePoint${matchCount}/rest.* | head -n1 | cut -d "." -f2)
					#grab anatomical that goes with that rest Time point if there is one and it has a good QC, if not complain
					# Anat part could be removed for Williams if you want to used unbiased surfaces and not QC
					if ls ${wd}/${sub}/anat* 1> /dev/null 2>&1; then
						for anat in $(ls ${wd}/${sub}/anat*);do
							anatInfo=$(echo "info.$anat" | sed 's/nii.gz/txt/g')
							anatqcCheck=$(grep "QC=" ${wd}/${sub}/${anatInfo} | cut -d "=" -f2)
							if [[ $anatqcCheck == 3 ]] || [[ $anatqcCheck == 4 ]];then
								anatDate=$(echo $anat | cut -d "," -f2)
								anatSecDiff=$(echo "sqrt(($(date --date="$restDate" +%s) - $(date --date="$anatDate" +%s))^2)" | bc) #gets abs val of time diff for comparison
								echo "${anat},${anatSecDiff}" >>  ${outDir}/${sub}/tmp/restTimePoint${matchCount}/anatTimeDiffs
							fi
						done
						bestAnat=$(sort --field-separator=',' --key=2 ${outDir}/${sub}/tmp/restTimePoint${matchCount}/anatTimeDiffs | head -n1 | cut -d "," -f1) #anat closes to rest
						ln -s ${wd}/${sub}/$bestAnat ${outDir}/${sub}/tmp/restTimePoint${matchCount}/
						rm ${outDir}/${sub}/tmp/restTimePoint${matchCount}/anatTimeDiffs
					else
						echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
						echo "No anatomical scan for $sub cannot move forward because preprocess_Uber will not work"
						echo "removing subject directory and moving on"
						echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
						rm -r ${outDir}/${sub}
					fi
				fi
			fi
			sed -i '/'$firstRest'/d' ${outDir}/${sub}/tmp/restList #remove the current first rest scan from the sublist so that you can check the next one in the next run through
			numRestLeft=$(cat ${outDir}/${sub}/tmp/restList | wc -l)
		done
		# if there were potentially good scans, check if there is more than one potential time point with enough scans. If so set up for preprocess_Uber or if there is more than one 
		# potential scan, then compare 
		numRestFound1=$(ls ${outDir}/${sub}/tmp/restTimePoint1/rest.* | wc -l) #check if you have the right number of rest at time point one so no swarm is needed
		if [[ $matchCount == 0 ]];then
			echo "WARNING: no good rest data found for $sub WARNING"
		elif [[ $matchCount == 1 ]] && [[ $numRestFound1 == $numRest ]];then
			anat=$(ls ${outDir}/${sub}/tmp/restTimePoint${matchCount}/anat.* | rev | cut -d "/" -f1 | rev)
			anatInfo=$(echo "info.$anat" | sed 's/nii.gz/txt/g')
			mv  ${outDir}/${sub}/tmp/restTimePoint${matchCount}/anat.* ${outDir}/${sub}/anat.nii.gz
			ln -s ${wd}/${sub}/${anatInfo} ${outDir}/${sub}/info.anat.txt
		else
			###Set up swarm file to get motion params for every rest
			for rest2VR in $(ls ${outDir}/${sub}/tmp/restTimePoint*/rest.*);do
				restPrefix=$(echo $rest2VR | rev |cut -d "/" -f1 | rev | cut -d "." -f-4)
				restTimeDir=$(echo $rest2VR | rev |cut -d "/" -f2- | rev)
				echo "cd $restTimeDir;3dcalc -a ${rest2VR}'[0]' -expr a -prefix tmp_${restPrefix}_0.nii.gz;3dcalc -a ${rest2VR}'[5..$]]' -expr a -prefix tmp_${restPrefix}_cut;3dvolreg -tshift 0 -prefix ${restPrefix}_vr.nii.gz  -1Dfile ${restPrefix}_vr_motion.1D tmp_${restPrefix}_cut+orig.;1d_tool.py -infile ${restPrefix}_vr_motion.1D -derivative -write ${restPrefix}_vr_motion_deriv.1D;1d_tool.py -infile ${restPrefix}_vr_motion_deriv.1D -collapse_cols euclidean_norm -write FD${restPrefix}.1D;awk '{s+=$1}END{print s/NR}' RS="\n" FD${restPrefix}.1D >meanFD${restPrefix}.txt" >> ${scriptsDir}/swarm.getMeanMotion ##may want to put this somewhere else or make sure to delete or add to .gitignore
			done
		fi

	fi
done	
### Run swarm if there is a swarm file, if not somthing is weird. Then run the script to grab best rest from each time point and select best time point after swarm is done



