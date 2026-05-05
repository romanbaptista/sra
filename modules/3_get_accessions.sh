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
# Source EDirect environment
source "${PIPELINE_DIR}/env/edirect.env"
# Source functions
source "${UTILS_DIR}/functions.sh"

######################### PATHS ##########################

# Define directory paths
OUTPUT_DIR="${PIPELINE_DIR}/output/3_get_accessions"

# Define directory array
DIRECTORIES=(
    "${OUTPUT_DIR}"
)

# Create directories
for DIR in "${DIRECTORIES[@]}"; do
    mkdir -p "${DIR}"
done

# Define file paths
ENV_FILE="${PIPELINE_DIR}/env/edirect.env"
UID_FILE="${OUTPUT_DIR}/biosample_uids.txt"
METADATA_FILE="${OUTPUT_DIR}/biosample_docsum.xml"
SAMN_FILE="${OUTPUT_DIR}/biosample_samn_accessions.txt"
SRR_FILE="${OUTPUT_DIR}/biosample_srr_accessions.txt"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 3_get_accessions.sh ..."

echo 
echo "  Checking for BioProject ID..."

check_variable BIOPROJECT || {
    echo "  Please provide valid BioProject ID in config.sh"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for EDirect environment file..."

check_file "${ENV_FILE}" || {
    echo "  EDirect environment not found, please run 1_install_edirect.sh"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for required EDirect commands..."

COMMANDS=(
    esearch
    elink
    efetch
    xtract
)

for cmd in "${COMMANDS[@]}"; do
    check_command "${cmd}" || {
        echo "  Required EDirect command not found in PATH"
        echo "  Ensure EDirect is installed and its environment is sourced"
        echo "  Exiting..."
        exit 1
    }
done

echo
echo "  Checking for awk..."

check_command awk || {
    echo "  Please ensure required dependencies are installed"
    echo "  Exiting..."
    exit 1
}

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 3_get_accessions.sh ..."

echo
echo "  Info:"
echo "      BioProject ID:      ${BIOPROJECT}"
echo "      Output directory:   '${OUTPUT_DIR}'"

echo
echo "  Getting UIDs..."

# Get UIDs
esearch -db bioproject -query "${BIOPROJECT}" \
    | elink -target biosample \
    | efetch -format uid \
    > "${UID_FILE}"

# Get number of UIDs
UID_COUNT=$(wc -l < "${UID_FILE}")

# Check for UIDs
if [[ "${UID_COUNT}" -eq 0 ]]; then
    echo "  ERROR: No BioSample UIDs found for BioProject ID ${BIOPROJECT}"
    echo "  Either BioProject ID is incorrect or contains no BioSamples"
    echo "  Exiting..."
    exit 1
else
    echo "  UIDs found: ${UID_COUNT}"
    echo "  UIDs saved to '${UID_FILE}'"
fi

echo
echo "  Getting XML metadata..."

# Get UID metadata
efetch -db biosample -format docsum \
    < "${UID_FILE}" \
    > "${METADATA_FILE}"

echo "  XML metadata found"
echo "  Metadata saved to '${METADATA_FILE}'"

echo
echo "  Getting SAMN accession IDs..."

# Get SAMN IDs
cat "${METADATA_FILE}" \
  | xtract -pattern DocumentSummary -element Accession \
  > "${SAMN_FILE}"

# Get number of SAMN IDs
SAMN_COUNT=$(wc -l < "${SAMN_FILE}")

echo "  SAMN accessions found: ${SAMN_COUNT}"
echo "  SAMN accessions saved to '${SAMN_FILE}'"

echo
echo "  Getting SRR accessions..."

# Get SRR accessions
esearch -db bioproject -query "${BIOPROJECT}" \
 | elink -target sra \
 | efetch -format runinfo \
 | awk -F',' 'NR>1 {print $1}' \
 > "${SRR_FILE}"

# Format line endings
sed -i 's/\r$//' "${SRR_FILE}"

# Get number of SRR accessions
SRR_COUNT=$(wc -l < "${SRR_FILE}")

echo "  SRR accessions found: ${SRR_COUNT} "
echo "  SRR accessions saved to '${SRR_FILE}'"

echo
echo "3_get_accessions.sh COMPLETE"
echo