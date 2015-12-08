#!/bin/bash

data=$1 #Should one functional file to be maskAved
outDir=$2 #where and what name you want the output to go
prefix=$3
mask=$4

cd $outDir
3dcalc -a $mask -expr 'ispositive(a-.25)' -prefix tmp/gmMask.$prefix.nii
3dresample -master $data -inset tmp/gmMask.$prefix.nii -prefix tmp/$prefix.mask.resamp.nii
for i in $(cat /data/elliottml/rest10M/templates/Dosenbach_Science_160ROIs_Center);do ### replace with power ROIs, need to figure out why it didnt seems to work, might need dball
	cord=$(echo $i | sed 's/,/ /g')
	line=$(3dmaskave -nball ${cord} 8 -mask tmp/$prefix.mask.resamp.nii -q $data | tr '\n' ' ')
	echo $line  >> tmp/tmp_${prefix}_maskAve
done

