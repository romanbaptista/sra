#!/bin/bash
set -euo pipefail

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### PATHS ###########################

# Define directory paths
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
UTILS_DIR="${PIPELINE_DIR}/utils"
INPUT_DIR="${PIPELINE_DIR}/output/1_get_accessions"

# Define file paths
ACCESSION_FILE="${INPUT_DIR}/biosample_srr_accessions.txt"

######################### SOURCE ##########################

# Source scripts
source "${UTILS_DIR}/functions_base.sh"
source "${PIPELINE_DIR}/config.sh"

######################### OUTPUT ##########################

# Create output directory
OUTPUT_DIR="${PIPELINE_DIR}/output/2_download_sra"
mkdir -p "${OUTPUT_DIR}"

######################### MAIN ############################

# Get number of non-empty accessions
SRR_COUNT=$(grep -cve '^\s*$' "${ACCESSION_FILE}")

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Info:"
echo "      Accession file:             ${ACCESSION_FILE}"
echo "      Number of accessions:       ${SRR_COUNT}"
echo "      Output directory:           ${OUTPUT_DIR}"

echo
echo "  Downloading SRA files..."

# Initialise count
COUNT=0

# Iterate over accessions
while read -r SRR; do
   
    # Format SRR ID (remove CR, leading/trailing whitespace)
    SRR="$(echo "${SRR}" | tr -d '\r' | xargs)"

    # Skip if empty
    [[ -z "${SRR}" ]] && continue
    
    # Iterate count
    COUNT=$((COUNT+1))

    echo "  [${COUNT} / ${SRR_COUNT}] $(date '+%Y-%m-%d %H:%M:%S') - Processing ${SRR}"

    # Define directory path for accession
    SRR_DIR="${OUTPUT_DIR}/${SRR}"
    # Create directory
    mkdir -p "${SRR_DIR}"

    # Skip if already downloaded    
    [[ -f "${SRR_DIR}/${SRR}.sra" ]] && {
        echo "  ${SRR} already downloaded; skipping..."
        continue
    }

    # Localise SRA config
    VDB_CONFIG="${SRR_DIR}/.vdb-config" \
    vdb-config --set /repository/user/main/public/root="${SRR_DIR}"

    # Download SRA file
    prefetch \
        --transport https \
        --output-directory "${SRR_DIR}" "${SRR}" \
        || {
            echo "  prefetch failed for ${SRR}"
            echo "  Exiting..."
            exit 1
        }

done < "${ACCESSION_FILE}"

echo
echo "  SRA files downloaded"

echo
echo "${SCRIPT_NAME} COMPLETE"
echo