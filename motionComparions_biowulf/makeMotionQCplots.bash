#!/bin/bash

###Steps
#get maskaves of data with swarm, put files in one place. At the same time for each subject make carpet plot. wait for that swarm command to end then make QC-RSFC plot

##Dependencies
#/data/elliottml/rest10M/scripts/getMaskAve.bash, R, being on biowulf2,

###Args
dataList=$1 # all of the process functional datasets that you want to make plots (1 will be output for QC-rsfsc plot along with 1 for each subject for there carpetPlot)
outDir=$2 #Where you want all plots to be placed, directory will be made if it doesnt already exist
prefix=$3 #name to be appended to all files
prepUber=$4
tmpFiles=$5
####Args needed if prepUber = F
subList=$6 #names of subjects in same order of dataList, will be used to name individual carpetPlots
subFD=$7 #average FD measurement to be used as motion summary for each individual. Has to be in same ofder as dataList


cd $outDir
module load R

scriptsDir="/data/elliottml/rest10M/scripts"
cwd=$(pwd)
date=$(date "+%Y-%m-%d_%H:%M:%S")
timeID=${prefix}_$date

if [[ $prepUber == T ]];then
	##make FD file
	rawDataList=$(echo $outDir/dataList_RAW.txt)
	ls $outDir/tmp/* > maskAveList.txt
	art=$(head -n1 $dataList | cut -d "." -f4-5| cut -d "_" -f1) ## Should either be AF or A follow by a number indicating art was run
	if [[ $art != AF ]];then
		for i in $(cat $dataList);do
			echo "USING CENSORED MOTION PARAMS TO CALC QC-RSFC CORRELATION!!! MAKE SURE YOU WANT THIS"
			dir=$(echo $i | cut -d "/" -f1-7)
			sub=$(echo $i | cut -d "/" -f6)
			grep ${sub}_${prefix}_maskAve maskAveList.txt >> maskAveListOrdered.txt
			cat ${dir}/meanFD_cens.txt >> meanFD_list.txt
			ls ${dir}/FD_both_cens.1D >> FD_list.txt
		done
		###For comparing the raw less processed dataset to the fully preprocessed dataset
		for i in $(cat $rawDataList);do
			#echo "USING CENSORED MOTION PARAMS TO CALC QC-RSFC CORRELATION!!! MAKE SURE YOU WANT THIS"
			dir=$(echo $i | cut -d "/" -f1-7)
			sub=$(echo $i | cut -d "/" -f6)
			grep ${sub}_RAW_${prefix}_maskAve maskAveList.txt >> maskAveListOrdered_RAW.txt
			cat ${dir}/meanFD.txt >> meanFD_RAW_list.txt
			ls ${dir}/FD_both.1D >> FD_RAW_list.txt
		done
	else
		for i in $(cat $dataList);do
			dir=$(echo $i | cut -d "/" -f1-7)
			sub=$(echo $i | cut -d "/" -f6)
			grep ${sub}_${prefix}_maskAve maskAveList.txt >> maskAveListOrdered.txt
			cat ${dir}/meanFD.txt >> meanFD_list.txt
			ls ${dir}/FD_both.1D >> FD_list.txt
		done
	fi
	####Think about passing scriptsDir as an arg to R calls so that someone could download these scripts and have everything run independently
	echo "call Rscript ${scriptsDir}/run_maskAves2carpet.R maskAveListOrdered.txt FD_list.txt ${outDir}/carpet_${timeID}"
	Rscript ${scriptsDir}/run_maskAves2carpet.R maskAveListOrdered.txt FD_list.txt ${outDir}/carpet_${timeID}
	echo "call Rscript ${scriptsDir}/run_maskAves2QCRSFC.R maskAveListOrdered.txt meanFD_list.txt ${outDir}/QC_RSFC_${timeID}.png"
	Rscript ${scriptsDir}/run_maskAves2QCRSFC.R maskAveListOrdered.txt meanFD_list.txt ${outDir}/QC_RSFC_${timeID}.png
	echo "call Rscript ${scriptsDir}/run_maskAves2carpet.R maskAveListOrdered_RAW.txt FD_RAW_list.txt ${outDir}/carpet_RAW_${timeID}"
	Rscript ${scriptsDir}/run_maskAves2carpet.R maskAveListOrdered_RAW.txt FD_RAW_list.txt ${outDir}/carpet_RAW_${timeID}
	echo "call Rscript ${scriptsDir}/run_maskAves2QCRSFC.R maskAveListOrdered_RAW.txt meanFD_RAW_list.txt ${outDir}/QC_RSFC_RAW_${timeID}.png"
	Rscript ${scriptsDir}/run_maskAves2QCRSFC.R maskAveListOrdered_RAW.txt meanFD_RAW_list.txt ${outDir}/QC_RSFC_RAW_${timeID}.png
	if [[ $tmpFiles == F ]];then
		rm -r tmp
		rm tmp*
	fi
	
else ####NOT ready, time crunch is forcing me to ignore the option that people did not use my preprocessing scripts. Work on Later!!!!!!!!!!!!!!!
	echo "NOT ready, time crunch is forcing me to ignore the option that people did not use my preprocessing scripts. if you are seeing this 
		and input the right args, talk to Max about getting this up and running
		"

	#if [[ $(cat $dataList | wc -l) != $(cat $subList | wc -l) || $(cat $dataList | wc -l) != $(cat $subFD | wc -l) ]];then
	#	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! unequal lengths of dataList and subList!!!!!!!!!!!!!!!!!!!!!"
	#else
	#	mkdir -p $outDir
	#	cd $outDir
	#	mkdir tmp
	#	cd tmp
	#	paste -d "," $dataList $subList > 


fi
#could set this up to either assume preprocess structure that preprocess_Uber creates or requires all information about subjects to be input. This should save work
