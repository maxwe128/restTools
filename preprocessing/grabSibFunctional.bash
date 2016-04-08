#!/bin/bash

##################################grabSibFunctional.bash##############################
####################### Authored by Max Elliott 3/28/16 ####################

####Description####
#Based on SibStudy queries that were made with MDG, This script grabs all Sib Study functional data, untars and organizes it.
##The initial reason for doing this is so that all ib study functional can be concatenated and used as "pseudo-rest" to have a large
##FC-MRI dataset for projects like parcellation, genetic seed comparisons and Schizophrenia projects.

# You will need a version for functional and a version for MPRAGES
#this will be run in a swarm. Takes in one line of sibStudy query and outputs one nifti, organization and record keeping

########################################################################################
######################Run this command to use this script from Biowulf###########
#while read line;do sub=$(echo $line | cut -d "," -f1); num=$(grep $sub /data/elliottml/sibStudy_fun/lists/sibstudy_hasAllTasks.csv | wc -l);if [[ $num -gt 0 ]];then echo "grabSibFunctional.bash $line" >> swarm."NAME";fi;done< <(tail -n+2 "YOUR SIBSTUDY CSV");swarm -f swarm."NAME" --gres=lscratch:10
############################################################################################
#################################################################################################

line=$1
task=$2 #FL_8,NB_02,PEAR_ENC_NA,FMT_MM,PEAR_RET_NA,DSST,MPRG use one of these so the script know what to untar
finalDir=/data/elliottml/sibStudy_fun/data/
wd=/lscratch/$SLURM_JOB_ID/   #acess scratch that you have to allocate in swarm call
#####sort the line
sub=$(echo $line | cut -d "," -f1)
scan_id=$(echo $line | cut -d "," -f3)
sess_id=$(echo $line | cut -d "," -f4)
mis=$(echo $line | cut -d "," -f6)
seq=$(echo $line | cut -d "," -f7)
qc=$(echo $line | cut -d "," -f8)
cond=$(echo $line | cut -d "," -f9)
scanner=$(echo $line | cut -d "," -f10)
dob=$(echo $line | cut -d "," -f11)
sex=$(echo $line | cut -d "," -f12)
tarbPath=$(echo $line | cut -d "," -f14 | cut -d "/" -f3-) #gets it ready for rsync
fid=$(echo $line | cut -d "," -f15)
mis2=$(echo $line | cut -d "," -f16)
fid2=$(echo $line | cut -d "," -f17)
dob2=$(echo $line | cut -d "," -f19)
sex2=$(echo $line | cut -d "," -f20)
notes=$(echo $line | cut -d "," -f22)
notes2=$(echo $line | cut -d "," -f23)

mkdir -p $finalDir/$sub
#######Double check redundancies to make sure they work out otherwise complain to list directory
#sex,dob,mis,family can all be check against each other

if [[ $sex == $sex2 ]];then
	fSex=$(echo $sex)
elif [[ $sex == "" ]];then
	fSex=$(echo $sex2)
elif [[ $sex2 == "" ]];then
	fSex=$(echo $sex)
else
	fSex=$(echo "CONFLICT BETWEEN SOURCES")
	echo date >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
	echo "PROBLEMS WITH SEX in::::::: $line" >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
fi

if [[ $dob == $dob2 ]];then
	fdob=$(echo $dob)
elif [[ $dob == "" ]];then
	fdob=$(echo $dob2)
elif [[ $dob2 == "" ]];then
	fdob=$(echo $dob)
else
	fdob=$(echo "CONFLICT BETWEEN SOURCES")
	echo date >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
	echo "PROBLEMS WITH DOB in::::::: $line" >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
fi

if [[ $mis == $mis2 ]];then
	fmis=$(echo $mis)
elif [[ $mis == "" ]];then
	fmis=$(echo $mis2)
elif [[ $mis2 == "" ]];then
	fmis=$(echo $mis)
else
	fmis=$(echo "CONFLICT BETWEEN SOURCES")
	echo date >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
	echo "PROBLEMS WITH mis in::::::: $line" >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
fi

if [[ $fid == $fid2 ]];then
	ffid=$(echo $fid)
elif [[ $fid == "" ]];then
	ffid=$(echo $fid2)
elif [[ $fid2 == "" ]];then
	ffid=$(echo $fid)
else
	ffid=$(echo "CONFLICT BETWEEN SOURCES")
	echo date >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
	echo "PROBLEMS WITH fid in::::::: $line" >> /data/elliottml/sibStudy_fun/lists/grabSibFunctional.COMPLAINTS
fi

###################Write out info file###########################
scanDate=$(echo $tarbPath | rev | cut -d "/" -f1 | rev | cut -d "_" -f2 | cut -d "." -f1)
DOB=$(echo $fdob | sed "s/'//g" | sed 's/-//g')
scanAge=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l | cut -c1-6)
scanName=$(echo "$task.$scanDate.$sess_id.$seq")

echo "sub=$sub" >> $finalDir/$sub/info.$scanName.txt
echo "scanAge=$scanAge" >> $finalDir/$sub/info.$scanName.txt
echo "DOB=$DOB" >> $finalDir/$sub/info.$scanName.txt
echo "scanDate=$scanDate" >> $finalDir/$sub/info.$scanName.txt
echo "sub=$sub" >> $finalDir/$sub/info.$scanName.txt
echo "sex=$fSex" >> $finalDir/$sub/info.$scanName.txt
echo "mis=$fmis" >> $finalDir/$sub/info.$scanName.txt
echo "fid=$ffid" >> $finalDir/$sub/info.$scanName.txt
echo "tarb=$tarbPath" >> $finalDir/$sub/info.$scanName.txt
echo "scan_id=$scan_id" >> $finalDir/$sub/info.$scanName.txt
echo "sess_id=$sess_id" >> $finalDir/$sub/info.$scanName.txt
echo "seq=$seq" >> $finalDir/$sub/info.$scanName.txt
echo "qc=$qc" >> $finalDir/$sub/info.$scanName.txt
echo "cond=$cond" >> $finalDir/$sub/info.$scanName.txt
echo "scanner=$scanner" >> $finalDir/$sub/info.$scanName.txt
echo "sub=$sub" >> $finalDir/$sub/info.$scanName.txt
echo "sub=$sub" >> $finalDir/$sub/info.$scanName.txt
echo "notes=$notes" >> $finalDir/$sub/info.$scanName.txt
echo "notes2=$notes2" >> $finalDir/$sub/info.$scanName.txt

######Grab Data
tarFile=$(echo $tarbPath | rev | cut -d "/" -f1 | rev)
rsync apollo.nimh.nih.gov::${tarbPath} $wd/
cd $wd
tar -zxf $tarFile --wildcards --no-anchored "$task*"
cd */*/*
mri_convert --in_type dicom --out_type nii ${task}-00001.dcm $scanName.nii
gzip $scanName.nii
numTRs=$(3dinfo -nv $scanName.nii.gz)
echo "numTRs=$numTRs" >> $finalDir/$sub/info.$scanName.txt
mv $scanName.nii.gz $finalDir/$sub/
