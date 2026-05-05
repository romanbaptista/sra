#!/usr/bin/env bash
set -euo pipefail

######################### SETUP ###########################

# Define pipeline root directory
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Define module directory
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source functions
source "${UTILS_DIR}/functions.sh"

######################### PATHS ##########################

# Define directory paths
INPUT_DIR="${PIPELINE_DIR}/output/4_download_sra"

# Define file paths
ACCESSION_FILE="${PIPELINE_DIR}/output/3_get_accessions/biosample_srr_accessions.txt"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 5_submit_array.sh ..."


echo 
echo "  Checking for sbatch command..."

check_command sbatch || {
    echo "  This pipeline requires SLURM"
    echo "  Exiting..."
    exit 1
}

echo 
echo "  Checking for input directory..."

check_directory "${INPUT_DIR}" || {
    echo "  4_download_sra.sh did not correctly generate an output directory"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for accession file..."

check_file "${ACCESSION_FILE}" || {
    echo "  3_get_accessions.sh did not correctly generate SRR accessions"
    echo "  Exiting..."
    exit 1
}

echo
echo "Checking for accession IDs in file..."

# Get non-empty accession count
SRR_COUNT=$(grep -cve '^\s*$' "${ACCESSION_FILE}")

# Check SRR_COUNT is not zero
if [[ "${SRR_COUNT}" -eq 0 ]]; then
    echo "  ERROR: No SRR accessions found in '${ACCESSION_FILE}'"
    echo "  Exiting..."
    exit 1
else
    echo "  Accessions found: ${SRR_COUNT}"
fi

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 5_submit_array.sh ..."

echo
echo "  Info:"
echo "      Input directory:                ${INPUT_DIR}"
echo "      Number of accessions:           ${SRR_COUNT}"
echo "      Maximum concurrent tasks:       ${SLURM_MAX_JOBS}"
echo "      CPUs allocated per task:        ${FASTERQ_CPUS}"
echo "      Memory per CPU:                 ${FASTERQ_MEM_PER_CPU}"

echo
echo "  Submitting SLURM array..."

# Submit SLURM array
sbatch \
    --array=1-${SRR_COUNT}%${SLURM_MAX_JOBS} \
    --cpus-per-task="${FASTERQ_CPUS}" \
    --mem-per-cpu="${FASTERQ_MEM_PER_CPU}" \
    "${MODULES_DIR}/6_convert_sra.sh"

echo "  Array submitted"

echo
echo "5_submit_array.sh COMPLETE"
echo