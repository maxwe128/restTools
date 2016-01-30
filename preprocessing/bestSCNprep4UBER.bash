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
	cd ${outDir}/${sub}/tmp
	for timePoint in $(ls -d ${outDir}/${sub}/tmp/restTimePoint*);do
		bestMean=999999999
		shortTime=$(echo $timePoint | rev | cut -d "/" -f1 | rev)
		##Make sortable file with rest motion info
		for scan in $(ls ${timePoint}/meanFD*);do
			mean=$(cat ${scan})
			echo "${scan},${mean}" >> ${timePoint}/meanFile_${shortTime}
		done
		#grab best $numRest per time point
		echo "1"
		sort --field-separator=',' --key=2 ${timePoint}/meanFile_${shortTime} | tail -n${numRest} > ${timePoint}/bestScans_${shortTime}
		echo "2"
		bestMean=$(cut -d "," -f2 ${timePoint}/bestScans_${shortTime} | awk '{s+=$1 }END{print s/NR}' RS="\n")
		echo "${shortTime},${bestMean}" >> ${outDir}/${sub}/${tmp}/timeMeans
	done
	echo "3"
	bestTimePoint=$(sort --field-separator="," --key=2 ${outDir}/${sub}/tmp/timeMeans | head -n1 | cut -d "," -f1)
	#look up best scans from best timePoint and move them along with the anat
	count=1
	for rest in $(cut -d "," -f1 ${outDir}/${sub}/tmp/${bestTimePoint}/bestScans_${bestTimePoint} | cut -d "." -f2-5);do
		mv ${bestTimePoint}/${rest}.nii.gz ${outDir}/${sub}/rest${count}.nii.gz
		mv ${bestTimePoint}/info.${rest}.txt ${outDir}/${sub}/info.rest${count}.txt
	done
	mv ${bestTimePoint}/anat.*.nii.gz ${outDir}/${sub}/anat.nii.gz
done
#rm -r {outDir}/${sub}/tmp
#after above is run you should have $numRest rest scans and best anat in each file


####Problem is with variable naming and referencing, should be an easy fix I am just beat. timeMeans is weird and you need to figure out what is supposed to be hear and where you want it.
