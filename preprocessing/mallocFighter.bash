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
timeID=$(date "+%Y-%m-%d_%H:%M:%S")
jobID=$(swarm -f $swarmFile -g 14 -t 4 --partition nimh --time 24:00:00 --logdir LOGS ##-noht  ##This may help solve malloc issue)
cwd=$(pwd)
###Run malloc fighter on LOGs that have been written to ./LOGS/preProcess_Uber.$i.$ID
#Check if jobs are running, check for malloc until there are no jobs left. If malloc, kill job, send command to new swarm file, rerun swarm with malloc fighter for new swarm jobID
numJobs=$(sjobs | grep $jobID | wc -l)
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
while [ ${numJobs} -gt 0 ];do
	mallocList=""
	for i in $(cat $swarmFile | cut -d " " -f5);do 
		checkMal=$(grep malloc ./LOGS/preProcess_Uber.${i}* | wc -w)
		if [[ $checkMal -gt 0 ]];then
			list=$(echo $list $i)
		fi
	done
	malLen=$(echo $mallocList | wc -w)
	if [[ $malLen -gt 0 ]];then
		for i in $(echo $mallocList);do
			jobNum=$(grep -n $i $swarmFile)
			badJob=$(echo "$jobNum - 1" | bc)
			scancel ${jobID}_${badJob}
			newTimeID=$(date "+%Y-%m-%d_%H:%M:%S")
			grep -n $i $swarmFile >> $cwd/swarm.preprocess_Uber_$newTimeID
		done
		#call command that you need to create that does the same thing you just did, but calls itself recursively so that it recylcels mallocs until they are done
		#takes a swarm file in and runs the swarm until it is done, while constructing a swarm file of mallocs, then calls itself
			
	fi
	
	#Use recursion to rerun malloc errors that emerged in this instance of calling mallocFighter
	bash ${scriptsDir}/mallocFighter.bash ${cwd}/swarm.preprocess_Uber_$newTimeID
	numJobs=$(sjobs | grep $jobID | wc -l)
done


