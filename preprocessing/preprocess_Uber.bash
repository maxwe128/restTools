#!/bin/bash

####Need to fix the creation of the regressors file, not all being but together. Also whats up with malloc error maybe start regressors as list of 1s then use 1dcat then remove 1s at


if [[ $# < 10 ]];then
	echo "
	######Call structure############

	preprocess_Uber.bash {working Directory} {subject list} {warp and segment?} {Art params} {CompCorr?} {motion params} {smoothing kernel} {keep Temp files?}
	
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
surf=$9 ##Sample data to individuals surface after running preprocessing. This requires that WarpAndSegment has already been run
tempFiles=$10

echo "preprocess_Uber.bash $wd $subjName $WarpAndSegment $ART $CompCorr $motionReg $smooth $tempFiles"



ID="PREP.A${ART}_C${CompCorr}_M${motionReg}"
randID=$(date "+%Y-%m-%d_%H:%M:%S") #generates an ID based on time and Date that will be added to all outputFiles to distinguish runs of this script
prepDir="${wd}/${subjName}/${ID}"
surfPrepDir="${wd}/${subjName}/surf.${ID}"
antsDir="/data/SOIN/ANTS"
scriptsDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

project=$(echo $wd | cut -d "/" -f4)
if [ $project == "rest10M" ];then
	#mask="/data/elliottml/rest10M/templates/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii"
	echo "Using 10M templates"
	regMask="/data/elliottml/rest10M/templates/mask.1_brain_combined_ws_td_dupn7template_MNI_restVox.nii"
	template=/data/elliottml/rest10M/templates/T1_combined_ws_td_dupn7template_MNI_1.5.nii
	stripTemplate=/data/elliottml/rest10M/templates/brain_combined_ws_td_dupn7template_MNI_1.5.nii
	brainmask=/data/elliottml/rest10M/templates/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii
elif [ $project == "COBRE" ];then
	echo "using COBRE templates"
	regMask="/data/elliottml/COBRE/templates/mask.1_T1_dartel_strip_240sagvols_cobreRestVox_MNI.nii"
	template=/data/elliottml/COBRE/templates/T1_dartel_avg_240sagvols_1.5mm_MNI.nii
	stripTemplate=/data/elliottml/COBRE/templates/T1_dartel_strip_240sagvols_1.5mm_MNI.nii
	brainmask=/data/elliottml/COBRE/templates/T1_dartel_brainmask_240sagvols_1.5mm_MNI.nii
else
	echo "no matching brain mask, please make another and input into preprocess_Uber.bash" 
	exit
fi
mkdir -p $prepDir
cd $prepDir

#setup matlab MCR env variables

if [ ! -f concat_blurat${smooth}mm_${ID}.nii.gz ];then
if [ $WarpAndSegment == T ];then
	#####Bulk preprocessing#####
	for restNum in $(seq 1 $numRest);do
		echo "#################"; echo "copying raw data"; echo "#################"
		3dcalc -a ../rest${restNum}.nii.gz'[0]' -expr a -prefix tmp_rest${restNum}_0.nii.gz
		3dcalc -a ../rest${restNum}.nii.gz'[5..$]' -expr a -prefix tmp_rest${restNum}_cut
		if [[ $restNum > 1 ]];then
			#####Should I be using the tmp_rest*_shft later in the script double Check!!!!!!!!#####
			@Align_Centers -1Dmat_only -base tmp_rest1_0.nii.gz -dset tmp_rest${restNum}_cut+orig.
			3dAllineate -1Dmatrix_apply tmp_rest${restNum}_cut_shft.1D -prefix tmp_rest${restNum}_shft.nii.gz -master tmp_rest1_0.nii.gz -input tmp_rest${restNum}_cut+orig.
			#mv tmp_rest${restNum}_cut.nii.gz tmp_old_rest${restNum}_cut.nii.gz
			mv tmp_rest${restNum}_shft.nii.gz tmp_rest${restNum}_cut.nii.gz
		fi
		echo ""; echo "#################"; echo "motion correcting rest scans"; echo "#################"
		3dvolreg -tshift 0 -prefix rest${restNum}_vr_${ID}.nii.gz -base tmp_rest1_0.nii.gz'[0]' -1Dfile rest${restNum}_vr_motion_${ID}.1D tmp_rest${restNum}_cut.nii.gz
		echo ""; echo "#################"; echo "starting spatial normalization and spm5 coregistration"; echo "#################"
		cp ../anat.nii.gz ./anat${restNum}.nii.gz
		$scriptsDir/norm.func.spm12sa.csh tmp_rest${restNum}_0.nii.gz anat${restNum}.nii.gz $scriptsDir
		kill %1
		${antsDir}/WarpTimeSeriesImageMultiTransform 4 rest${restNum}_vr_${ID}.nii.gz W_rest${restNum}_vr_${ID}.nii.gz -R template_tmp_rest${restNum}_0.nii.gz Wanat${restNum}_Warp.nii.gz Wanat${restNum}_Affine.txt --use-NN
		3drefit -space MNI -view tlrc W_rest${restNum}_vr_${ID}.nii.gz
		echo ""; echo "#################"; echo "segmenting anatomic scan "; echo "#################"
		if [[ $restNum < 2 ]];then
			mv Wanat1.nii.gz ../Wanat.nii.gz
			gunzip ../Wanat.nii.gz
		fi
		mv W_rest${restNum}_vr_${ID}.nii.gz ../Wrest${restNum}.nii.gz
		mv rest${restNum}_vr_${ID}.nii.gz ../rest${restNum}_vr.nii.gz
		mv rest${restNum}_vr_motion_${ID}.1D ../rest${restNum}_vr_motion.1D
		gunzip ../rest${restNum}_vr.nii.gz
		if [[ $restNum < 2 ]];then
			cp ../Wanat.nii ./
			export MCRROOT="/usr/local/matlab-compiler/v80"
			export LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64
			export MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client
			export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}
			export XAPPLRESDIR=${MCRROOT}/X11/app-defaults
			/data/SOIN/scripts/spm5_segment Wanat.nii /data/SOIN/templates/tpm
			echo ""; echo "#################"; echo "calculating aCompCor components"; echo "#################"
			3dAllineate -base Wanat.nii -source mWanat.nii.gz -prefix mWanat_warp.nii.gz -1Dmatrix_save segment.1D
			3dAllineate -base Wanat.nii -source c1Wanat.nii.gz -1Dmatrix_apply segment.1D -prefix seg_gm.nii.gz
			3dAllineate -base Wanat.nii -source c2Wanat.nii.gz -1Dmatrix_apply segment.1D -prefix seg_wm.nii.gz
			3dAllineate -base Wanat.nii -source c3Wanat.nii.gz -1Dmatrix_apply segment.1D -prefix seg_csf.nii.gz
			3dcalc -a seg_wm.nii.gz -b seg_csf.nii.gz -expr 'step(a-0.975)+step(b-0.975)' -prefix seg.wm.csf.nii.gz
			3dresample -master ../Wrest1.nii.gz -prefix seg.wm.csf.resamp.nii.gz -inset seg.wm.csf.nii.gz
			3dmerge -1clust_depth 5 5 -prefix seg.wm.csf.depth.nii.gz seg.wm.csf.resamp.nii.gz
			3dcalc -a seg.wm.csf.depth.nii.gz -expr 'step(a-1)' -prefix seg.wm.csf.erode.nii.gz
			#gzip c[123]Wanat.nii
			mv c[123]Wanat.nii.gz ../
			gzip mWanat.nii
			mv mWanat.nii.gz ../
		fi
		3dcalc -a seg.wm.csf.erode.nii.gz -b ../Wrest${restNum}.nii.gz -expr 'a*b' -prefix rest${restNum}.wm.csf.nii.gz
		3dpc -pcsave 5 -prefix ../pc${restNum}.wm.csf rest${restNum}.wm.csf.nii.gz
		mv rest${restNum}.wm.csf.nii.gz ../
	done
fi
####could remove everything other that Wanat.nii.gz and W_rest1_vr_motion_${ID}.nii.gz and W_rest2_vr_motion_${ID}.nii.gz decon output

##################start matrix of regressors for 3dTproject
for restNum in $(seq 1 $numRest);do
	numTR=$(cat ../rest1_vr_motion.1D | wc -l)
	for j in $(seq 1 $numTR);do echo $j >> regressors${restNum}.1D; done
	if [ $CompCorr == T ];then
		1dcat regressors${restNum}.1D ../pc${restNum}.wm.csf0* > regressors${restNum}_compCorr.1D
		rm regressors${restNum}.1D
		mv regressors${restNum}_compCorr.1D ./regressors${restNum}.1D
	fi

	if [ $motionReg > 0 ];then
		ln -s ../rest${restNum}_vr_motion.1D ./
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
	rm anat* Manat* strip* spm* Wanat[123456789]* *tmp* pc* seg*
	gzip *.nii*
else
	echo "keeping Files"
fi
if [ $ART != F ];then
	cp ../rest*_vr.nii ./
	for restNum in $(seq 1 $numRest);do
		echo ""; echo "############################ running ART censoring ######################"
		###Setup cfg file
		sed 's/rest1/rest'${restNum}'/g' ${scriptsDir}/rest${restNum}_std.cfg > rest${restNum}_std.cfg
		mm=$(echo $ART | cut -d "_" -f1)
		sd=$(echo $ART | cut -d "_" -f2)
		sed 's/motion_threshold: 1/motion_threshold: '${mm}'/g' rest${restNum}_std.cfg | sed 's/global_threshold: 3.0/global_threshold: '${sd}'/g' > rest${restNum}_new.cfg
		######Art#####
		export MCRROOT="/usr/local/matlab-compiler/v80"
		export LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64
		export MCRJRE=${MCRROOT}/sys/java/jre/glnxa64/jre/lib/amd64
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/native_threads
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/server
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}/client
		export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRJRE}
		export XAPPLRESDIR=${MCRROOT}/X11/app-defaults
		${scriptsDir}/art rest${restNum}_new.cfg
		mv outliers.1D outliers${restNum}_new.1D
		outliers=$(cat outliers${restNum}_new.1D)
		lenOut=$(echo $outliers | wc -w)
		echo ""; echo "############################ get Censored Mean FD ######################"
		count=0
		out_array=($(less outliers${restNum}_new.1D)) # don't need additional to account for concating with multiplier when removing from FD
		echo ${out_array[@]} > tmp_cen_$restNum #used later for censoring
		if [[ $lenout -gt 0 ]];then
			for i in ${out_array[@]}; do out_array[$count]=$(expr $i + 1); ((count++));done # add one so correct lines of movement file are remove, these are not zero indexed like art output and afni censoring
			out_form=$(echo "$(echo ${out_array[@]} | sed 's/ /d;/g')d") #remove all lines that art said to remove, using above formatting	
			sed "${out_form}" rest${restNum}_vr_motion_deriv.1D > rest${restNum}_vr_deriv_cens.1D
			1d_tool.py -infile rest${restNum}_vr_deriv_cens.1D -collapse_cols euclidean_norm -write tmp_FD${restNum}_cens.1D
		else #for case when there are no outliers
			1d_tool.py -infile rest${restNum}_vr_motion_deriv.1D -collapse_cols euclidean_norm -write tmp_FD${restNum}_cens.1D
		fi
		cut -d " " -f3- regressors${restNum}.1D > regressors${restNum}_IN.1D #there is a space(not sure why) then an index I put in for censoring motionfile reasons, need to remove both regressors${restNum}.1D
	done
	gzip *.nii
	cat tmp_FD*_cens.1D > FD_both_cens.1D
	awk '{s+=$1}END{print s/NR}' RS="\n" FD_both_cens.1D >meanFD_cens.txt #Mean of list of nums with awk, gets around biowulf Rscript issue
fi

echo ""; echo "#################"; echo "bandpass filtering, detrending and blurring rest data"; echo "#################"

######First pass regression of nuisance covariates, Then will do censoring below. This is a hacky way of saving DOF, not the best but DOF at this stage doesnt really matter and this saves subjects#####

##count DOF and exit if not enough here, based on ART, motion, Compcorr and bandpass
echo "##################Counting Regressors and determining Degrees of Freedom########################"
if [ $CompCorr == T ];then
	compReg=5
else
	compReg=0
fi
1dBport -input ../Wrest1.nii.gz -band 0.008 0.1 -nozero -invert > tmp_bport.txt
numBandReg=$(head -n1 tmp_bport.txt | wc -w)
numBandReg=$(expr 2 + $numBandReg)
scanTRs=$(3dinfo -nv ../Wrest1.nii.gz)
numTotalTRs=$(expr $scanTRs \* $numRest)
cen=$(paste -d " " tmp_cen_*) #get Trs to censor for the all rests concatenated together
len=$(echo $cen | wc -w)
#expr $len + $motionReg + $comReg + 2 \* $numRest +
numFirstPassReg=$(expr $motionReg + $compReg + 2 )
numSecPassReg=$(expr $len + 2 \* $numBandReg)
TRsLeft=$(expr $numTotalTRs - $numSecPassReg)ls 

cat regressors*_IN.1D > allRegressors.1D
if [[ $len == 0 ]];then
	3dTproject -input ../Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${ID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth
else
	3dTproject -input ../Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${ID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth -CENSORTR $cen
fi
3dTproject -input ../Wrest*.nii.gz -prefix concat_RAW_blurat${smooth}mm.nii.gz -mask $regMask -blur $smooth

3dresample -master concat_blurat${smooth}mm_bpss_${ID}.nii.gz -inset /data/elliottml/rest10M/templates/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii -prefix brainmask_2funcgrid_${ID}.nii.gz


#############Surface Part, Still working on this##################
#steps: run preprocessing without warp or smooth, run recon-all if not run, run SUMAMakeSpec if not run, sample rest to surface, SurfSmooth


if [[ $surf == T ]];then
	mkdir -p $surfPrepDir
	cd $surfPrepDir
	cp $prepDir/allRegressors.1D ./
	if [[ $len == 0 ]];then
		3dTproject -input ../rest*_vr.nii.gz -prefix vol4surf.concat_bpss_${ID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10
	else
		3dTproject -input ../rest*_vr.nii.gz -prefix vol4surf.concat_bpss_${ID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -CENSORTR $cen
	fi
	if [[ ! -f ${wd}/${subjName}/surf/rh.sphere ]];then
		echo "Creating surfaces with Freesurfer and MakeSpec"
		export SUBJECTS_DIR=$wd
		sub=$subjName
		cd $wd
		mksubjdirs $sub
		cd $sub/mri/orig
		mri_convert ${wd}/${subjName}/anat.nii.gz 001.mgz
		##RUN FS ON SUBJECT
		cd $SUBJECTS_DIR
		recon-all -all -subject $sub
		##ALIGN FS SURFACES TO STANDARD MESH AND MAKE SUMA READABLE
		cd $SUBJECTS_DIR/$sub
		@SUMA_Make_Spec_FS -use_mgz -sid $sub -ld 141 -ld 60 -ld 30 #ld of 30 should be about equivelnt to number of gray matter voxels in a 4X4X4mm analysis in CWAS
	elif [[ ! -f ${wd}/${subjName}/SUMA/std.141.rh.thickness.niml.dset ]];then
		echo "Freesurfer completed, running MakeSpec"
		export SUBJECTS_DIR=$wd
		sub=$subjName
		cd $SUBJECTS_DIR/$sub
		@SUMA_Make_Spec_FS -use_mgz -sid $sub -ld 141 -ld 60 -ld 30 #ld of 30 should be about equivelnt to number of gray matter voxels in a 4X4X4mm analysis in CWAS
		
	else
		echo "Freesurfer and MakeSpec already ran"
	fi
	echo "Surfaces are created, sampling rest data to surface and using FS segmentations to keep volume data"
	cd $surfPrepDir
	mkdir tmp
	cd tmp
	###Align all volume files to Surface space
	3dcalc -a ../../rstrip.anat1.nii.gz -expr 'a' -prefix rstrip.anat
	3dcalc -a ../../SUMA/aparc.a2009s+aseg_rank.nii -expr 'a' -prefix aparc.a2009s+aseg_rank
	3dcalc -a ../../SUMA/aseg_rank.nii -expr 'a' -prefix aseg_rank
	3dcalc -a ../../SUMA/aparc+aseg_rank.nii -expr 'a' -prefix aparc+aseg_rank
	@SUMA_AlignToExperiment -exp_anat rstrip.anat+orig. -surf_anat ../../SUMA/brainmask.nii -align_centers -prefix anat_Alnd_exp -surf_anat_followers aparc.a2009s+aseg_rank+orig. aseg_rank+orig. aparc+aseg_rank+orig.
	for mesh in std.60.${subjName}_rh std.60.${subjName}_lh std.30.${subjName}_rh std.30.${subjName}_lh;do
		3dVol2Surf -spec ../SUMA/$mesh.spec -surf_A smoothwm -surf_B pial -sv anat_Alnd_exp+orig.HEAD -grid_parent vol4surf.concat_bpss_${ID}.nii.gz -map_func ave -f_steps 10 -f_index nodes -f_p1_fr -0.1 -f_pn_fr 0.1 -skip_col_nodes -skip_col_1dindex -skip_col_i -skip_col_j -skip_col_k -skip_col_vals -no_headers -out_1D ${mesh}.concat_bpss_${ID}.1D.dset
		SurfSmooth -met HEAT_07 -input ${mesh}.concat_bpss_${ID}.1D.dset -fwhm 10 -output $mesh.concat_SurfSmooth10mm_bpss_${ID}.1D.dset -spec ../SUMA/$mesh.spec
		mv $mesh.concat_SurfSmooth10mm_bpss_${ID}.1D.dset ../
	done
	####Extract non-cortical values from volume in organized way
	3dresample -master vol4surf.concat_bpss_${ID}.nii.gz -inset aseg_rank_Alnd_Exp+orig.HEAD -prefix aseg_rank_Alnd_resamp.nii
	3dcalc -a aseg_rank_Alnd_resamp.nii -b $regMask -expr '(ispositive(equals(a,28))*a+ispositive(equals(a,8))*a+ispositive(equals(a,29))*a+ispositive(equals(a,9))*a+ispositive(equals(a,27))*a+ispositive(equals(a,7))*a+ispositive(equals(a,30))*a+ispositive(equals(a,10))*a+ispositive(equals(a,7))*a+ispositive(equals(a,13))*a+ispositive(equals(a,26))*a+ispositive(equals(a,6))*a+ispositive(equals(a,15))*a+ispositive(equals(a,14))*a+ispositive(equals(a,31))*a+ispositive(equals(a,32))*a)*b' -prefix volumeForSurfAnalysesMask.nii
	3dcalc -b vol4surf.concat_bpss_${ID}.nii.gz -a volumeForSurfAnalysesMask.nii -expr '(ispositive(a))*b' -prefix volData.NonCortival.concat_bpss_${ID}.nii
	3dBlurInMask -input volData.NonCortival.concat_bpss_${ID}.nii -FWHM $smooth -mask volumeForSurfAnalysesMask.nii -prefix volData.NonCortical.concat_blurat${smooth}mm_bpss_${ID}.nii #should I use Mmask option to only blur in distinct anatomical regions
	mv volData.NonCortical.concat_blurat${smooth}mm_bpss_${ID}.nii ../
fi

#######################################################
#command to run if malloc error occurs
#cen=$(paste -d " " tmp_cen_*);3dTproject -input ../Wrest*.nii.gz -prefix concat_blurat${smooth}mm_bpss_${ID}.nii.gz -ort allRegressors.1D -polort 1 -mask $regMask -bandpass 0.008 0.10 -blur $smooth -CENSORTR $cen;3dTproject -input ../Wrest*.nii.gz -prefix concat_RAW_blurat${smooth}mm.nii.gz -mask $regMask -blur $smooth


####Cleanup
if [[ $tempFiles == F ]];then
	rm rest* Decon*.nii.gz tmp* 0 art* c[123]*.nii.gz Wanat.nii.gz
else
	echo "keeping Files"
fi
else
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!Already ran this type of preprocessing!!!!!!!!!!!!!!!!!!!!!!"
fi
fi
