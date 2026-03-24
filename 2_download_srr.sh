#!/bin/bash

# Load SRA Toolkit module
module load sra-tools/2.10.3

# Define accession file
ACCESSION_FILE="accessions_test.txt"
# Get number of SRR IDs
NUM_IDS=$(wc -l < "$ACCESSION_FILE")
# Initialise count
COUNT=0

echo
echo "RUNNING 2_download_srr.sh..."
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

    # Download SRA file
    prefetch "$SRR"

done < "$ACCESSION_FILE"

echo
echo "2_download_srr.sh COMPLETE"
echo


