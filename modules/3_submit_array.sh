#!/bin/bash

# Exit on error
set -euo pipefail

######################### DIRECTORIES ####################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Export PIPELINE_DIR to SBATCH
export PIPELINE_DIR
# Define INPUT directory path
INPUT_DIR="${PIPELINE_DIR}/output/2_download_sra"
# Define accession file path
ACCESSION_FILE="${PIPELINE_DIR}/output/1_get_accessions/biosample_srr_accessions.txt"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS #########################

# Check for input directory
if [[ ! -d "${INPUT_DIR}" ]]; then
    echo "ERROR: Input directory not found: ${INPUT_DIR}"
    exit 1
fi

# Check for accession file
if [[ ! -f "${ACCESSION_FILE}" ]]; then
    echo "ERROR: Accession file not found: ${ACCESSION_FILE}"
    exit 1
fi

# Count SRRs (non-empty lines)
NUM_IDS=$(grep -cve '^\s*$' "${ACCESSION_FILE}")


if [[ "${NUM_IDS}" -eq 0 ]]; then
    echo "ERROR: No SRR accessions found in ${ACCESSION_FILE}"
    exit 1
fi

######################### SCRIPT #########################

echo
echo "RUNNING 3_submit_array.sh..."
echo
echo "  Detected ${NUM_IDS} SRR accessions"
echo "  Submitting SLURM array job with ${SLURM_MAX_JOBS} maximum concurrent tasks"
echo "  CPUs allocated per task:        ${FASTERQ_CPUS}"
echo "  Memory per CPU:                 ${FASTERQ_MEM_PER_CPU}"

# Submit array job with maximum concurrent tasks
sbatch \
    --array=1-${NUM_IDS}%${SLURM_MAX_JOBS} \
    --cpus-per-task="${FASTERQ_CPUS}" \
    --mem-per-cpu="${FASTERQ_MEM_PER_CPU}" \
    "${PIPELINE_DIR}/modules/4_convert_sra.sh"

echo
echo "3_submit_array.sh COMPLETE"
echo