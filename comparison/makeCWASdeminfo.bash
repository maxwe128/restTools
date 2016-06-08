#!/bin/bash

##################################makeCWASdemInfo.bash##############################
####################### Authored by Max Elliott 3/29/16 ####################

####Description####
#Takes in subject list and prepDir and grabs potentially relavant Dem info for CWAS
#based on preprocess_Uber output

#Depends on preprocess_Uber and PREP dir needs to be hardcoded at this point if there is more than one
subList=$1
prepDir=$2

cd $prepDir
echo "Subj,Sex,Age,FD"
for i in $(cat $subList);do
	sex=$(grep sex ${i}/info.${i}* | cut -d "=" -f2 | cut -c1 | awk '{ print toupper($0) }')
	age=$(grep scanAge ${i}/info.rest1_local.txt | cut -d "=" -f2 | cut -c1-6)
	fd=$(cat ${i}/PREP.A.5_3_CT_M6_WT*/meanFD_cens.txt)
	echo "$i,$sex,$age,$fd"
done
