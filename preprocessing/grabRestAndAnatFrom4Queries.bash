#!/bin/bash

####Improvement Ideas/Future directions
#1) make generalizable to all kinds of Rest. Currently the queries are generalized so you just need to allow user input of minAge, protocolNumber, etc.. so that user can 
#restrict downloading of data to those scans
#2) make this download to a central repository for everybody :)
#3) make this run on Biowulf for speed.
#4) Allow this to check for new anats even if rest scan is already downloaded (may not be necessary because new anats should be somewhat paired with new rests)



date=$(date +"%Y%d%m")
queryToRun="date=$(date +"%Y%d%m");sindb_query.py /x/Rdrive/Max/queries/MR750_Rest_nonotes_20151202.txt /x/Rdrive/Max/queries/restNoNotes_$date;sindb_query.py /x/Rdrive/Max/queries/MR750_Rest_withnotes_20151202.sql /x/Rdrive/Max/queries/restWithNotes_$date;sindb_query.py /x/Rdrive/Max/queries/MEMPRAGE_nonotes_20151202.txt /x/Rdrive/Max/queries/anatnoNotes_$date;sindb_query.py /x/Rdrive/Max/queries/MEMPRAGE_withnotes_20151202.txt /x/Rdrive/Max/queries/anatWithNotes_$date"
wd=/helix/data/00M_rest
cd $wd
if [[ ! -f /helix/data/00M_rest/lists/restNoNotes_$date ]];then
	echo ""
	echo "You need to run the sinDB query"
	echo "use your sindb userName and Password"
	echo "First log in as Weili, type in the Weili Password"
	echo "run this as weili in a bash shell:  "      
	echo "" 
	echo "${queryToRun};exit"
	echo ""
	echo "then run this as yourself:"
	echo "
	date=$(date +"%Y%d%m");mv /x/Rdrive/Max/queries/restNoNotes_$date /helix/data/00M_rest/lists/;mv /x/Rdrive/Max/queries/restWithNotes_$date /helix/data/00M_rest/lists/;mv /x/Rdrive/Max/queries/anatNoNotes_$date /helix/data/00M_rest/lists/;mv /x/Rdrive/Max/queries/anatWithNotes_$date /helix/data/00M_rest/lists/
	"
	exit
fi
colNames=$(cat /helix/data/00M_rest/lists/restNoNotes_$date | head -n1 | sed $'s/\t/#/g')

###Check to make sure my funky # delimeter files will work#######
restNoNotesCheck=$(grep "#" /helix/data/00M_rest/lists/restNoNotes_$date | wc -l)
restWithNotesCheck=$(grep "#" /helix/data/00M_rest/lists/restWithNotes_$date | wc -l)
anatNoNotesCheck=$(grep "#" /helix/data/00M_rest/lists/anatNoNotes_$date | wc -l)
anatWithNotesCheck=$(grep "#" /helix/data/00M_rest/lists/anatWithNotes_$date | wc -l)
if [[ $restNoNotesCheck -gt 0 ]] || [[ $restWithNotesCheck -gt 0 ]] || [[ $anatNoNotesCheck -gt 0 ]] || [[ $anatWithNotesCheck -gt 0 ]];then
	echo "there is a # in one of the queries, this is a problem because this script uses #s for delimeters"
	echo " run grep "#" /helix/data/00M_rest/lists/restNoNotes_$date;grep "#" /helix/data/00M_rest/lists/restWithNotes_$date;grep "#" /helix/data/00M_rest/lists/anatNoNotes_$date | wc -l;grep "#" /helix/data/00M_rest/lists/anatWithNotes_$date | wc -l"
	echo "then consider removing the # from the file that returns a result, otherwith you need to edit this script so it uses a smarter delimeter than Max could think of"
	exit
fi

cat /helix/data/00M_rest/lists/restNoNotes_$date | sed 's/"//g' | tail -n +3 | sed $'s/\t/#/g'  > $wd/lists/restNoNotes_$date.hashsv #using weird delimeter to avoid in inadvertant matches in file
cat /helix/data/00M_rest/lists/restWithNotes_$date | sed 's/"//g' | tail -n +3 | sed $'s/\t/#/g'  > $wd/lists/restWithNotes_$date.hashsv
cat /helix/data/00M_rest/lists/anatNoNotes_$date | sed 's/"//g' | tail -n +3 | sed $'s/\t/#/g'  > $wd/lists/anatNoNotes_$date.hashsv
cat /helix/data/00M_rest/lists/anatWithNotes_$date | sed 's/"//g' | tail -n +3 | sed $'s/\t/#/g'  > $wd/lists/anatWithNotes_$date.hashsv
while read subScan;do
	race=$(echo $subScan | cut -f4 -d "#")
	diagnoses=$(echo $subScan | cut -f6 -d "#")
	onPlatelist=$(echo $subScan | cut -f14 -d "#")
	FDOPA=$(echo $subScan | cut -f17 -d "#")
	subNotes=$(echo $subScan | cut -f5 -d "#")
	tarb=$(echo $subScan | cut -f11 -d "#")
	familyNum=$(echo $subScan | cut -f3 -d "#")
	exclude=$(echo $subScan | cut -f13 -d "#")
	eganNotes=$(echo $subScan | cut -f15 -d "#")
	medicalRuleOut=$(echo $subScan | cut -f16 -d "#")
	DOBtmp=$(echo $subScan | cut -f12 -d "#")
	###Format DOB,a major PIMA
	year=$(echo $DOBtmp | cut -d "/" -f1)
	month=$(echo $DOBtmp | cut -d "/" -f2)
	day=$(echo $DOBtmp | cut -d "/" -f3)
	obscureName=$(echo $tarb | cut -d "." -f1 | rev | cut -d "/" -f1 | rev)
	mLen=${#month}
	dLen=${#day}
	if [ "$mLen" -ne "2" ];then
		month=$(echo "0$month")
	fi
	if [ "$dLen" -ne "2" ];then
		day=$(echo "0$day")
	fi
	#year=$(echo ${year:(-2)})
	DOB=$(echo "$year$month$day")
	DOBlen=${#DOB}
	if [[ $DOBlen -eq 8 ]];then #check that inputs to info.obscureName.txt will be correct before begining to unpack scans
	############################
		#IFS=', ' read -r -a scans <<< "$tarbs" #wierd syntax but puts all tarballs into an array that can be looped through
		fullTarPath=$(echo "$tarb" | tr -d '\r') #hopefully sed gets rid of \r issues
		scanAgeCheck=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l) #trying to avoid anat and rest variable confusion
		scannerCheck=$(echo $fullTarPath | cut -d "." -f3) 
		scanExamCheck=$(echo $fullTarPath | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
		scanDatetmpCheck=$(echo $fullTarPath | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
		scanMonthDayCheck=$(echo ${scanDatetmpCheck:0:4})
		scanYearCheck=$(echo ${scanDatetmpCheck:4:2})
		scanDateCheck=$(echo "20$scanYearCheck$scanMonthDayCheck")
		scanDateCheckSecs=$(date --date="$scanDateCheck" +%s)
		echo "$obscureName, $tarb"
	####ONLY untar data if age is over 18 and we don't already have data#################
		if [[ $scannerCheck == "mr750" ]] && [[ $scanDateCheckSecs -gt 1310702400 ]];then # last check is because first 2 chronological rest scans were for testing and throw off script
			mkdir -p "$wd/data/$obscureName"
			if [[ ! -f $wd/data/$obscureName/info.$obscureName.txt ]];then
				#####Setting up info.$obscureName file, allows you to keep track of subScanjects scans and info better. Set up so 
				#####"grep "demInfo" | cut -d "=" -f2" will get you the information you need
				echo "ObscureName=$obscureName" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "Diagnoses=$diagnoses" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "OnPlatelist=$onPlatelist" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "FDOPA=$FDOPA" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "DOB=$DOB" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "subNotes=$subNotes" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "eganNotes=$eganNotes" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "exclude=$exclude" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "medicalRuleOut=$medicalRuleOut" >> $wd/data/$obscureName/info.$obscureName.txt
				echo "familyNum=$familyNum" >> $wd/data/$obscureName/info.$obscureName.txt
			fi
	#############Check for entry of scan in info.$obscureName, if its not there that add it and untar, adding info to info.$obscureName for each rest scan and anat
			if ls $wd/data/$obscureName/info.rest.$scanDateCheck.$scanExamCheck.* 1> /dev/null 2>&1; then
				echo "already have Rest data for $tarb"
			else
				cd $wd/data/$obscureName
				mkdir tmpRestRaw
				cd tmpRestRaw
				echo "Grabbing Rest from Tarball $tarb"
				fullTarPath=$(echo "$fullTarPath" | sed 's@\\r@@g')
				echo "untarring $fullTarPath"
				tar -zxf $fullTarPath --wildcards --no-anchored 'fmri_rest_32ch*'
				scanType="REST.3TC.32CH"
				scanDateExam=$(echo "$scanDate.$scanExam")
				cd $wd/data/$obscureName/tmpRestRaw/*/*
				for rstSCN in $(ls -d *);do
					protocol=$(echo $subScan | cut -f7 -d "#")
					scanner=$(echo $fullTarPath | cut -d "." -f3)
					scanDatetmp=$(echo $fullTarPath | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
					scanMonthDay=$(echo ${scanDatetmp:0:4})
					scanYear=$(echo ${scanDatetmp:4:2})
					scanDate=$(echo "20$scanYear$scanMonthDay")
					scanExam=$(echo $fullTarPath | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
					scanAge=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l)
					cd $wd/data/$obscureName/tmpRestRaw/*/*/$rstSCN
					scanSeries=$(echo $rstSCN | sed 's/mr_//g' | sed 's/0//g')
					echo "creating nii for Rest Scan series $scanSeries"
					mri_convert --in_type dicom --out_type nii fmri_rest_32ch-00001.dcm rest.$scanDate.$scanExam.$scanSeries.nii
					numTRs=$(3dinfo -nv rest.$scanDate.$scanExam.$scanSeries.nii)
					tarbRowWithNotes=$(grep $fullTarPath $wd/lists/restWithNotes_$date.hashsv | cut -d "#" -f14 | grep -nr $scanSeries | cut -d ":" -f1 )
					scanNotes=$(grep $fullTarPath $wd/lists/restWithNotes_$date.hashsv | sed "${tarbRowWithNotes}q;d" | cut -d "#" -f 13)
					if [[ "$numTRs" -gt 149 ]];then
						echo "FullTarPath=$fullTarPath" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "protocol=$protocol" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanDate=$scanDate" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "SCANTYPE=$scanType" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanSeries=$scanSeries" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanAge=$scanAge" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanName=rest.$scanDate.$scanExam.$scanSeries.nii" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "numTRs=$numTRs" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanNotes=$scanNotes" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "QC=" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						mv $wd/data/$obscureName/tmpRestRaw/*/*/$rstSCN/rest.$scanDate.$scanExam.$scanSeries.nii $wd/data/$obscureName/
						gzip $wd/data/$obscureName/rest.$scanDate.$scanExam.$scanSeries.nii
						cd $wd/data/$obscureName/
					else
						echo "FullTarPath=$fullTarPath" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "protocol=$protocol" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanDate=$scanDate" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "SCANTYPE=$scanType" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanSeries=$scanSeries" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanAge=$scanAge" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanName=rest.$scanDate.$scanExam.$scanSeries.nii" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "numTRs=$numTRs" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "scanNotes=$scanNotes" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						echo "QC=!!!!Scan Aborted, .nii file deleted!!!!" >> $wd/data/$obscureName/info.rest.$scanDate.$scanExam.$scanSeries.txt
						cd $wd/data/$obscureName/
					fi
				done
				echo "cleaning up Rest dirs"
				rm -r $wd/data/$obscureName/tmpRestRaw
			fi
			#if ls $wd/data/$obscureName/info.anat* 1> /dev/null 2>&1; then
			#	echo "already have Anats for $obscureName"
			#else
			###############################ME-MPRAGES#################################
				echo "Grabbing all ME-MPRAGES for $obscureName"
				grep $obscureName $wd/lists/anatNoNotes_$date.hashsv > $wd/lists/tmp.$obscureName.anats
				while read subAnat;do
					cd $wd/data/$obscureName
					mkdir tmpAnatRaw
					cd tmpAnatRaw
					anatTarb=$(echo $subAnat | cut -f11 -d "#")	
					fullAnatTarPath=$(echo "$anatTarb" | tr -d '\r')
					fullAnatTarPath=$(echo "$fullAnatTarPath" | sed 's@\\r@@g')
					scanDatetmp=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
					scanMonthDay=$(echo ${scanDatetmp:0:4})
					scanYear=$(echo ${scanDatetmp:4:2})
					scanDateCheck=$(echo "20$scanYear$scanMonthDay")
					scanExamCheck=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
					obscureName=$(echo $fullAnatTarPath | cut -d "." -f1 | rev | cut -d "/" -f1 | rev)
					DOB=$(grep DOB $wd/data/$obscureName/info.$obscureName.txt | cut -d "=" -f2)
					scanAge=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l)
					if ls $wd/data/$obscureName/info.anat.$scanDateCheck.$scanExamCheck.* 1> /dev/null 2>&1; then
						echo "already have $fullAnatTarPath ME-MPRAGES"
						cd $wd/data/$obscureName
						rm -r $wd/data/$obscureName/tmpAnatRaw
					else
						echo "untarring $fullAnatTarPath"
						tar -zxf $fullAnatTarPath --wildcards --no-anchored 'sagittal_anat_me_mp_rage_1_mm*' ####Double check, doesnt like $fullTarPath
						scanType="ANAT.3TC.32CH"
						cd $wd/data/$obscureName/tmpAnatRaw/*/*
						for anatSCN in $(ls -d mr_????);do
							echo "creating nii for Anat Scan $anatSCN"
							cd $wd/data/$obscureName/tmpAnatRaw/*/*
							prep_memprage $anatSCN y n #should combine echos and n3 normalize
							cd $wd/data/$obscureName/
							protocol=$(echo $subAnat | cut -f7 -d "#")
							scanner=$(echo $fullAnatTarPath | cut -d "." -f3)
							scanDatetmp=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f1) # need to get into monthdayyear format
							scanMonthDay=$(echo ${scanDatetmp:0:4})
							scanYear=$(echo ${scanDatetmp:4:2})
							scanDate=$(echo "20$scanYear$scanMonthDay")
							scanExam=$(echo $fullAnatTarPath | cut -d "." -f2 | cut -d "_" -f2 | sed 's/exam//g')
							scanSeries=$(echo $anatSCN | sed 's/mr_//g' | sed 's/0//g')
							tarbRowWithNotes=$(grep $fullAnatTarPath $wd/lists/anatWithNotes_$date.hashsv | cut -d "#" -f13 | grep -nr $scanSeries | cut -d ":" -f1 )
							numTRs=$(3dinfo -nv anat.$scanDate.$scanExam.$scanSeries.nii)
							scanNotes=$(grep $fullAnatTarPath $wd/lists/anatWithNotes_$date.hashsv | sed "${tarbRowWithNotes}q;d" | cut -d "#" -f 12)
							mv $wd/data/$obscureName/tmpAnatRaw/*/*/${anatSCN}/${anatSCN}_me_combined.n3.nii $wd/data/$obscureName/anat.$scanDate.$scanExam.$scanSeries.nii
							echo "FullTarPath=$fullAnatTarPath" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "protocol=$protocol" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "scanDate=$scanDate" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "SCANTYPE=$scanType" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "scanSeries=$scanSeries" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "scanAge=$scanAge" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "scanName=$wd/data/$obscureName/anat.$scanDate.$scanExam.$scanSeries.nii" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "numTRs=$numTRs" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "scanNotes=$scanNotes" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							echo "QC=" >> $wd/data/$obscureName/info.anat.$scanDate.$scanExam.$scanSeries.txt
							cd $wd/data/$obscureName/
						done
						cd $wd/data/$obscureName/
						echo "cleaning up anat dirs"
						rm -r $wd/data/$obscureName/tmpAnatRaw
						gzip $wd/data/$obscureName/*.nii
					fi
				done < $wd/lists/tmp.$obscureName.anats
				rm $wd/lists/tmp.$obscureName.anats
				echo "Have all ME-MPRAGES from $fullAnatTarPath"
				#fi
		else
			echo "Scanner = $scannerCheck, Scan Age = $scanAgeCheck, Scan Date= $scanDateCheckSecs. One of these variables is causing scripts to skip over $fullTarPath"
		fi
	else
		echo "##############################################################"
		echo "Weird DOB for $obscureName, skipping a tarball, check error log in /helix/data/00M_rest/scripts/LOGS/grabRestAndAnatFrom4Queries_$date.error"
		echo "$subScan" >> /helix/data/00M_rest/scripts/LOGS/grabRestAndAnatFrom4Queries_$date.error
		echo "##############################################################"
	fi
done < $wd/lists/restNoNotes_$date.hashsv
