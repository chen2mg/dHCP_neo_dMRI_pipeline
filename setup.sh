#!/bin/bash


echo "\n START: Setting up necessary folders to run the neonatal dMRI pipeline..."


# Folders where data and scripts are 
export scriptsFolder=/mnt/d/dHCP_neo_dMRI_pipeline_release  # neonatal dMRI pipeline scripts
export templateFolder=/mnt/d/dHCP_work/atlas_dhcp
# Neonatal template folder

# dHCP-specific paths
#export reconFolder=/home/xiaom/Documents/dhcp_data          # Raw data
#export structFolder=/home/xiaom/Documents/dhcp_data           # Structural pipeline outupt

export reconFolder=/home/xiaom/Documents/eps_data          # Raw data
export structFolder=/home/xiaom/Documents/eps_data           # Structural pipeline outupt

# Folders where necessary programs are
export IRTKPATH=/home/xiaom/Desktop/repositories/IRTK/build/bin                # IRTK for super-resolution
export ants_scripts=/home/xiaom/Desktop/repositories/ANTs/Scripts                       # ANTS scripts
export ANTSPATH=/opt/ANTs/bin                           # ANTS binaries
export C3DPATH=/home/xiaom/Desktop/repositories/c3d/bin                                        # c3d to converts ANTS to FNIRT warps


echo "\n END: Setup complete"
