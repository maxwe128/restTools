#!/bin/bash

##################################CheckForPreprocess_UberCompletion.bash##############################
####################### Authored by Max Elliott 02/23/2016 ####################

####Description
#given a prep directory, list everyone who is completed and everyone who had vol vs surf crash. Writes out 3 files

dir=$1
outDir=$2

date=$(date "+%m%d%Y")
cd $dir
for i in $(ls -d *);do
	if ls ${dir}/${i}/PREP.A*/concat_blur* 1> /dev/null 2>&1; then
		if ls ${dir}/${i}/surf.PREP.A*/std.30.${i}_lh* 1> /dev/null 2>&1; then
			echo $i >> ${outDir}/preprocessComplete.$date
		else
			echo $i >> ${outDir}/preprocessIncomplete_surf.$date
		fi
	else
		echo $i >> ${outDir}/preprocessIncomplete_vol.$date
	fi
done
