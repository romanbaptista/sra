#!/bin/bash

# Load user configuration
source run_config.sh

# Exit on error
set -euo pipefail

# Check if accession file exists
if [[ ! -f "$ACCESSION_FILE" ]]; then
    echo "ERROR: Accession file not found: $ACCESSION_FILE"
    exit 1
fi

# Get number of SRR IDs (non-empty lines)
NUM_IDS=$(grep -cve '^\s*$' "$ACCESSION_FILE")
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

    # SRA download (HTTPS enabled)
    prefetch --transport https "$SRR" || { echo "prefetch failed for $SRR"; exit 1; }

    # Return to parent directory
    cd ..

done < "$ACCESSION_FILE"

echo
echo "2_download_sra.sh COMPLETE"
echo