#!/bin/bash

export FSLDIR=/usr/local/fsl/5.0.11-2

if [ "${6}" == "" ];then
    echo "The script will create the babyText.txt file needed to run the dMRI pipeline possible"
    echo ""
    echo "usage: gen_babytest2.sh <bvals_P> <bvecs_P> <vols_P> <vols_A> <outputdir> <subject id>"
    echo ""
    echo "       bvals_P: b-values for the blip up volumes"
    echo "       bvecs_P: b-vectors for the blip up volumes"
    echo "       pe_P: phase encoding direction for the blip up volumes (1: LR, 2: RL, 3: AP, 4: PA)"
    echo "       pe_A: phase encoding direction for the blip down volumes (0 if not acquired, 1: LR, 2: RL, 3: AP, 4: PA)"
    echo "       ro_P: total readout time (in seconds) for the blip up volumes"
    echo "       ro_A: total readout time (in seconds) for the blip up volumes (0 if not acquired)"
    echo "       vols_P: blip up volumes"
    echo "       vols_A: blip down volumes"
    echo "       output: output basename"
    echo ""
    exit 1
fi


bvals_P=$1 
bvecs_P=$2
vol_P=$3
vol_A=$4
out=$5
subid=$6
pe_P=4
pe_A=3
ro_P=0.086
ro_A=0.086


rm ${out}/babyTest.txt
echo "old baby text file removed"

#making a directory to save original data
mkdir ${out}/origDTI

# Import bvals
if [ -e ${bvals_P} ]; then
    bvals=(`cat ${bvals_P}`)
else
    echo "ERROR! bvals_up file does not exist!"
    exit 1
fi
# Import bvecs
if [ -e ${bvecs_P} ]; then
    ii=0
    while read line; do
	#echo ${line}
	tmp=(${line})
	if [ ${ii} -eq 0 ]; then
	    bvecs_x=("${tmp[@]}")
	elif [ ${ii} -eq 1 ]; then
	    bvecs_y=("${tmp[@]}")
	elif [ ${ii} -eq 2 ]; then
	    bvecs_z=("${tmp[@]}")
	fi
	ii=$((${ii} + 1))
    done < ${bvecs_P}
else
    echo "ERROR! bvecs_up file does not exist!"
    exit 1
fi

# Start writing protocol file
ii=0
for b in "${bvals[@]}"; do
if [ ${b} -ge 0 ]; then
    echo "${bvecs_x[ii]} ${bvecs_y[ii]} ${bvecs_z[ii]} ${b} ${pe_P} ${ro_P}" >> ${out}/babyTest.txt
fi
	ii=$((${ii} + 1))
done

#concatinating to babytext file
#ii=0
if [[ -e ${vol_A} ]];then
	echo "0 0 0 0 3 0.086" >> ${out}/babyTest.txt
else
echo "error check B0_A file"
exit 1
fi

#Now creating the new P files for further processing
dimt4b=`${FSLDIR}/bin/fslval ${vol_A} dim4`
if [[ ${dimt4b[@]} -eq 4 ]]; then
	mv ${vol_A} ${out}/origDTI/
	${FSLDIR}/bin/fslsplit ${out}/origDTI/sub_${subid}_DTI_B800_B0_A.nii ${out}/origDTI/sub_${subid}_B0_A_ -t
	cp ${out}/origDTI/sub_${subid}_B0_A_0001.* ${out}/sub_${subid}_DTI_B800_B0_A.nii.gz
	vol_A=${out}/sub_${subid}_DTI_B800_B0_A.nii.gz
else
	echo "you have 1B0 only"
fi

mv ${vol_P} ${out}/origDTI
echo "original copy of the p file is saved in the origDTI folder"
${FSLDIR}/bin/fslmerge -t ${out}/sub_${subid}_DTI_B800_P ${out}/origDTI/sub_${subid}_DTI_B800_P.nii ${vol_A}

echo "unziping .nii.gz file to match the format"
gunzip ${out}/sub_${subid}_DTI_B800_P.nii.gz


