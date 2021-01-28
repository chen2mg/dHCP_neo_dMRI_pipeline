#!/bin/bash

if [ "${5}" == "" ]; then
  echo "The script will create the babyText.txt file needed to run the dMRI pipeline possible"
  echo ""
  echo "usage: gen_babytest.sh <bvals_P> <bvecs_P> <vol_P> <vol_A> <outputdir>"
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
pe_P=4
pe_A=3
ro_P=0.086
ro_A=0.086


if [ -e ${out}/acqProt.txt ]; then
  rm ${out}/acqProt.txt
  #echo "Old baby text file removed"
fi

# create an empty file
touch ${out}/acqProt.txt

P2A_dimt4=$(${FSLDIR}/bin/fslval ${vol_P} dim4)
A2P_dimt4=$(${FSLDIR}/bin/fslval ${vol_A} dim4)

${FSLDIR}/bin/fslmerge -t ${out}/merged ${vol_A} ${vol_P}

# Import bvals
bvals=($(cat ${bvals_P}))

# Import bvecs
ii=0
while read line; do
  tmp=(${line})
  if [ ${ii} -eq 0 ]; then
    bvecs_x=("${tmp[@]}")
  elif [ ${ii} -eq 1 ]; then
    bvecs_y=("${tmp[@]}")
  elif [ ${ii} -eq 2 ]; then
    bvecs_z=("${tmp[@]}")
  fi
  ii=$((${ii} + 1))
done <${bvecs_P}

# writing protocol from A2P file
for i in $(seq 1 ${A2P_dimt4}); do
  #echo $i;
  echo "0 0 0 0 ${pe_A} ${ro_P}" >>${out}/acqProt.txt
done

# writing protocol from P2A file
for i in $(seq 0 $(($P2A_dimt4-1))); do
  #echo $i "${bvecs_x[i]} ${bvecs_y[i]} ${bvecs_z[i]} ${bvals[i]} ${pe_P} ${ro_P}"
  echo "${bvecs_x[i]} ${bvecs_y[i]} ${bvecs_z[i]} ${bvals[i]} ${pe_P} ${ro_P}" >>${out}/acqProt.txt
done