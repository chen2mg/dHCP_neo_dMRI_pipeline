#!/bin/bash

echo "\n START: dHCP neonatal dMRI data processing pipeline"

if [ "${2}" == "" ]; then
  echo "The script will read dHCP subject info and, if data is there, launch the processing steps"
  echo ""
  echo "usage: dHCP_neo_dMRI_launchPipeline.sh <subject list> <output folder>"
  echo ""
  echo "       subject list: text file containing participant_id, sex and age at birth (w GA)"
  echo "       output folder: folder where results will be stored"
  echo ""
  echo ""
fi

subjList=$1
outFolder=$2

mkdir -p ${outFolder}

# Read the connectome IDs
sids=($(cat ${subjList} | sed "1 d" | cut -f 1 | grep -v "^$"))

# Main loop through subjects
for s in ${sids[@]}; do
  # testing mode
#  if [ ${s} != "sub_140" ]; then
#    continue
#  fi
  # testing mode
  echo "working on: ${s}"

  sex=$(cat ${subjList} | grep ${s} | cut -f 2)
  birth=$(cat ${subjList} | grep ${s} | cut -f 3) # ga (weeks)

  ses=session-1
  age=$(cat ${subjList} | grep ${s} | cut -f 4) # pma (weeks)

  # Round birth and scan ages
  age=$(awk -v v="${age}" 'BEGIN{printf "%.0f", v}')
  birth=$(awk -v v="${birth}" 'BEGIN{printf "%.0f", v}')

  P_A=${reconFolder}/${s}/${ses}/DWI/DTI_B800_P.nii
  b0_A_P=${reconFolder}/${s}/${ses}/DWI/DTI_B800_B0_A.nii
  b_val=${reconFolder}/${s}/${ses}/DWI/DTI_B800_P.bval
  b_vec=${reconFolder}/${s}/${ses}/DWI/DTI_B800_P.bvec
  t2=${structFolder}/${s}/${ses}/anat/T2_brain.nii.gz
  seg=${structFolder}/${s}/${ses}/anat/sub-1_ses-1_drawem_tissue_labels.nii

  echo ''
  echo Check for scan completeness
  echo ============================================================================

  if [ ! -f ${b_val} ]; then
    echo "Error! Missing b_val data for subject ${s} Abort"
    continue
  fi

  if [ ! -f ${b_vec} ]; then
    echo "Error! Missing b_vec data for subject ${s} Abort"
    continue
  fi

  if [ ! -f ${P_A} ]; then # Check that data has been acquired
    echo "Error! Missing dMRI data for subject ${s}"
    echo "${s} ${ses}" >>${outFolder}/missingDmri.txt
    continue
  fi


  if [ -f ${P_A} ]; then
    ${scriptsFolder}/utils/gen_acqProt.sh ${b_val} ${b_vec} ${P_A} ${b0_A_P} ${reconFolder}/${s}/${ses}/DWI
    data=${reconFolder}/${s}/${ses}/DWI/merged.nii.gz
    data_file=merged.nii.gz
  else
    ${scriptsFolder}/utils/gen_acqProt.sh ${b_val} ${b_vec} ${P_A} ${b0_A_P} ${reconFolder}/${s}/${ses}/DWI
    data=${P_A}
    data_file=DTI_B800_P.nii
    echo "WARNING! Missing A2P data for subject ${s}"
  fi
  acqProt=${reconFolder}/${s}/${ses}/DWI/acqProt.txt

  if [ ! -f ${data} ]; then # Check that data has been acquired
    echo "Error! Missing merged data for subject ${s}"
    continue
  fi

  if [ ! -e ${t2} ]; then # Check that structural data has been acquired
    echo "Error! Missing structural data for subject ${s}"
    echo "${s} ${ses}" >>${outFolder}/missingAnat.txt
    continue
  fi

  echo ''
  echo all necessary file acquired
  echo ============================================================================

  dimt4=$(${FSLDIR}/bin/fslval ${data} dim4)
  complete_check=${dimt4}
  usable_check=1
  if [ ${dimt4} -lt 34 ]; then
    echo "Error: The dataset is unusable as it does not contain enough b0 volumes"
    echo "${s} ${ses}" >>${outFolder}/unusable.txt
    usable_check=0
  elif [ ${dimt4} -lt 38 ]; then
    echo "WARNING: The dataset is incomplete and does not contain enough b0 pairs for each PE direction"
    echo "${s} ${ses}" >>${outFolder}/incomplete.txt
    noB0s=1
    usable_check=1
  fi

  echo ''
  echo Store QC information
  echo ============================================================================
  subjOutFolder=${outFolder}/${s}/${ses}
  if [ -e ${subjOutFolder}/initQC.json ]; then
    echo 'exist initQC.json'
    rm ${subjOutFolder}/initQC.json
    echo 'deleted original initQC.json'
  fi
  mkdir -p ${subjOutFolder}
  echo "{" >${subjOutFolder}/initQC.json
  echo "   \"Complete\": ${complete_check}," >>${subjOutFolder}/initQC.json
  echo "   \"Usable\": ${usable_check}," >>${subjOutFolder}/initQC.json
  #echo "   \"nSessions\": ${n_sessions}," >> ${subjOutFolder}/initQC.json
  echo "   \"nSessions\": 1," >>${subjOutFolder}/initQC.json
  echo "   \"birthAge\": ${birth}," >>${subjOutFolder}/initQC.json
  echo "   \"scanAge\": ${age}" >>${subjOutFolder}/initQC.json
  echo "}" >>${subjOutFolder}/initQC.json


  echo ''
  echo Set processing jobs
  echo ============================================================================
  echo 'start job:'
  # "usage: dHCP_neo_dMRI_setJobs.sh <data folder> <session folder> <data file> <connectome ID> \
  # <acquisition protocol> <slspec> <output folder> \
  # <age at scan> <age at birth> <subject T2> <subject segmentation> <superres flag> <gpu flag> <testing flag>"
  ${scriptsFolder}/dHCP_neo_dMRI_setJobs.sh ${reconFolder}/${s} ${ses} ${data_file} ${s} \
    ${acqProt} ${scriptsFolder}/slspec.txt ${outFolder} \
    ${age} ${birth} ${t2} ${seg} 0 0 1

  echo "${s} ${ses} ${birth} ${age}" >>${outFolder}/complete.txt
done

echo "\n END: dHCP neonatal dMRI data processing pipeline"
