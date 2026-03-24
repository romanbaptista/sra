#!/bin/bash

ACCESSION_FILE="accessions_test.txt"

# Count SRRs
NUM_IDS=$(wc -l < "$ACCESSION_FILE")
# Define max number of jobs
MAX_JOBS=20

echo
echo "RUNNING 3_calculate_array.sh..."
echo "  Detected $NUM_IDS SRR accessions"
echo "  Submitting SLURM array job with $MAX_JOBS maximum concurrent tasks"
echo

# Submit array job with maximum concurrent tasks
sbatch --array=1-$NUM_IDS%$MAX_JOBS 4_convert_sra.sh
