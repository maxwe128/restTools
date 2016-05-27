#!/bin/bash

##################################findBestCwasSeeds.bash##############################
####################### Authored by Max Elliott 3/30/16 ####################

####Description####
#goal is to make spherical seeds from each cluster that represents the center of mass of the cluster while avoiding problems where the center of mass is on the edge of the cluster or entirely outside
#Takes in cwas output and give you a Xmm sphere seed for each clust at a given threshold that has all nonzero clustered values within the cluster.


###Args
pMap=$1
thresh=$2 #bonferonni corrected for WSTD is .999998 for 4mm voxels
clustSize=$3
restGM=$4 #used to provide voxel size for seed mask that will be used in seed FC script
seedSize=$5 #what size do you want your seeds to be
prefix=$6


#cluster the CWAS 1-pvals dataset based on thresh
3dclust -quiet -nosum -1dindex 0 -1tindex 0 -2thresh -$thresh $thresh -dxyz=1 1.01 $clustSize $pMap | tr -s ' ' |tr " " "," | cut -d "," -f3-5 > $prefix.tmp.clustTable
numClust=$(cat $prefix.tmp.clustTable | wc -l)

3dclust -1Dformat -nosum -1dindex 0 -1tindex 0 -2thresh -$thresh $thresh -dxyz=1 -savemask ${prefix}_ClustMaskFull.nii 1.01 $clustSize $pMap

for i in $(seq 1 $numClust);do
	#compute localStats to erode mask to just be voxels that are surrounded by XXmm of voxels that are in mask
	3dcalc -a ${prefix}_ClustMaskFull.nii -expr "equals(a,$i)" -prefix $prefix.tmp.FullClust${i}.nii
	3dLocalstat -nbhd "SPHERE($seedSize)" -stat sum -prefix $prefix.tmp.localSum${i}.nii $prefix.tmp.FullClust${i}.nii
	maxSum=$(3dmaskave -max -quiet -mask $prefix.tmp.FullClust${i}.nii $prefix.tmp.localSum${i}.nii) #finds the voxels that are most surrounded by other voxels in the cluster
	#grab coordinates of the best voxels, the grep syntax guarantees that you are in the right column
	3dmaskdump -mask $prefix.tmp.FullClust${i}.nii -noijk -xyz $prefix.tmp.localSum${i}.nii | grep "^[^,]* [^,]* [^,]* $maxSum" > $prefix.tmp.maxSumsClust${i}
	numPotSeeds=$(cat $prefix.tmp.maxSumsClust${i} | wc -l)
	if [[ $numPotSeeds == 0 ]];then
		echo "!!!!!!!!!!!!!!!!!!!!!Problem with seed $i in mask: no potential seeds!!! Cannot move forward with making seed!!!!!!!!!!!!!!!!!!!!"
	elif [[ $numPotSeeds == 1 ]];then
		#use the best seed for 
		seedXcoord=$(cat $prefix.tmp.maxSumsClust${i} | cut -d " " -f1)
		seedYcoord=$(cat $prefix.tmp.maxSumsClust${i} | cut -d " " -f2)
		seedZcoord=$(cat $prefix.tmp.maxSumsClust${i} | cut -d " " -f3)
	else
		#find the max seed that is closes to the center of mass
		while read vox;do
			xCoord=$(echo $vox | cut -d " " -f1)
			yCoord=$(echo $vox | cut -d " " -f2)
			zCoord=$(echo $vox | cut -d " " -f3)
			cmassX=$(sed "${i}q;d" $prefix.tmp.clustTable | cut -d "," -f1)
			cmassY=$(sed "${i}q;d" $prefix.tmp.clustTable | cut -d "," -f2)
			cmassZ=$(sed "${i}q;d" $prefix.tmp.clustTable | cut -d "," -f3)
			euc=$(echo "sqrt(($xCoord - $cmassX)^2 + ($yCoord - $cmassY)^2 + ($zCoord - $cmassZ)^2)" | bc) #euclidean distance between cmass and each voxel
			echo "$euc $vox" >> $prefix.tmp.eucDist$i
		done <  $prefix.tmp.maxSumsClust${i}
		bestDist=$(sort -n -k1 $prefix.tmp.eucDist$i | head -n1 | cut -d " " -f1)
		bestCoords=$(sort -n -k1 $prefix.tmp.eucDist$i | head -n1 | cut -d " " -f2-4)
		seedXcoord=$(sort -n -k1 $prefix.tmp.eucDist$i | head -n1 | cut -d " " -f2)
		seedYcoord=$(sort -n -k1 $prefix.tmp.eucDist$i | head -n1 | cut -d " " -f3)
		seedZcoord=$(sort -n -k1 $prefix.tmp.eucDist$i | head -n1 | cut -d " " -f4)
	fi
	echo "found best seed location for seed $i, making a $seedSize mm sphere at $seedXcoord,$seedYcoord,$seedZcoord" 
	echo "the best voxel had $maxSum voxels within sphere that are in the Sig Cluster and it is $bestDist mm away from Center of Mass"
	#make spherical seed based on coordinates
	#first 3dcalc formatting monkey business
	if [[ $(echo "$seedXcoord < 0" | bc -l) ]];then
		xbitTmp=$(echo "$seedXcoord*-1" | bc)
		xbit=$(echo "+$xbitTmp")
	else
		xbit=$(echo "-$seedXcoord")
	fi
	if [[ $(echo "$seedYcoord < 0" | bc -l) ]];then
		ybitTmp=$(echo "$seedYcoord*-1" | bc)
		ybit=$(echo "+$ybitTmp")
	else
		ybit=$(echo "-$seedYcoord")
	fi
	if [[ $(echo "$seedXcoord < 0" | bc -l) ]];then
		zbitTmp=$(echo "$seedZcoord*-1" | bc)
		zbit=$(echo "+$zbitTmp")
	else
		zbit=$(echo "-$seedZcoord")
	fi
	sqSeed=$(echo "$seedSize^2" | bc)
	#put all of the seeds together
	if [[ $i == 1 ]];then	
		3dcalc -a $restGM -expr "step(${sqSeed}-(x${xbit})*(x${xbit})-(y${ybit})*(y${ybit})-(z${zbit})*(z${zbit}))*$i" -prefix $prefix.tmp.seeds$i.nii
	else
		prevNum=$(echo "$i - 1" | bc)
		3dcalc -a $restGM -b $prefix.tmp.seeds$prevNum.nii -expr "(step(${sqSeed}-(x${xbit})*(x${xbit})-(y${ybit})*(y${ybit})-(z${zbit})*(z${zbit}))*$i)+b" -prefix $prefix.tmp.seeds$i.nii
	fi
done
3dcalc -a $prefix.tmp.seeds$i.nii -b $restGM -expr 'a*b' -prefix $prefix.seeds.nii
seedMaskMax=$(3dmaskave -max -quiet $prefix.seeds.nii)
if [[ $seedMaskMax -gt $i ]];then
	echo "!!!!!!!!!!!!Warning!!!!!!!!!!! you have overlapping seeds in $prefix.seeds.nii, make sure you do something about this otherwise you will have problems in seedGroupDiff.bash !!!!!!!!!!!!Warning!!!!!!!!!!!"
fi
#remove tmp files
rm $prefix.tmp.*
echo "seed Mask created, Next up run your groups of interest throught seedGroupDiff.bash in a for loop for every seed in this mask"
