#!/bin/bash

##################################groupDiff2BoxPlot.bash##############################
####################### Authored by Max Elliott 4/07/16 ####################

####Description####
#goal is to see how individual subjects contribute to group connectivity differences by making box plots for each of the major clusters of a difference map
#right now this will extract the value from the peak group difference voxel from each clust in each subject


###Args
statMap=$1
group1Info=$2 #in the form of groupLabel./path/to/list/of/DataFiles
group2Info=$3 #in the form of groupLabel./path/to/list/of/DataFiles
thresh=$4 #bonferonni corrected for WSTD is .999998
clustSize=$5
prefix=$6

scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#cluster the CWAS 1-pvals dataset based on thresh
3dclust -quiet -1Dformat -nosum -1dindex 0 -1tindex 1 -2thresh -$thresh $thresh -dxyz=1 1.01 $clustSize $statMap | tr -s ' ' | cut -d " " -f15-17 > $prefix.tmp.peakTable
numClust=$(cat $prefix.tmp.peakTable | wc -l)

group1Label=$(echo $group1Info | cut -d "." -f1)
group2Label=$(echo $group2Info | cut -d "." -f1)
group1Data=$(echo $group1Info | cut -d "." -f2-)
group2Data=$(echo $group2Info | cut -d "." -f2-)
if [[ $numClust -eq 0 ]];then
	echo "Your thresh and clust parameters are too stringent, there are no clusters to extract from"
	exit
else
	echo "extracting values from $numClust Clusters"
	echo "group1=$group1Label data=$group1Data"
	echo "group2=$group2Label data=$group2Data"
fi
3dclust -quiet -1Dformat -nosum -1dindex 0 -1tindex 1 -2thresh -$thresh $thresh -dxyz=1 -savemask ${prefix}.tmp.ClustMapFull.nii 1.01 $clustSize $statMap

3dcalc -a ${prefix}.tmp.ClustMapFull.nii -b $statMap -expr '(a*b)/a' -prefix ${prefix}.ClustMapFull.nii #get clusters with all values intact


##make files for ggplot to handle and turn into a plot
while read peakVox;do
	peakName=$(whereami $peakVox | grep Focus | head -n2 | tr -s ' ' | tail -n1 | cut -d " " -f4- | tr ' ' '_')
	peakCoords=$(echo $peakVox | tr ' ' ',') #for R labeling purposes
	peakTitle=$(echo $peakVox | tr ' ' '_')
	echo "extracting values from $peakName"
	echo "Group,BetaVal" >> "${prefix}.tmp.${peakName}.${peakTitle}.data.csv"
	for subData in $(cat $group1Data);do
		voxData=$(3dmaskave -xbox $peakVox -quiet $subData)
		echo "$group1Label,$voxData" >> "${prefix}.tmp.${peakName}.${peakTitle}.data.csv"
		
	done
	for subData in $(cat $group2Data);do
		voxData=$(3dmaskave -xbox $peakVox -quiet $subData)
		echo "$group2Label,$voxData" >> "${prefix}.tmp.${peakName}.${peakTitle}.data.csv"
	done
	###Run Rscript to read in above data and make plots with the correct labels
		Rscript $scriptsDir/extractedToPlot.R ${prefix}.tmp.${peakName}.${peakTitle}.data.csv "$peakName ($peakCoords)" $prefix.$peakName.$peakTitle.BoxPlot.png
done < $prefix.tmp.peakTable

rm $prefix.tmp.*
