#!/bin/bash

gica_dir = /Users/tomonagasutashu/workspace/ECSU/codes/dr_script.sh

#textfile containing the list of individual resting state functional data in standard space 
#Each file directory+filename is in each line /directory/individual_preprocessed_fMRI_RS_std.nii.gz                                                                                                                                                          
inputlist=/mydirectory/list_of_ind_RS.txt          

condition = "before during after"                                                                                            


#create directory for output                                                                                                                                                           
mkdir -p /mydirectory/dual_regression/before_randomise/drA_masks 

#directory of dual regression output before permutation                                                                           
dr_dir="/mydirecotry/dual_regression/before_randomise" 


################### drA ######################
# create mask
echo "starting drA..."
for a in ${condition} ;do
        grep ${a} ${inputlist} | while read -r inputfile ;do
                #read individual_preprocessed_fMRI_RS_std.nii.gz from the text file
                #each file name contains participant's ID. Extract the ID from the text file
                sub=`echo ${inputfile} | sed -e "s/^\/home.*participants\/\(S0..._...\)\/nifti.*$/\1/g"` #modify according to your direcotry/file naming
                outputimage="${dr_dir}/drA_masks/mask_${a}_${sub}.nii.gz"
                fslmaths ${inputfile} -Tstd -bin ${outputimage} -odt char
		echo "drA ${sub} is done"       
done
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

mkdir ${dr_dir}/drC_stage1/
mkdir ${dr_dir}/drC_stage2/

template_dir=/directory/to/your_groupIC_map #point to HCP map for instance


for a in ${condition} ;do
        grep ${a} ${inputlist} | while read -r inputimage ;do
                sub=`echo ${inputimage} | sed -e "s/^\/home.*participants\/\(S0..._...\)\/nifti.*$/\1/g"` #modify according to your direcotry/file naming
                
                #check how the group ica folder/files are named 
        
                if [[ ${template} = *.gica ]]
                        then
                        des="${template_dir}/melodic_IC.nii.gz"
                else
                        des="${template_dir}/*.nii.gz"
                fi

                outimage_st1="${dr_dir}/drC_stage1/drC_stage1_${sub}_${a}.txt" #this is what we need for tSNE
                maskimage="${dr_dir}/drB_timeseries/mask.nii.gz"
                outimage_st2="${dr_dir}/drC_stage2/drC_stage2_${sub}_${a}"
                zmapout="${dr_dir}/drC_stage2/drC_stage2_${sub}_${a}_Z.nii.gz"
                icmapout="${dr_dir}/drC_stage2/drC_stage2_${sub}_${a}_ic"

                #get timeseries using the groupIC map
                fsl_glm -i ${inputimage} -d ${des} -o ${outimage_st1} --demean -m ${maskimage}

                #spatial map calculations
                fsl_glm -i ${inputimage} -d ${outimage_st1} -o ${outimage_st2} --out_z=${zmapout} --demean -m ${maskimage} --des_norm

                #split for each components
                fslsplit ${outimage_st2} ${icmapout}
		echo "drC ${a} ${sub} is done"
        done
        echo "${a} is done for all subjects! :D"
done



