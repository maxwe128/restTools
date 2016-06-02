#!/bin/bash

##################################groupDiff2BoxPlot.bash##############################
####################### Authored by Max Elliott 4/07/16 ####################

####Description####
#goal is to see how individual subjects contribute to group connectivity differences by making box plots for each of the major clusters of a difference map
#right now this will extract the value from the peak group difference voxel from each clust in each subject and plot them in one plot for each unique group label


###Args
statMap=$1
dataTable=$2 ### csv without titles in the form: /path/to/subData,groupLabel
thresh=$3 #bonferonni corrected for WSTD is .999998
clustSize=$4
prefix=$5

scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#cluster the CWAS 1-pvals dataset based on thresh
3dclust -quiet -1Dformat -nosum -1dindex 0 -1tindex 0 -2thresh -$thresh $thresh -dxyz=1 1.01 $clustSize $statMap | tr -s ' ' | cut -d " " -f15-17 > $prefix.tmp.peakTable
numClust=$(cat $prefix.tmp.peakTable | wc -l)

if [[ $numClust -eq 0 ]];then
	echo "Your thresh and clust parameters are too stringent, there are no clusters to extract from"
	exit
else
	cat $dataTable | cut -d "," -f2 | uniq > $prefix.tmp.groupLabels
	echo "extracting values from $numClust Clusters"
	echo "group Labels to be Plotted:"
	cat $prefix.tmp.groupLabels
fi
3dclust -quiet -1Dformat -nosum -1dindex 0 -1tindex 0 -2thresh -$thresh $thresh -dxyz=1 -savemask ${prefix}.tmp.ClustMapFull.nii 1.01 $clustSize $statMap

3dcalc -a ${prefix}.tmp.ClustMapFull.nii -b $statMap -expr '(a*b)/a' -prefix ${prefix}.ClustMapFull.nii #get clusters with all values intact


##make files for ggplot to handle and turn into a plot
while read peakVox;do
	peakName=$(whereami $peakVox | grep Focus | head -n2 | tr -s ' ' | tail -n1 | cut -d " " -f4- | tr ' ' '_')
	peakCoords=$(echo $peakVox | tr ' ' ',') #for R labeling purposes
	peakTitle=$(echo $peakVox | tr ' ' '_')
	echo "extracting values from $peakName"
	echo "Group,BetaVal" >> "${prefix}.tmp.peak.${peakName}.${peakTitle}.data.csv"
	for group in $(cat $prefix.tmp.groupLabels);do
		for subData in $(grep $group $dataTable | cut -d "," -f1);do
			voxData=$(3dmaskave -xbox $peakVox -quiet $subData)
			echo "$group,$voxData" >> "${prefix}.tmp.peak.${peakName}.${peakTitle}.data.csv"
		
		done
	done
	###Run Rscript to read in above data and make plots with the correct labels
	Rscript $scriptsDir/extractedToPlot.R ${prefix}.tmp.peak.${peakName}.${peakTitle}.data.csv "$peakName ($peakCoords)" $prefix.peak.$peakName.$peakTitle.BoxPlot.png
done < $prefix.tmp.peakTable
for i in $(seq 1 $numClust);do
	peakVox=$(sed "${i}q;d" $prefix.tmp.peakTable)
	peakName=$(whereami $peakVox | grep Focus | head -n2 | tr -s ' ' | tail -n1 | cut -d " " -f4- | tr ' ' '_')
	peakCoords=$(echo $peakVox | tr ' ' ',') #for R labeling purposes
	peakTitle=$(echo $peakVox | tr ' ' '_')
	echo "extracting values from $peakName"
	echo "Group,BetaVal" >> "${prefix}.tmp.avg.${peakName}.${peakTitle}.data.csv"
	for group in $(cat $prefix.tmp.groupLabels);do
		for subData in $(grep $group $dataTable | cut -d "," -f1);do
			voxData=$(3dmaskave -mask ${prefix}.tmp.ClustMapFull.nii -mrange $i $i -quiet $subData)
			echo "$group,$voxData" >> "${prefix}.tmp.avg.${peakName}.${peakTitle}.data.csv"
		
		done
	done
	###Run Rscript to read in above data and make plots with the correct labels
	Rscript $scriptsDir/extractedToPlot.R ${prefix}.tmp.avg.${peakName}.${peakTitle}.data.csv "$peakName ($peakCoords)" $prefix.avg.$peakName.$peakTitle.BoxPlot.png
done
rm $prefix.tmp.*
