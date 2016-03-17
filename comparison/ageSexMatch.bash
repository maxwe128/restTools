#!/bin/bash

##################################ageSexMatch.bash##############################
####################### Authored by Max Elliott 3/14/2016 ####################

####Description####
#helper for making matched groups, given a prep dir and a sub, this script finds all heathies who are within 2 years of age and the same gender as sub and outputs those names to std out.
#in future make this just find best matched sub

prepDir=$1
sub=$2 

helix=$(echo $prepDir | cut -d "/" -f2) #check if you are on helix or biowulf

if [[ ${helix} == "helix" ]];then
	linkPointer="helix"
else
	linkPointer="biowulf"
fi
subAge=$(grep scanAge ${prepDir}/${sub}/info.rest1_$linkPointer.txt | cut -d "=" -f2 | cut -c1-4)
subSex=$(grep sex ${prepDir}/${sub}/info.${sub}_$linkPointer.txt | cut -d "=" -f2 | awk '{print tolower($0)}' | cut -c1)
cd ${prepDir}
for p in $(ls -d *);do
	pAge=$(grep scanAge ${prepDir}/${p}/info.rest1_$linkPointer.txt | cut -d "=" -f2 | cut -c1-4)
	pSex=$(grep sex ${prepDir}/${p}/info.${p}_$linkPointer.txt | cut -d "=" -f2 | awk '{print tolower($0)}' | cut -c1)
	ageCheck=$(echo "sqrt(($subAge-$pAge)^2) < 2" | bc)
	pDiag=$(grep Diagnoses ${prepDir}/${p}/info.${p}_$linkPointer.txt | cut -d "=" -f2 | awk '{print tolower($0)}')
	if [[ $ageCheck == "1" ]] && [[ $pSex == $subSex ]];then
		if [[ $pDiag == "null" ]] || [[ $pDiag == "normal" ]];then			
			echo $p $pAge $pSex $pDiag
		fi
	fi
done
