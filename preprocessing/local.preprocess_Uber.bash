#!/bin/bash

##################################preprocess_Uber.bash##############################
####################### Authored by Max Elliott in its original form sometime in 2015 ####################

####Description####
#this worker script for preprocessing resting state data

if [[ $# < 10 ]];then
	echo "
	########Requirements###########
	1)Ants needs to be downloaded and in your path
	2)spm12sa needs to be downloaded and in your path
	3)Freesurfer needs to be downloaded and in your path
	######Call structure############

	preprocess_Uber.bash {working Directory} {subject list} {warp and segment?} {Art params} {CompCorr?} {motion params} {smoothing kernel} (numberRest} {surface?} {warpTemplate} {keep Temp files?}
	
	Example) run_preprocess_Uber.bash ../data_V1/ 10MInclusiveList F .25_3 F 24 10 F
	##############Intro################
	This script automates the running of preprocess_Uber.bash so that you can easily preprocess large groups of people with different preprocessing params.
	It will make a swarm file, write it to the current directory and run the swarm file

	#options that can change: WarpAndSegment- this is made to save space. After it has been ran once on a subject the subject will then have the important files in their parent directory. Then all other preprocessing schemes will rely on these files and you no longer need matlab licences and things move much faster,ART-can adjust censoring params mm and g, COMPcorr-True or False, MOTION REGRESSORS-0, 6(typical),12(adds temproral derivative),18(adds quadratic) or 24(adds temporal derivative of quadratic), BLURRING-FWHM kernel(can be any integer)
	#
	#
	#####input
	"
else
wd=$1 #begginning of tree, assumes that all subjects have their own folder within this dir
subjName=$2 #Assumes that in subject folder is a file called anat.nii.gz, rest1.nii.gz and rest2.nii.gz, this is also where I keep FS and SUMA dirs
WarpAndSegment=$3 #either T or F, Chose T to start preprocessing from beggnining Choose F if you have already Done this
ART=$4 #should be in form {integer indicating mm movement cutoff within TR}-{integer indicating sd of signal change cutoff}. Example) .25-3. Can also be F for no ART
CompCorr=$5 #either T or F. Do you want CompCorr run of dataset
motionReg=$6 #how many motion regressors do you want in preprocessing. See above for details
smooth=$7 ##smoothing kernel, can be any integer
numRest=$8
surf=$9 ##Sample data to individuals surface after running preprocessing.
warpTemp=${10} #this is the hardCoded name of the template files below, add another if the one you want isn't here
tempFiles=${11}

echo "preprocess_Uber.bash $wd $subjName $WarpAndSegment $ART $CompCorr $motionReg $smooth $numRest $surf $warpTemp $tempFiles"


surfID="PREP.A${ART}_C${CompCorr}_M${motionReg}"
volID="PREP.A${ART}_C${CompCorr}_M${motionReg}_WT$warpTemp"
randID=$(date "+%Y-%m-%d_%H:%M:%S") #generates an ID based on time and Date that will be added to all outputFiles to distinguish runs of this script
prepDir="${wd}/${subjName}/${volID}"
surfPrepDir="${wd}/${subjName}/surf.${surfID}"
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
templateDir="${wd}/${subjName}/template_${warpTemp}_files" #Idea is that all warped and warp related files will go here, this way multiple runs of preprocessing can be done without having to rewarp and multiple templates can be used for the same scans without having confusion

if [ $warpTemp == "n7.WSTDDUP.MNI" ];then
	#mask="/helix/data/rest10M/templates/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii"
	echo "Using WS Dup Kid templates"
	regMask="/helix/data/rest10M/templates/mask.1_brain_combined_ws_td_dupn7template_MNI_restVox.nii"
	template=/helix/data/rest10M/templates/T1_combined_ws_td_dupn7template_MNI_1.5.nii
	stripTemplate=/helix/data/rest10M/templates/brain_combined_ws_td_dupn7template_MNI_1.5.nii
	brainmask=/helix/data/rest10M/templates/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii
elif [ $warpTemp == "n240.SagVols.MNI" ];then
	echo "using adult 240 sagVols templates"
	regMask="/helix/data/COBRE/templates/mask.1_T1_dartel_strip_240sagvols_SOINrestVox.nii"
	template=/helix/data/COBRE/templates/T1_dartel_avg_240sagvols_1.5mm_MNI.nii
	stripTemplate=/helix/data/COBRE/templates/T1_dartel_strip_240sagvols_1.5mm_MNI.nii
	brainmask=/helix/data/COBRE/templates/T1_dartel_brainmask_240sagvols_1.5mm_MNI.nii
else
	echo "no matching brain mask, please make another and input into preprocess_Uber.bash" 
	exit
fi
mkdir -p $prepDir
cd $prepDir

#setup matlab MCR env variables
echo "here $pwd"
		for restNum in $(seq 1 $numRest);do
			rm rest${restNum}_vr_motion.1D
			cp ${templateDir}/rest${restNum}_vr_motion.1D ./
			numTR=$(cat ${templateDir}/rest1_vr_motion.1D | wc -l)
			rm regressors${restNum}.1D
			for j in $(seq 1 $numTR);do echo $j >> regressors${restNum}.1D; done
			if [ $CompCorr == T ];then
				1dcat regressors${restNum}.1D ${templateDir}/pc${restNum}.wm.csf0* > regressors${restNum}_compCorr.1D
				rm regressors${restNum}.1D
				mv regressors${restNum}_compCorr.1D ./regressors${restNum}.1D
			fi

			if [ $motionReg > 0 ];then
				echo ""; echo "############################ setting up motion Regression #################"
				1d_tool.py -infile rest${restNum}_vr_motion.1D -derivative -write rest${restNum}_vr_motion_deriv.1D
				for i in $(seq 0 1 5);do
					1deval -a rest${restNum}_vr_motion.1D"[$i]" -expr 'a^2' > rest${restNum}_vr_motion_quad_temp${i}.1D
					1deval -a rest${restNum}_vr_motion_deriv.1D"[$i]" -expr 'a^2' > rest${restNum}_vr_motion_deriv_quad_temp${i}.1D
				done
				paste -d " " rest${restNum}_vr_motion_quad_temp* > rest${restNum}_vr_motion_quad.1D
				paste -d " " rest${restNum}_vr_motion_deriv_quad_temp* > rest${restNum}_vr_motion_deriv_quad.1D
				rm *quad_temp*
				######make FD time courses for subjects runs#######
				1d_tool.py -infile rest${restNum}_vr_motion_deriv.1D -collapse_cols euclidean_norm -write tmp_FD${restNum}.1D
				echo ""; echo "#################"; echo "Using regressors of no interest and determining residuals"; echo "#################"

				if [ $motionReg == 6 ];then
					1dcat regressors${restNum}.1D rest${restNum}_vr_motion.1D > regressors${restNum}_motion.1D
					rm regressors${restNum}.1D
					mv regressors${restNum}_motion.1D ./regressors${restNum}.1D
				elif [ $motionReg == 12 ];then
					1dcat regressors${restNum}.1D rest${restNum}_vr_motion.1D rest${restNum}_vr_motion_deriv.1D > regressors${restNum}_motion.1D
					rm regressors${restNum}.1D
					mv regressors${restNum}_motion.1D ./regressors${restNum}.1D
				elif [ $motionReg == 18 ];then
					1dcat regressors${restNum}.1D rest${restNum}_vr_motion.1D rest${restNum}_vr_motion_deriv.1D rest${restNum}_vr_motion_quad.1D > regressors${restNum}_motion.1D
					rm regressors${restNum}.1D
					mv regressors${restNum}_motion.1D ./regressors${restNum}.1D
				elif [ $motionReg == 24 ];then
					1dcat regressors${restNum}.1D rest${restNum}_vr_motion.1D rest${restNum}_vr_motion_deriv.1D rest${restNum}_vr_motion_quad.1D rest${restNum}_vr_motion_deriv_quad.1D > regressors${restNum}_motion.1D
					rm regressors${restNum}.1D
					mv regressors${restNum}_motion.1D ./regressors${restNum}.1D
				else
					echo "!!!!!!!!!!!!!!!!!!!!!!!!!!You failed at choosing a motionReg option!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
					exit
				fi
			fi
		done
		cat tmp_FD*.1D > FD_both.1D
		awk '{s+=$1}END{print s/NR}' RS="\n" FD_both.1D >meanFD.txt #Mean of list of nums with awk, gets around biowulf Rscript issue
		if [ $tempFiles == F ];then
			rm anat* Manat* strip* spm* Wanat[123456789]* *tmp* seg* art_*
		else
			echo "keeping Files"
		fi
		gzip -f *.nii
	#else
		#echo "#################";echo "skipping over regressor creation, already has been completed";echo "#################"
	#fi
	if [ $ART != F ];then
		if [[ -s cenArray_1 ]];then
			echo "skipping Art, already ran"
		else
			echo "!!!!!!!!!!!!!!!!!!!!!!";echo "!!!!!!!!!!!!!!!!!!!!!!";echo "!!!!!!!!!!!!!!!!!!!!!!";echo "no outliers file, run this through biowulf again or make sure you know what you are doing"
			echo "exiting"
			exit
		fi
	fi
	echo ""; echo "#################"; echo "bandpass filtering, detrending and blurring rest data"; echo "#################"
	scanTRs=$(3dinfo -nv ${templateDir}/Wrest1.nii.gz)
	numTotalTRs=$(expr $scanTRs \* $numRest)
	cen=$(paste -d " " cenArray_*) #get Trs to censor for the all rests concatenated together
	echo $cen > outliers_concat.1D
	len=$(echo $cen | wc -w)
	cat regressors*_IN.1D > allRegressors.1D
if [ ! -f ${prepDir}/concat_blurat${smooth}mm_bpss_${volID}.nii.gz ];then
	if [[ $len == 0 ]];then
		echo "3dTproject -input ${templateDir}/Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${volID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth"
		3dTproject -input ${templateDir}/Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${volID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth
	else
		echo "3dTproject -input ${templateDir}/Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${volID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth -CENSORTR $cen"
		3dTproject -input ${templateDir}/Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${volID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth -CENSORTR $cen
	fi
	echo "3dTproject -input ${templateDir}/Wrest*.nii.gz -prefix concat_RAW_blurat${smooth}mm.nii.gz -mask $regMask -blur $smooth"
	3dTproject -input ${templateDir}/Wrest*.nii.gz -prefix concat_RAW_blurat${smooth}mm.nii.gz -mask $regMask -blur $smooth

	3dresample -master concat_blurat${smooth}mm_bpss_${volID}.nii.gz -inset $brainmask -prefix brainmask_2funcgrid_${volID}.nii.gz
else
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!Already ran Preprocessing on Volume!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!Make sure that this is okay!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!Moving on to Surfaced based processing!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

#############Surface Part, Still working on this##################
#steps: run preprocessing without warp or smooth, run recon-all if not run, run SUMAMakeSpec if not run, sample rest to surface, SurfSmooth


if [[ $surf == T ]] && [[ ! -f ${surfPrepDir}/volData.NonCortical.concat_blurat${smooth}mm_bpss_${surfID}.nii.gz ]] && [[ ! -f ${surfPrepDir}/std.30.${subjName}_lh.concat_SurfSmooth10mm_bpss_${surfID}.1D.dset ]];then
	echo "processing Surfaces"	
	mkdir -p $surfPrepDir
	cd $surfPrepDir
	cp ${prepDir}/allRegressors.1D ./
	surfCen=$(3dinfo ${prepDir}/concat_blurat${smooth}mm_bpss_${volID}.nii.gz | grep CENSOR | sed 's/.*CENSORTR //g') ##dinky workaround to get censored trs from art
	surfLen=$(echo $surfCen | wc -w)
	if [[ $surfLen == 0 ]];then
		echo "3dTproject -input ${templateDir}/rest*_vr.nii -prefix vol4surf.concat_bpss_${surfID}.nii.gz -ort allRegressors.1D -polort 1 -bandpass 0.008 0.10"
		3dTproject -input ${templateDir}/rest*_vr.nii -prefix vol4surf.concat_bpss_${surfID}.nii.gz -ort allRegressors.1D -polort 1 -bandpass 0.008 0.10
	else
		echo "3dTproject -input ${templateDir}/rest*_vr.nii -prefix vol4surf.concat_bpss_${surfID}.nii.gz -ort allRegressors.1D -polort 1 -bandpass 0.008 0.10 -CENSORTR $surfCen"
		3dTproject -input ${templateDir}/rest*_vr.nii -prefix vol4surf.concat_bpss_${surfID}.nii.gz -ort allRegressors.1D -polort 1 -bandpass 0.008 0.10 -CENSORTR $surfCen
	fi
	if [[ ! -f ${wd}/${subjName}/surf/rh.sphere ]];then
		echo "Creating surfaces with Freesurfer and MakeSpec"
		export SUBJECTS_DIR=$wd
		sub=$subjName
		cd $wd
		mksubjdirs ${sub}_tmp
		cp -r ${sub}_tmp/* ${sub}/
		rm -r ${sub}_tmp
		cd ${wd}/${sub}/mri/orig
		mri_convert ${wd}/${sub}/anat.nii.gz ${wd}/${sub}/mri/orig/001.mgz
		##RUN FS ON SUBJECT
		cd $SUBJECTS_DIR
		recon-all -openmp 4 -all -subject $sub
		##ALIGN FS SURFACES TO STANDARD MESH AND MAKE SUMA READABLEF
		cd ${SUBJECTS_DIR}/${sub}
		@SUMA_Make_Spec_FS -use_mgz -sid $sub -ld 141 -ld 60 -ld 30 #ld of 30 should be about equivelnt to number of gray matter voxels in a 4X4X4mm analysis in CWAS
	elif [[ ! -f ${wd}/${subjName}/SUMA/std.141.rh.thickness.niml.dset ]];then
		echo "Freesurfer completed, running MakeSpec"
		export SUBJECTS_DIR=$wd
		sub=$subjName
		cd ${SUBJECTS_DIR}/${sub}
		@SUMA_Make_Spec_FS -use_mgz -sid $sub -ld 141 -ld 60 -ld 30 #ld of 30 should be about equivalent to number of gray matter voxels in a 4X4X4mm analysis in CWAS
		
	else
		echo "Freesurfer and MakeSpec already ran"
	fi
	echo "Surfaces are created, sampling rest data to surface and using FS segmentations to keep volume data"
	cd $surfPrepDir
	mkdir -p tmp
	cd tmp
	###Align all volume files to Surface space
	3dcalc -a ${templateDir}/rstrip.anat1.nii.gz -expr 'a' -prefix rstrip.anat
	3dcalc -a ${wd}/${subjName}/SUMA/aparc.a2009s+aseg_rank.nii -expr 'a' -prefix aparc.a2009s+aseg_rank
	3dcalc -a ${wd}/${subjName}/SUMA/aseg_rank.nii -expr 'a' -prefix aseg_rank
	3dcalc -a ${wd}/${subjName}/SUMA/aparc+aseg_rank.nii -expr 'a' -prefix aparc+aseg_rank
	@SUMA_AlignToExperiment -exp_anat rstrip.anat+orig. -surf_anat ${wd}/${subjName}/SUMA/brainmask.nii -align_centers -prefix anat_Alnd_exp -surf_anat_followers aparc.a2009s+aseg_rank+orig. aseg_rank+orig. aparc+aseg_rank+orig.
	for mesh in std.60.${subjName}_rh std.60.${subjName}_lh std.30.${subjName}_rh std.30.${subjName}_lh;do
		3dVol2Surf -spec ${wd}/${subjName}/SUMA/$mesh.spec -surf_A smoothwm -surf_B pial -sv anat_Alnd_exp+orig.HEAD -grid_parent ${surfPrepDir}/vol4surf.concat_bpss_${surfID}.nii.gz -map_func ave -oob_value 0 -f_steps 10 -f_index nodes -f_p1_fr -0.1 -f_pn_fr 0.1 -skip_col_nodes -skip_col_1dindex -skip_col_i -skip_col_j -skip_col_k -skip_col_vals -no_headers -out_1D ${mesh}.concat_bpss_${surfID}.1D.dset
		SurfSmooth -met HEAT_07 -input ${mesh}.concat_bpss_${surfID}.1D.dset -fwhm 10 -output $mesh.concat_SurfSmooth10mm_bpss_${surfID}.1D.dset -spec ${wd}/${subjName}/SUMA/$mesh.spec
		mv $mesh.concat_SurfSmooth10mm_bpss_${surfID}.1D.dset ../
	done
	####Extract non-cortical values from volume in organized way
	3dresample -master ${surfPrepDir}/vol4surf.concat_bpss_${surfID}.nii.gz -inset ${surfPrepDir}/tmp/aseg_rank_Alnd_Exp+orig -prefix aseg_rank_Alnd_resamp.nii
	3dcalc -a aseg_rank_Alnd_resamp.nii -expr '(ispositive(equals(a,28))*a+ispositive(equals(a,8))*a+ispositive(equals(a,29))*a+ispositive(equals(a,9))*a+ispositive(equals(a,27))*a+ispositive(equals(a,7))*a+ispositive(equals(a,30))*a+ispositive(equals(a,10))*a+ispositive(equals(a,7))*a+ispositive(equals(a,13))*a+ispositive(equals(a,26))*a+ispositive(equals(a,6))*a+ispositive(equals(a,15))*a+ispositive(equals(a,14))*a+ispositive(equals(a,31))*a+ispositive(equals(a,32))*a)' -prefix volumeForSurfAnalysesMask.nii
	3dcalc -b ${surfPrepDir}/vol4surf.concat_bpss_${surfID}.nii.gz -a ${surfPrepDir}/tmp/volumeForSurfAnalysesMask.nii -expr '(ispositive(a))*b' -prefix volData.NonCortical.concat_bpss_${surfID}.nii
	3dBlurInMask -input volData.NonCortical.concat_bpss_${surfID}.nii -FWHM $smooth -Mmask volumeForSurfAnalysesMask.nii -prefix volData.NonCortical.concat_blurat${smooth}mm_bpss_${surfID}.nii #should I use Mmask option to only blur in distinct anatomical regions
	mv volData.NonCortical.concat_blurat${smooth}mm_bpss_${surfID}.nii ../
else
	echo "!!!!!!!!!!!!!!!!!!!!!surface processing has already been run, make sure you are okay with your previous results!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

#######################################################
#command to run if malloc error occurs
#cen=$(paste -d " " tmp_cen_*);3dTproject -input ./Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${volID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth -CENSORTR $cen;3dTproject -input ./Wrest*.nii.gz -prefix concat_RAW_blurat${smooth}mm.nii.gz -mask $regMask -blur $smooth;3dresample -master concat_blurat${smooth}mm_bpss_${volID}.nii.gz -inset $brainmask -prefix brainmask_2funcgrid_${volID}.nii.gz


####Cleanup
if [[ $tempFiles == F ]];then
	cd $prepDir
	rm rest* Decon*.nii.gz tmp* 0 art* c[123]*.nii.gz brainmask_2funcgrid* mWanat_warp* rest*_vr.nii.gz segment.1D seg_* seg.wm.csf.depth.nii.gz seg.wm.csf.nii.gz seg.wm.csf.resamp.nii.gz
	cd ../
	rm -r mWanat.nii.gz bem morph mpg rgb tiff tmp src trash 
	gzip -f *.nii
	cd $surfPrepDir
	3dcalc -a tmp/anat_Alnd_exp+orig. -expr 'a' -prefix anat_Alnd_exp.nii
	rm -r tmp
	gzip -f *.nii
else
	echo "keeping Files"
fi
fi
