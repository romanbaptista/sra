#!/bin/bash

# BioProject ID to query
BIOPROJECT="PRJNA925215"

# File containing SRR accessions
ACCESSION_FILE="biosample_srr_accessions.txt"
# Maximum number of concurrent SLURM array jobs
MAX_JOBS=20
# Number of threads for fasterq-dump
THREADS=8

# Local SRA Toolkit installation
export SRATOOLS_DIR="$HOME/sratoolkit.2.10.9-centos_linux64"
export PATH="$SRATOOLS_DIR/bin:$PATH"
# EDirect PATH
export PATH="$HOME/edirect:$PATH"