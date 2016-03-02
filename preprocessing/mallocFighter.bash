#!/bin/bash

##################################mallocFighter.bash##############################
####################### Authored by Max Elliott 02/18/2016 ####################

####Description####
#This is meant to handle the pesky problem of malloc errors and their mysterious ways
#Assumes that it is called within run_preprocess_Uber.bash, runs a swarm file, check for mallocs and makes new swarm of mallocs, then recalls itself until no mallocs

###Args
#1) swarm file

swarmFile=$1

####Run Swarm#####
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
timeID=$(date "+%Y-%m-%d_%H:%M:%S")
jobID=$(swarm -f ${swarmFile} -g 14 -t 4 --partition nimh --time 24:00:00 --logdir ${scriptsDir}/LOGS)
cwd=$(pwd)
###Run malloc fighter on LOGs that have been written to ./LOGS/preProcess_Uber.$i.$ID
#Check if jobs are running, check for malloc until there are no jobs left. If malloc, kill job, send command to new swarm file, rerun swarm with malloc fighter for new swarm jobID
numJobs=$(sjobs | grep $jobID | wc -l)
while [ ${numJobs} -gt 0 ];do
	echo "###############################";echo "there are $numJobs biowulf jobs running within mallocFighter;Currently fighting with swarm job: $jobID"
	mallocList=""
	for i in $(cat $swarmFile | cut -d " " -f5);do 
		checkMal=$(grep malloc ${scriptsDir}/LOGS/preProcess_Uber.${i}* | wc -w)
		if [[ $checkMal -gt 0 ]];then
			mallocList=$(echo $mallocList $i)
			#if there is a malloc, clear Log so it doesnt keep getting picked up		
			echo "" > ${scriptsDir}/LOGS/preProcess_Uber.${i}*
			#remove prep dirs so the rerun can be clean, suceptible to script changes, check here for field references in cut if errors arise!!!!
			prepDir=$(grep $i $swarmFile | cut -d " " -f4)
			templateName=$(grep $i $swarmFile | cut -d " " -f13)
			art=$(grep $i $swarmFile | cut -d " " -f7)
			comp=$(grep $i $swarmFile | cut -d " " -f8)
			motReg=$(grep $i $swarmFile | cut -d " " -f9)
			blur=$(grep $i $swarmFile | cut -d " " -f10)
			volPrepDir=$(echo "${prepDir}/${i}/PREP.A${art}_C${comp}_M${motReg}_WT${templateName}")
			surfPrepDir=$(echo "${prepDir}/${i}/surf.PREP.A${art}_C${comp}_M${motReg}")
			##remove prep files that may be related to malloc issues so that they are made anew when reran
			if [[ -f ${volPrepDir}/concat_blurat${blur}mm_bpss_PREP.A${art}_C${comp}_M${motReg}_WT${templateName}.nii.gz ]];then
				rm -r $surfPrepDir
			else
				rm -r $volPrepDir
			fi
		fi
	done
	malLen=$(echo $mallocList | wc -w)
	if [[ $malLen -gt 0 ]];then
		for i in $(echo $mallocList);do
			jobNum=$(grep -n $i $swarmFile | cut -d ":" -f1)
			badJob=$(echo "$jobNum - 1" | bc)
			scancel ${jobID}_${badJob}
			grep -n $i $swarmFile | cut -d ":" -f2 >> ${cwd}/swarm.preprocess_Uber_$timeID
		done
		#call command that you need to create that does the same thing you just did, but calls itself recursively so that it recylcels mallocs until they are done
		#takes a swarm file in and runs the swarm until it is done, while constructing a swarm file of mallocs, then calls itself
		echo "malloc found, running mallocFighter recursively until mallocs are decimated!!!";echo "###############################"
		sleep 1m
	else
		echo "no mallocs yet, waiting 1 minute before checking again";echo "###############################"
		sleep 1m		
	fi
	
	#Use recursion to rerun malloc errors that emerged in this instance of calling mallocFighter
	numJobs=$(sjobs | grep $jobID | wc -l)
done

#once all the jobs are either killed because of malloc or finish, then rerun the mallocs with a recursive call. running this outside of while should clean things up and help with debugging
reSwarmLen=$(wc -l ${cwd}/swarm.preprocess_Uber_$timeID | cut -d " " -f1)

if [[ ${reSwarmLen} -gt 0 ]];then
	bash ${scriptsDir}/mallocFighter.bash ${cwd}/swarm.preprocess_Uber_$timeID
else
	echo "we escaped the malloc induced threat of infinite recursion, YAY!!!!"
fi




