#!/bin/bash

# Load user configuration
source run_config.sh

# Check if accession file exists
if [[ ! -f "$ACCESSION_FILE" ]]; then
    echo "ERROR: Accession file not found: $ACCESSION_FILE"
    exit 1
fi

# Count SRRs (non-empty lines)
NUM_IDS=$(grep -cve '^\s*$' "$ACCESSION_FILE")

echo
echo "RUNNING 3_submit_array.sh..."
echo
echo "  Detected $NUM_IDS SRR accessions"
echo "  Submitting SLURM array job with $MAX_JOBS maximum concurrent tasks"
echo

# Submit array job with maximum concurrent tasks
sbatch --array=1-$NUM_IDS%$MAX_JOBS 4_convert_sra.sh

echo "3_submit_array.sh COMPLETE"