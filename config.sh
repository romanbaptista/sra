#!/bin/bash

######################### 0_INSTALL_PACKAGES.SH ##########

# Local SRA Toolkit installation
export SRATOOLS_DIR="$HOME/sratoolkit.2.10.9-centos_linux64"
export PATH="$SRATOOLS_DIR/bin:$PATH"
# EDirect PATH
export PATH="$HOME/edirect:$PATH"

######################### 1_GET_ACCESSIONS.SH ############

# BioProject ID to query
BIOPROJECT=""

######################### 3_SUBMIT_ARRAY.SH ##############

# Maximum number of concurrent SLURM array jobs
SLURM_MAX_JOBS=20

######################### 4_CONVERT_SRA.SH ###############

# Define number of threads
FASTERQ_CPUS=8
# Define memory per threads
FASTERQ_MEM_PER_CPU=16G