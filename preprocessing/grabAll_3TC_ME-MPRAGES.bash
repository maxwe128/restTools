#!/bin/bash

##############################grabAll_3TC_ME-MPRAGES.bash################



date=$(date +"%Y%d%m")
queryToRun="bash;date=$(date +"%Y%d%m");sindb_query.py /x/Rdrive/Max/queries/MEMPRAGEgrabAll_nonotes.txt /x/Rdrive/Max/queries/anatMEMPRAGEquery_nonotes_$date;sindb_query.py /x/Rdrive/Max/queries/MEMPRAGEgrabAll_withnotes.txt /x/Rdrive/Max/queries/anatMEMPRAGEquery_withnotes_$date"
wd=/helix/data/3TC_rest
cd $wd
if [[ ! -f /helix/data/3TC_rest/lists/anatMEMPRAGEquery_withnotes_$date ]];then
	echo ""
	echo "You need to run the sinDB query"
	echo "use your sindb userName and Password"
	echo "First log in as Weili, type in the Weili Password"
	echo "run this as weili in a bash shell:  "      
	echo "" 
	echo "${queryToRun};exit;exit"
	echo ""
	echo "then run this as yourself:"
	echo "
	date=$(date +"%Y%d%m");mv /x/Rdrive/Max/queries/anatMEMPRAGEquery_withnotes_$date /helix/data/3TC_rest/lists/;mv /x/Rdrive/Max/queries/anatMEMPRAGEquery_nonotes_$date /helix/data/3TC_rest/lists/
	"
	exit
fi

anatNoNotesCheck=$(grep "#" /helix/data/3TC_rest/lists/anatMEMPRAGEquery_nonotes_$date | wc -l)
anatWithNotesCheck=$(grep "#" /helix/data/3TC_rest/lists/anatMEMPRAGEquery_withnotes_$date | wc -l)

if [[ $anatNoNotesCheck -gt 0 ]] || [[ $anatWithNotesCheck -gt 0 ]];then
	echo "there is a # in one of the queries, this is a problem because this script uses #s for delimeters"
	echo " run grep "#" /helix/data/3TC_rest/lists/anatMEMPRAGEquery_withnotes_$date;grep "#" /helix/data/3TC_rest/lists/anatMEMPRAGEquery_nonotes_$date"
	echo "then consider removing the # from the file that returns a result, otherwith you need to edit this script so it uses a smarter delimeter than Max could think of"
	exit
fi

cat /helix/data/3TC_rest/lists/anatMEMPRAGEquery_nonotes_$date | sed 's/"//g' | sed $'s/\t/#/g'  > $wd/lists/anatMEMPRAGEquery_nonotes_$date.hashsv
cat /helix/data/3TC_rest/lists/anatMEMPRAGEquery_withnotes_$date | sed 's/"//g' | sed $'s/\t/#/g'  > $wd/lists/anatMEMPRAGEquery_withnotes_$date.hashsv

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
		protocol=$(echo $subScan | cut -f7 -d "#")
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
			###############################ME-MPRAGES#################################
			scanAge=$(echo "$(( ($(date --date="$scanDate" +%s) - $(date --date="$DOB" +%s) )/(60*60*24) ))/365" | bc -l)
			scanSeries=$(echo $anatSCN | sed 's/mr_//g' | sed 's/0//g')
			if ls $wd/data/$obscureName/anat.$scanDateCheck.$scanExamCheck* 1> /dev/null 2>&1; then
				echo "have"
			else

				echo "cd /data/elliottml/3TC_rest/scripts/restTools/preprocessing;./grabSubMEMPRAGEfromQuery.bash $fullTarPath $protocol" >> $wd/lists/swarm.grabAll_3TC_ME-MPRAGES_$date
				echo "will grab MEMPRAGEs from $fullTarPath"
			fi
		else
			echo "Scanner = $scannerCheck, Scan Age = $scanAgeCheck, Scan Date= $scanDateCheckSecs. One of these variables is causing scripts to skip over $fullTarPath"
		fi
	else
		echo "##############################################################"
		echo "Weird DOB for $obscureName, skipping a tarball, check error log in /helix/data/3TC_rest/scripts/LOGS/grabAll_3TC_ME-MPRAGES_$date.error"
		echo "$subScan" >> /helix/data/3TC_rest/scripts/LOGS/grabAll_3TC_ME-MPRAGES_$date.error
		echo "##############################################################"
	fi	
done < /helix/data/3TC_rest/lists/anatMEMPRAGEquery_nonotes_$date.hashsv
echo "if this script ran successfully, your next command line call should be from biowulf and be: swarm -f $wd/lists/swarm.grabAll_3TC_ME-MPRAGES_$date -g 4 -t 4 --gres=lscratch:5 --partition nimh --logdir /data/elliottml/sibStudy_func/lists/swarmOut"
