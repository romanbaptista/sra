#!/bin/bash

# Exit on error
set -euo pipefail

######################### DIRECTORIES ####################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define MODULES directory path
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output"
# Create OUTPUT directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### SCRIPT #########################

echo
echo "RUNNING BioProject SRA pipeline..."
echo "User configuration from config.sh:"
echo "  BioProject:               $BIOPROJECT"
echo "  Max SLURM Array Jobs:     $MAX_JOBS"
echo "  FASTERQ Threads:          $THREADS"
echo "  SRA-Toolkit:              $SRATOOLS_DIR"
echo

# Install EDirect
bash "${MODULES_DIR}/0_install_packages.sh"

# Get SRR Accessions
bash "${MODULES_DIR}/1_get_accessions.sh"

# Download SRA files
bash "${MODULES_DIR}/2_download_sra.sh"

# Submit SLURM array for SRA -> FASTQ conversion
bash "${MODULES_DIR}/3_submit_array.sh"

echo
echo "  Pipeline submitted successfully"
echo "  FASTQ conversion running on cluster"
echo "  You are free to exit the cluster session if required"
echo