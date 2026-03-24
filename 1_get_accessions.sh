#!/bin/bash

# Load user configuration
source run_config.sh

# Stop if BIOPROJECT is empty
if [[ -z "$BIOPROJECT" ]]; then
    echo "ERROR: BioProject ID not provided. Please edit the script and set a valid BioProject ID."
    exit 1
fi

# Stop if EDirect not installed
if ! command -v esearch >/dev/null 2>&1; then
    echo "ERROR: EDirect not installed. Run 0_install_packages.sh first."
    exit 1
fi

echo
echo "RUNNING 1_get_accessions.sh..."
echo
echo "  Extracting UIDs for BioProject ID ${BIOPROJECT}"

# Extract UIDs
esearch -db bioproject -query "${BIOPROJECT}" \
  | elink -target biosample \
  | efetch -format uid \
  > biosample_uids.txt

# Get number of UIDs
COUNT_UID=$(wc -l <biosample_uids.txt)

echo "  $COUNT_UID UIDs extracted"
echo "  UIDs saved to 'biosample_uids.txt'"

# Stop if no UIDs were found
if [[ "$COUNT_UID" -eq 0 ]]; then
    echo "ERROR: No BioSample UIDs found for BioProject $BIOPROJECT"
    echo "This usually means the BioProject ID is incorrect or contains no BioSamples."
    exit 1
fi

echo "  Extracting XML metadata"

# Get UID metadata
efetch -db biosample -format docsum < biosample_uids.txt > biosample_docsum.xml

echo "  Metadata saved to 'biosample_docsum.xml'"
echo "  Extracting SAMN accession IDs"

# Get SAMN IDs
cat biosample_docsum.xml \
  | xtract -pattern DocumentSummary -element Accession \
  > biosample_samn_accessions.txt

# Get number of SAMN IDs
COUNT_SAMN=$(wc -l <biosample_samn_accessions.txt)

echo "  $COUNT_SAMN SAMN IDs extracted"
echo "  SAMN IDs saved to 'biosample_samn_accessions.txt'"
echo "  Extracting SRR accession IDs"

# Get SRR run accessions from BioProject
esearch -db bioproject -query "$BIOPROJECT" \
  | elink -target sra \
  | efetch -format runinfo \
  | awk -F',' 'NR>1 {print $1}' \
  > biosample_srr_accessions.txt

# Format line endings
dos2unix biosample_srr_accessions.txt

# Get number of SRR IDs
COUNT_SRR=$(wc -l <biosample_srr_accessions.txt)

echo "  $COUNT_SRR SRR IDs extracted"
echo "  SRR accessions saved to 'biosample_srr_accessions.txt'"

echo
echo "1_get_accessions.sh COMPLETE"
echo