#!/bin/bash

#####smoothSwarm.bash####

#speeds up smoothing by making an easy way to warm smooth. assumes files are .nii.gz and outputs to the same directory with smoothXXmm.nii.gz as new suffix to scan name

fileList=$1
fwhm=$2
mask=$3
date=$(date "+%Y-%m-%d_%H:%M:%S")

for i in $(cat ${fileList});do
	baseDir=$(echo $i | rev | cut -d "/" -f2- | rev)
	inFile=$(echo $i | rev | cut -d "/" -f1- | rev)
	outName=$(echo $i | sed "s/.nii.gz/_smooth${fwhm}mm.nii.gz/g")
	if [[ ! -f $outName ]];then
		echo "cd $baseDir;3dBlurToFWHM -input $inFile -FWHM $fwhm -prefix $outName -mask $mask" >> swarm.$date
	fi
done
swarm -f swarm.$date -t 4 -g 8 --partition=quick --logdir /data/elliottml/ANTSstructs/lists/swarm
