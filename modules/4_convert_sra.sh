#!/bin/bash
#SBATCH --job-name=4_convert_sra
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

# Exit on error
set -euo pipefail

######################### DIRECTORIES ####################

# Navigate to PIPELINE_DIR
cd "${PIPELINE_DIR}"
# Define INPUT directory path
INPUT_DIR="${PIPELINE_DIR}/output/2_download_sra"
# Define accession file path
ACCESSION_FILE="${PIPELINE_DIR}/output/1_get_accessions/biosample_srr_accessions.txt"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/4_convert_sra"
# Create OUTPUT directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS #########################

# Check for accession file
if [[ ! -f "${ACCESSION_FILE}" ]]; then
    echo "ERROR: Accession file not found: ${ACCESSION_FILE}"
    exit 1
fi

# Get SRR ID for array index
SRR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${ACCESSION_FILE}")

# Check for empty SRR ID
if [[ -z "${SRR}" ]]; then
    echo "  ERROR: No SRR found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

# Define path to sra file
SRA_PATH="${INPUT_DIR}/${SRR}/${SRR}.sra"

# Error if not found
if [[ ! -f "${SRA_PATH}" ]]; then
    echo "  ERROR: SRA file not found: ${SRA_PATH}"
    exit 1
fi

# Define SRR output directory path
SRR_DIR="${OUTPUT_DIR}/${SRR}"
# Create SRR output directory
mkdir -p "${SRR_DIR}"

# Create log file inside SRR directory
LOGFILE="${SRR_DIR}/${SRR}_conversion.log"
# Redirect .out/.err logs to LOGFILE
exec >"${LOGFILE}" 2>&1

######################### SCRIPT #########################

echo
echo "RUNNING 4_convert_sra.sh..."
echo
echo "  Array task: ${SLURM_ARRAY_TASK_ID}"
echo "  CPUs allocated per task:        ${SLURM_CPUS_PER_TASK}"
echo "  Memory per CPU:                 ${SLURM_MEM_PER_CPU}"
echo "  SRR: ${SRR}"
echo
echo "  Converting ${SRR} to FASTQ"

fasterq-dump \
    "${SRA_PATH}" \
    --split-files \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --outdir "${SRR_DIR}"

echo "  Compressing FASTQ files"

# Compress and delete uncompressed files
gzip -f "${SRR_DIR}"/*.fastq

echo
echo "4_convert_sra.sh COMPLETE"
echo