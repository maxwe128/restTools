#!/bin/bash



#########grabSubMEMPRAGEfromQuery

subAnat=$1
wd=/lscratch/$SLURM_JOB_ID/ 
date=$(date +"%Y%d%m")

anatTarb=$(echo $subAnat)
scanDatetmp=$(echo $anatTarb | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
scanMonthDay=$(echo ${scanDatetmp:0:4})
scanYear=$(echo ${scanDatetmp:4:2})
scanDateCheck=$(echo "20$scanYear$scanMonthDay")
scanExamCheck=$(echo $anatTarb | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
obscureName=$(echo $anatTarb | cut -d "." -f1 | rev | cut -d "/" -f1 | rev)
DOB=$(grep DOB /data/elliottml/3TC_rest/data/$obscureName/info.$obscureName.txt | cut -d "=" -f2)
scanAge=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l)

echo $subAnat
echo $obscureName
echo $anatTarb
echo "/data/elliottml/3TC_rest/data/$obscureName/info.$obscureName.txt"




if ls $wd/data/$obscureName/info.anat.$scanDateCheck.$scanExamCheck.* 1> /dev/null 2>&1; then
	echo "have"
else
	tarbPath=$(echo $anatTarb | cut -d "/" -f3-)
	rsync galactica.nimh.nih.gov::${tarbPath} $wd/
	anatTarb=$(echo $subAnat)
	fullAnatTarPath=$(echo "$anatTarb" | tr -d '\r')
	fullAnatTarPath=$(echo "$fullAnatTarPath" | sed 's@\\r@@g')
	scanDatetmp=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
	scanMonthDay=$(echo ${scanDatetmp:0:4})
	scanYear=$(echo ${scanDatetmp:4:2})
	scanDateCheck=$(echo "20$scanYear$scanMonthDay")
	scanExamCheck=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
	obscureName=$(echo $fullAnatTarPath | cut -d "." -f1 | rev | cut -d "/" -f1 | rev)
	DOB=$(grep DOB /data/elliottml/3TC_rest/data/$obscureName/info.$obscureName.txt | cut -d "=" -f2)
	scanAge=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l)
	tarFile=$(echo $tarbPath | rev | cut -d "/" -f1 | rev)
	#####Untar and reconstruct before moving
	cd $wd
	tar -zxf $tarFile --wildcards --no-anchored 'sagittal_anat_me_mp_rage_1_mm*' ####Double check, doesnt like $fullTarPath
	scanType="MEMPRAGE.3TC.32CH"
	cd */*
	for anatSCN in $(ls -d mr_????);do
		echo "creating nii for Anat Scan $anatSCN"
		cd $wd/*/*
		prep_memprage $anatSCN y n #should combine echos and n3 normalize
		protocol=$2
		scanner=$(echo $fullAnatTarPath | cut -d "." -f3)
		scanDatetmp=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
		scanMonthDay=$(echo ${scanDatetmp:0:4})
		scanYear=$(echo ${scanDatetmp:4:2})
		scanDate=$(echo "20$scanYear$scanMonthDay")
		scanExam=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
		scanSeries=$(echo $anatSCN | sed 's/mr_//g' | sed 's/0//g')
		tarbRowWithNotes=$(grep $fullAnatTarPath /data/elliottml/3TC_rest/lists/anatMEMPRAGEquery_withnotes_$date.hashsv | cut -d "#" -f13 | grep -nr $scanSeries | cut -d ":" -f1 )
		numTRs=$(3dinfo -nv $wd/*/*/${anatSCN}/${anatSCN}_me_combined.nii)
		scanNotes=$(grep $fullAnatTarPath /data/elliottml/3TC_rest/lists/anatMEMPRAGEquery_withnotes_$date.hashsv | sed "${tarbRowWithNotes}q;d" | cut -d "#" -f 12)
		mv $wd/*/*/${anatSCN}/${anatSCN}_me_combined.nii /data/elliottml/3TC_rest/data/$obscureName/anat.$scanDate.$scanExam.$scanSeries.nii
		echo "" > /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt #clear the file
		echo "FullTarPath=$fullAnatTarPath" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "protocol=$protocol" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "scanDate=$scanDate" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "SCANTYPE=$scanType" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "scanSeries=$scanSeries" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "scanAge=$scanAge" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "scanName=/data/elliottml/3TC_rest/data/$obscureName/anat.$scanDate.$scanExam.$scanSeries.nii" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "numTRs=$numTRs" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "scanNotes=$scanNotes" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
		echo "QC=" >> /data/elliottml/3TC_rest/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
	done
	gzip /data/elliottml/3TC_rest/data/$obscureName/*.nii
fi
