#!/bin/tcsh
#Usage:
#norm.func.csh <func_file> <anat_file> <0 to warp func> <template with skull> <template stripped> <template brainmask>
setenv ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS 4
#module load afni/7-Feb-2013-openmp
setenv PATH  /data/SOIN/ANTS:$PATH 
set path = ( /data/SOIN/ANTS $path )

set scriptdir = /data/NIMH_SOIN/elliottml/COBRE_SZ/scripts
if ($#argv < 2) then 
	goto endscript
else if ($#argv == 2) then
	set func = $1
	set anat = $2
	set template_dir = '/data/elliottml/rest10M/templates/'
	set ants_template = $template_dir/T1_combined_ws_td_dupn7template_MNI_1.5.nii
	set ants_strip_template = $template_dir/brain_combined_ws_td_dupn7template_MNI_1.5.nii
	set ants_brainmask = $template_dir/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii
else if ($#argv == 3) then
	set func = $1
	set anat = $2
	set template_dir = '/data/elliottml/rest10M/templates/'
	set ants_template = $template_dir/T1_combined_ws_td_dupn7template_MNI_1.5.nii
	set ants_strip_template = $template_dir/brain_combined_ws_td_dupn7template_MNI_1.5.nii
	set ants_brainmask = $template_dir/brainmask_combined_ws_td_dupn7template_MNI_1.5.nii
else if ($#argv < 5) then
	goto endscript
else
	set func = $1
	set anat = $2
	set ants_template = $3
	set ants_strip_template = $4
	set ants_brainmask = $5
endif

set wfile = `prefix W $anat:r:r`
set mfile = `prefix M $anat:r:r`
set sfile = `prefix strip. $anat`
#set afunc = `prefix A. $func:r:r`
#set astrip = `prefix A. $sfile:r:r`

set strip_syn = 0.25
set strip_cc = 4
set strip_gauss = 50
set strip_res = 50x50x30
set strip_nits = 10000x10000x10000x10000x10000 
set strip_mi = 32x16000

set warp_cc = 4
set warp_gauss = 35
set warp_syn = 0.5
set warp_res = 100x100x100x20
set warp_nits = 10000x10000x10000x10000x10000 
set warp_mi = 32x16000

set func_gauss = 50
set func_syn = 0.25
set func_res = 50x50x30
set func_nits = 10000x10000x10000x10000x10000 
set func_mi = 32x16000



#Skullstrip ANAT
ANTS 3 -m CC\[$ants_template,$anat,1,$strip_cc\] -i $strip_res -o ${mfile}_ -t Syn\[$strip_syn\] -r Gauss\[$strip_gauss,0\]  --number-of-affine-iterations $strip_nits --use-Histogram-Matching --MI-option $strip_mi

WarpImageMultiTransform 3 $ants_brainmask `prefix M $anat` -i ${mfile}_Affine.txt ${mfile}_InverseWarp.nii.gz -R $anat

3dcalc -prefix $sfile -a $anat -b `prefix M $anat` -expr 'a*step(b-0.5)' -overwrite

#determine EPI to ANAT params
#3dresample -master $sfile -prefix tmp_func.nii -inset $func
set anat_res = `@GetAfniRes $anat`
ResampleImageBySpacing 3 $func tmp_func.nii $anat_res

3dcalc -a $sfile -expr a -prefix $sfile:r
set zsfile = $sfile:r
perl -pe "s|<EPI>|tmp_func.nii|;s|<ANAT>|$zsfile|" $scriptdir/spm12sa_coreg.m >! spm12sa_coreg_run.m
spm12sa batch spm12sa_coreg_run.m
3drefit -space ORIG -view orig r$zsfile
rm $zsfile

#Determine affine and warp params
ANTS 3 -m CC\[$ants_strip_template,r$zsfile,1,$warp_cc\] -i $warp_res -o ${wfile}_ -t Syn\[$warp_syn\] -r Gauss\[$warp_gauss,0\] --use-Histogram-Matching  --number-of-affine-iterations $warp_nits  --MI-option $warp_mi
WarpImageMultiTransform 3 r$zsfile $wfile.nii.gz ${wfile}_Warp.nii.gz ${wfile}_Affine.txt -R $ants_strip_template --use-NN
3drefit -space MNI -view tlrc $wfile.nii.gz

set func_res = `@GetAfniRes $func`
ResampleImageBySpacing 3 $ants_strip_template template_${func} $func_res
WarpTimeSeriesImageMultiTransform 4 $func W_$func -R template_${func} ${wfile}_Warp.nii.gz ${wfile}_Affine.txt --use-NN
3drefit -space MNI -view tlrc W_$func

endscript:
echo " "
echo 'norm.func.spm5.csh - written by MDG last modified 10/16/14'
echo " "
echo "Usage: norm.func.csh <functional> <anatomic> <template w/ skull> <template-stripped> <template-mask>"
echo " "
echo "Uses ANTS to skull-strip anatomic, then coregister EPI to anatomic, then warps anatomic to template"
echo " "
echo "Functional, anatomic and template files should be NIFTI images"
echo " "
echo "If you specify templates, you must specify all 3 and specify whether to warp functional."
echo " "
echo "Current default templates on biowulf are: /data/SOIN/templates/T1_dartel_avg_240sagvols_1.5mm_MNI.nii"
