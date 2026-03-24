#!/bin/bash

# Exit on error
set -euo pipefail

# Load user configuration
source run_config.sh

echo
echo "RUNNING BioProject SRA pipeline..."
echo "User configuration from run_config.sh:"
echo "  BioProject:               $BIOPROJECT"
echo "  Accession File:           $ACCESSION_FILE"
echo "  Max SLURM Array Jobs:     $MAX_JOBS"
echo "  FASTERQ Threads:          $THREADS"
echo "  SRA-Toolkit Module:       apps/sra-tools/2.10.3"
echo

# Install EDirect
bash 0_install_edirect.sh

# Get SRR Accessions
bash 1_get_accessions.sh

# Download SRA files
bash 2_download_sra.sh

# Submit SLURM array for SRA -> FASTQ conversion
bash 3_submit_array.sh

echo
echo "  Pipeline submitted successfully"
echo "  FASTQ conversion running on cluster"
echo "  You are free to exit the cluster session if required"
echo