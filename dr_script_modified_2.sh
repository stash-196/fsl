#!/bin/bash

gica_dir=/mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Dual_regression/                                                                                                                                         
                                         
# textfile containing the list of individual resting state functional data in standard space 
# Each file directory+filename is in each line /directory/individual_preprocessed_fMRI_RS_std.nii.gz                                                                                                                                                          
# inputlist=/mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Dual_regression/files_path.txt          

subj=(032304)                                                                                            
                                                                                                                                                           
# create directory for output                                                                                                                                                           
mkdir -p /mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Dual_regression/before_randomize/drA_masks

output_dir=/mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Dual_regression/before_randomize

# directory of dual regression output before permutation                                                                           
dr_dir="/mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Dual_regression/before_randomize" 
data_dir=/mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Lemon_mri


################### drA ######################
# create mask
echo "starting drA..."
for a in ${subj} ;do
        #read individual_preprocessed_fMRI_RS_std.nii.gz from the text file
        #each file name contains participant's ID. Extract the ID from the text file
        inputfunc="${data_dir}/sub-${subj}_ses-01_task-rest_acq-AP_run-01_MNI2mm.nii" #modify according to your direcotry/file naming
        outputimage="${output_dir}/drA_masks/mask_${a}.nii.gz"
        fslmaths ${inputfunc} -Tstd -bin ${outputimage} -odt char	               
echo "drA ${a} is done."
done

echo "drA is done"

################### drB ######################
# timeseries

mkdir ${dr_dir}/drB_timeseries
outdir="${dr_dir}/drB_timeseries"

cd ${dr_dir}/drA_masks/
fslmerge -t ${outdir}/maskALL.nii.gz `ls ${dr_dir}/drA_masks/mask_*.nii.gz`

fslmaths ${outdir}/maskALL.nii.gz -Tmin ${outdir}/mask.nii.gz

imrm ${dr_dir}/drA_masks/mask_*

echo "drB is done"

################### drC ######################
#get timeseries and spatial maps for each indivisual each condition

echo "beggining drC"

mkdir ${dr_dir}/drC_stage1/
mkdir ${dr_dir}/drC_stage2/

echo "Folders created for drC"

template_dir=/mnt/c/Users/jsd19/Dropbox/OIST_internship/fMRI_analysis/Dual_regression #point to HCP map for instance


for a in ${subj} ;do
        inputimage="${data_dir}/sub-${subj}_ses-01_task-rest_acq-AP_run-01_MNI2mm.nii"
        des="${template_dir}/melodic_IC_sum.nii"

        echo "past the input image and ICA components for ${a}"

        outimage_st1="${dr_dir}/drC_stage1/drC_stage1_${subj}_${a}.txt" #this is what we need for tSNE
        maskimage="${dr_dir}/drB_timeseries/mask.nii.gz"
        outimage_st2="${dr_dir}/drC_stage2/drC_stage2_${subj}_${a}"
        zmapout="${dr_dir}/drC_stage2/drC_stage2_${subj}_${a}_Z.nii.gz"
        icmapout="${dr_dir}/drC_stage2/drC_stage2_${subj}_${a}_ic"

        echo "output files created for ${a}"

        #get timeseries using the groupIC map
        fsl_glm -i ${inputimage} -d ${des} -o ${outimage_st1} --demean -m ${maskimage}

        echo "time series created for ${a}"

        #spatial map calculations
        fsl_glm -i ${inputimage} -d ${outimage_st1} -o ${outimage_st2} --out_z=${zmapout} --demean -m ${maskimage} --des_norm

        echo "spatial map calculations done for ${a}"

        #split for each components
        fslsplit ${outimage_st2} ${icmapout}
	echo "drC ${a} ${sub} is done"
        
        echo "${a} is done for all subjects! :D"
done