#!/bin/bash
#SBATCH --job-name=sra_to_fastq_convert
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

# Load user configuration
source run_config.sh

# Exit on error
set -euo pipefail

# Get SRR ID for array index
SRR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$ACCESSION_FILE")

# Check for empty SRR ID
if [[ -z "$SRR" ]]; then
    echo "  ERROR: No SRR found for SLURM_ARRAY_TASK_ID=$SLURM_ARRAY_TASK_ID"
    exit 1
fi

# Check SRR directory exists
mkdir -p "$SRR"

# Define path to sra file
SRA_PATH="${SRR}/${SRR}.sra"

# Error if not found
if [[ ! -f "$SRA_PATH" ]]; then
    echo "  ERROR: SRA file not found: $SRA_PATH"
    exit 1
fi

# Create log file inside SRR directory
LOGFILE="${SRR}/${SRR}_conversion.log"
# Redirect .out/.err logs to LOGFILE
exec >"$LOGFILE" 2>&1

echo
echo "RUNNING 4_convert_sra.sh..."
echo
echo "  Array task: $SLURM_ARRAY_TASK_ID"
echo "  SRR: $SRR"
echo

# Navigate to directory
cd "$SRR"

echo "  Converting $SRR to FASTQ"
fasterq-dump "${SRR}.sra" --split-files --threads "$THREADS"
echo "  Compressing FASTQ files"
# Compress and delete uncompressed files
gzip -f *.fastq

echo
echo "4_convert_sra.sh COMPLETE"