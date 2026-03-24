#!/bin/bash

# Load user configuration
source run_config.sh

# Exit on error
set -euo pipefail

# Load SRA Toolkit module
#module load "$SRA_MODULE"
#module load sra-tools/2.10.3

# Check if accession file exists
if [[ ! -f "$ACCESSION_FILE" ]]; then
    echo "ERROR: Accession file not found: $ACCESSION_FILE"
    exit 1
fi

# Get number of SRR IDs
NUM_IDS=$(wc -l < "$ACCESSION_FILE")
# Initialise count
COUNT=0

echo
echo "RUNNING 2_download_sra.sh..."
echo "  Input file: $ACCESSION_FILE"
echo "  Number of SRR IDs: $NUM_IDS"
echo

# Iterate through IDs
while read -r SRR; do

    # Check for empty line and continue if found
    [[ -z "$SRR" ]] && continue

    # Iterate count
    COUNT=$((COUNT+1))

    echo "  [$COUNT / $NUM_IDS] $(date '+%Y-%m-%d %H:%M:%S') Processing $SRR"

    # Create directory for SRR ID
    mkdir -p "$SRR"
    # Navigate to directory
    cd "$SRR"

    # Disable SSL certificate verification (fix for old cluster SSL)
    export NCBI_SETTINGS=/dev/null
    export VDB_CONFIG=/dev/null
    
    # Download SRA file using HTTPS transport
    prefetch --type sra --transport https "$SRR" || { echo "prefetch failed for $SRR"; exit 1; }


    # Return to parent directory
    cd ..

done < "$ACCESSION_FILE"

echo
echo "2_download_sra.sh COMPLETE"
echo