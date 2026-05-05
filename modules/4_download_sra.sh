#!/usr/bin/env bash
set -euo pipefail

######################### SETUP ###########################

# Define pipeline root directory
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source SRA Toolkit environment
source "${PIPELINE_DIR}/env/sratoolkit.env"
# Source functions
source "${UTILS_DIR}/functions.sh"

######################### PATHS ##########################

# Define directory paths
INPUT_DIR="${PIPELINE_DIR}/output/3_get_accessions"
OUTPUT_DIR="${PIPELINE_DIR}/output/4_download_sra"

# Define directory array
DIRECTORIES=(
    "${OUTPUT_DIR}"
)

# Create directories
for DIR in "${DIRECTORIES[@]}"; do
    mkdir -p "${DIR}"
done

# Define file paths
ACCESSION_FILE="${INPUT_DIR}/biosample_srr_accessions.txt"
ENV_FILE="${PIPELINE_DIR}/env/sratoolkit.env"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 4_download_sra.sh ..."

echo
echo "  Checking for SRA Toolkit environment file..."

check_file "${ENV_FILE}" || {
    echo "  Environment file required, run 2_install_sratoolkit.sh"
    echo "  Exiting..."
    exit 1
}

echo 
echo "  Checking for SRA Toolkit commands..."

COMMANDS=(
    prefetch
    vdb-config
)

for cmd in "${COMMANDS[@]}"; do
    check_command "${cmd}" || {
        echo "  Command required to download SRA files; run 2_install_sratoolkit.sh"
        echo "  Exiting..."
        exit 1
    }
done 

echo 
echo "  Checking for accessions file..."

check_file "${ACCESSION_FILE}" || {
    echo "  Accession file not created by 3_get_accessions.sh"
    echo "  Exiting..."
    exit 1
}

# Get number of accessions
SRR_COUNT=$(wc -l < "${ACCESSION_FILE}")

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 4_download_sra.sh ..."

echo
echo "  Info:"
echo "      Accession file:             '${ACCESSION_FILE}'"
echo "      Number of accessions:       ${SRR_COUNT}"
echo "      Output directory:           '${OUTPUT_DIR}'"

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
    VDB_CONFIG="${SRR_DIR}/.vdb-config"
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
echo "4_download_sra.sh COMPLETE"
echo