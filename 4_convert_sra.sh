#!/bin/bash
#SBATCH --job-name=sra_to_fastq_convert
#SBATCH --output=fastq_%A_%a.out
#SBATCH --error=fastq_%A_%a.err
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --array=1-300   # Defined by 3_submit_array.sh

# Load user configuration
source run_config.sh

# Exit on error
set -euo pipefail

# Load SRA Toolkit module
module load "$SRA_MODULE"

# Get SRR ID for array index
SRR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$ACCESSION_FILE")
# Check SRR directory exists
mkdir -p "$SRR"
# Create log file inside SRR directory
LOGFILE="${SRR}/${SRR}_conversion.log"
# Redirect .out/.err logs to LOGFILE
exec >"$LOGFILE" 2>&1

echo
echo "RUNNING 4_convert_sra.sh..."
echo "  Array task: $SLURM_ARRAY_TASK_ID"
echo "  SRR: $SRR"
echo

# Define path to sra file
SRA_PATH="${SRR}/${SRR}.sra"

# Error if not found
if [[ ! -f "$SRA_PATH" ]]; then
    echo "  ERROR: SRA file not found: $SRA_PATH"
    exit 1
fi

# Navigate to directory
cd "$SRR"

echo "  Converting $SRR to FASTQ"
fasterq-dump "${SRR}.sra" --split-files --threads "$THREADS"
echo "  Compressing FASTQ files"
gzip *.fastq

echo
echo "4_convert_sra.sh COMPLETE"