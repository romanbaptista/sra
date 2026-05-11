#!/bin/bash
set -euo pipefail

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### PATHS ###########################

# Define directory paths
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source scripts
source "${UTILS_DIR}/functions_base.sh"
source "${PIPELINE_DIR}/config.sh"

######################### OUTPUT ##########################

# Create output directory
OUTPUT_DIR="${PIPELINE_DIR}/output/1_get_accessions"
mkdir -p "${OUTPUT_DIR}"

# Define file paths
UID_FILE="${OUTPUT_DIR}/biosample_uids.txt"
METADATA_FILE="${OUTPUT_DIR}/biosample_docsum.xml"
SAMN_FILE="${OUTPUT_DIR}/biosample_samn_accessions.txt"
SRR_FILE="${OUTPUT_DIR}/biosample_srr_accessions.txt"

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Info:"
echo "      BioProject ID:      ${BIOPROJECT}"
echo "      Output directory:   ${OUTPUT_DIR}"

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
    fail "  ERROR: No BioSample UIDs found for given BioProject ID: ${BIOPROJECT}"
else
    echo "  UIDs found: ${UID_COUNT}"
    echo "  UIDs saved to '${UID_FILE}'"
fi

echo "  Getting XML metadata..."

# Get UID metadata
efetch -db biosample -format docsum \
    < "${UID_FILE}" \
    > "${METADATA_FILE}"

echo "  XML metadata found"
echo "  Metadata saved to '${METADATA_FILE}'"
echo "  Getting SAMN accession IDs..."

# Get SAMN IDs
cat "${METADATA_FILE}" \
  | xtract -pattern DocumentSummary -element Accession \
  > "${SAMN_FILE}"

# Get number of SAMN IDs
SAMN_COUNT=$(wc -l < "${SAMN_FILE}")

echo "  SAMN accessions found: ${SAMN_COUNT}"
echo "  SAMN accessions saved to '${SAMN_FILE}'"
echo "  Getting SRR accessions..."

# Get SRR accessions
esearch -db bioproject -query "${BIOPROJECT}" \
 | elink -target sra \
 | efetch -format runinfo \
 | awk -F',' 'NR>1 {print $1}' \
 > "${SRR_FILE}"

# Format line endings
sed -i 's/\r$//' "${SRR_FILE}"

# Check SRR file
check_file "${SRR_FILE}" || fail "  Accession file not created: ${SRR_FILE}"
check_file_data "${SRR_FILE}" || fail "  Accession file contains no data: ${SRR_FILE}"

# Get number of SRR accessions
SRR_COUNT=$(wc -l < "${SRR_FILE}")

echo "  SRR accessions found: ${SRR_COUNT} "
echo "  SRR accessions saved to '${SRR_FILE}'"

echo
echo "${SCRIPT_NAME} COMPLETE"
echo