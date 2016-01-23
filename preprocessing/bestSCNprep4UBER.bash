#!/bin/bash

##################################bestSCNprep4Uber.bash##############################
####################### Authored by Max Elliott 01/21/2016 ####################

####Description
#called within prep4Uber.bash to choose each participants best ${numRest} scans within each visit and then choose best visit.
#Does this by meanFD solely


#Edit prep4Uber to allow a specification that looks for averaged anat that is closest in age to best rest
#May want to play with calling from helix so that you can look in wmg dirs after swarming 
#might be easiest to just grab the best anats and after call a separate script from helix that looks for an averaged anat
#and clears the current anat if the averaged anat is present and close enough in age

subList=$1
numRest=$2
outDir=$3

for sub in $(cat $subList);do
	cd ${outDir}/${sub}
	######Psuedo Code because I am on a train to New Haven
	#probably need to write scan name and FD to each file and use cut and sort to keep info together so you can mv the right file
	#for timePoint in ls -d timePoints
		#cat meanFDsPerTimePoint | sort | tail -n${numRest} > fileInTimePoint #grab best x scans 
	#done
	#Awk average command all the timepoint files | sort | tail -n1 to find timePoint with best motion
	#mv $best X scans in best TimePoint to outDir, mv info files
	#rm -r tmp subDirs
done

	
#after above is run you should have $numRest rest scans and best anat in each file