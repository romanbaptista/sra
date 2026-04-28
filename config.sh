#!/bin/bash

## 0_INSTALL_PACKAGES.sh

# Local SRA Toolkit installation
export SRATOOLS_DIR="$HOME/sratoolkit.2.10.9-centos_linux64"
export PATH="$SRATOOLS_DIR/bin:$PATH"
# EDirect PATH
export PATH="$HOME/edirect:$PATH"

## 1_GET_ACCESSIONS.sh

# BioProject ID to query
BIOPROJECT="PRJNAXXXXXX"

## 3_SUBMIT_ARRAY.sh

# Maximum number of concurrent SLURM array jobs
MAX_JOBS=20

## 4_CONVERT_SRA.sh

# Number of threads for fasterq-dump
THREADS=8