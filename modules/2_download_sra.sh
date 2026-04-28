#!/bin/bash

# Exit on error
set -euo pipefail

######################### DIRECTORIES ####################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Define INPUT directory path
INPUT_DIR="${PIPELINE_DIR}/output/1_get_accessions"
# Define accession file path
ACCESSION_FILE="${INPUT_DIR}/biosample_srr_accessions.txt"
# Define OUTPUT directory path
OUTPUT_DIR="${PIPELINE_DIR}/output/2_download_sra"
# Create output directory
mkdir -p "${OUTPUT_DIR}"

######################### CONFIG #########################

# Load user configuration
source "${PIPELINE_DIR}/config.sh"

######################### CHECKS #########################

# Check if accession file exists
if [[ ! -f "${ACCESSION_FILE}" ]]; then
    echo "ERROR: Accession file not found: ${ACCESSION_FILE}"
    exit 1
fi

######################### VARIABLES ######################

# Get number of SRR IDs (non-empty lines)
NUM_IDS=$(grep -cve '^\s*$' "${ACCESSION_FILE}")
# Initialise count
COUNT=0

######################### SCRIPT #########################

echo
echo "RUNNING 2_download_sra.sh..."
echo
echo "  Input file: ${ACCESSION_FILE}"
echo "  Output directory: ${OUTPUT_DIR}"
echo "  Number of SRR IDs: ${NUM_IDS}"

# Iterate through IDs
while read -r SRR; do

    # Check for empty line and continue if found
    [[ -z "${SRR}" ]] && continue

    # Iterate count
    COUNT=$((COUNT+1))

    echo "  [${COUNT} / ${NUM_IDS}] $(date '+%Y-%m-%d %H:%M:%S') Processing ${SRR}"

    # Create directory for SRR ID
    SRR_DIR="${OUTPUT_DIR}/${SRR}"
    mkdir -p "${SRR_DIR}"

    # # Navigate to directory
    # cd "${SRR}"

    # Localise SRA config
    export VDB_CONFIG="${SRR_DIR}/.vdb-config"
    vdb-config --set /repository/user/main/public/root="${SRR_DIR}"

    # Download directly into SRR directory
    prefetch \
        --transport https \
        --output-directory "${SRR_DIR}" "${SRR}" \
        || { echo "prefetch failed for ${SRR}"; exit 1; }

    # # Return to parent directory
    # cd ..

done < "${ACCESSION_FILE}"

echo
echo "2_download_sra.sh COMPLETE"
echo