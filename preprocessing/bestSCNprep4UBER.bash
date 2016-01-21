#!/bin/bash

##################################bestSCNprep4Uber.bash##############################
####################### Authored by Max Elliott 01/21/2016 ####################

####Description
#called within prep4Uber.bash to choose each participants best ${numRest} scans within each visit and then choose best visit.
#Does this by meanFD solely


subList=$1
numRest=$2
outDir=$3

for i in $(cat $subList);do
	
