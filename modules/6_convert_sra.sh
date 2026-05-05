#!/usr/bin/env bash
#SBATCH --job-name=6_convert_sra
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null
set -euo pipefail
: "${SLURM_SUBMIT_DIR:?This script must be run via sbatch}"
: "${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID not set}"

######################### SETUP ###########################

# Define pipeline root directory
PIPELINE_DIR="${SLURM_SUBMIT_DIR}"
# Navigate to pipeline root path
cd "${PIPELINE_DIR}"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source SRA toolkit environment
source "${PIPELINE_DIR}/env/sratoolkit.env"
# Source functions
source "${UTILS_DIR}/functions.sh"

######################### PATHS ##########################

# Define directory paths
INPUT_DIR="${PIPELINE_DIR}/output/4_download_sra"
OUTPUT_DIR="${PIPELINE_DIR}/output/6_convert_sra"

# Define directory array
DIRECTORIES=(
    "${OUTPUT_DIR}"
)

# Create directories
for DIR in "${DIRECTORIES[@]}"; do
    mkdir -p "${DIR}"
done

# Define file paths
ACCESSION_FILE="${PIPELINE_DIR}/output/3_get_accessions/biosample_srr_accessions.txt"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 6_convert_sra.sh ..."

echo
echo "  Checking for gzip..."


check_command gzip || {
    echo "  gzip is required to compress FASTQ files"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for fasterq-dump..."

check_command fasterq-dump || {
    echo "  fasterq-dump is required for FASTQ conversion; run 2_install_sratoolkit.sh"
    exit 1
}

echo 
echo "  Checking for input directory..."

check_directory "${INPUT_DIR}" || {
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for accession file..."

check_file "${ACCESSION_FILE}" || {
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for SRR accession..."

# Get SRR ID for array index
SRR="$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${ACCESSION_FILE}" | tr -d '\r' | xargs)"

# Check for empty SRR ID
if [[ -z "${SRR}" ]]; then
    echo "  ERROR: No SRR accession found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
    echo "  Exiting..."
    exit 1
else
    echo "  SRR accession found: ${SRR}"
fi

echo
echo "  Checking for SRA file..."

# Define path to SRA file
SRA_FILE="${INPUT_DIR}/${SRR}/${SRR}.sra"

check_file "${SRA_FILE}" || {
    echo "  Exiting..."
    exit 1
}

echo
echo "  Create sample output directory..."

# Define sample directory
SRR_DIR="${OUTPUT_DIR}/${SRR}"
# Create directory
mkdir -p "${SRR_DIR}"

echo "  Sample directory created"
echo
echo "  Creating sample log..."

# Define sample log path
SAMPLE_LOG="${SRR_DIR}/${SRR}_conversion.log"

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."
echo "Log output will be send to sample directories"

# Redirect all stdout/stderr to per-sample log
exec > >(tee -a "${SAMPLE_LOG}") 2>&1

######################### MAIN ############################

echo
echo "RUNNING 6_convert_sra.sh ..."

echo
echo "  Info:"
echo "      Input directory:            ${INPUT_DIR}"
echo "      Array task ID:              ${SLURM_ARRAY_TASK_ID}"
echo "      CPUs allocated per task:    ${SLURM_CPUS_PER_TASK}"
echo "      Memory per CPU:             ${SLURM_MEM_PER_CPU}"
echo "      SRA to convert:             ${SRR}"
echo "      Output directory:           ${OUTPUT_DIR}"

echo
echo "  Converting ${SRR} to FASTQ"

# Cleanup partial FASTQs on error
trap 'rm -f "${SRR_DIR}"/*.fastq' ERR

# Check if FASTQ files already exist
if compgen -G "${SRR_DIR}/*.fastq.gz" > /dev/null; then
    echo "  FASTQ files already exist; skipping conversion"
    exit 0
fi

# Convert SRA file
fasterq-dump \
    "${SRA_FILE}" \
    --split-files \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --outdir "${SRR_DIR}"

echo "  SRA file converted"
echo
echo "  Compressing FASTQ file..."

# Compress and delete uncompressed files
gzip -f "${SRR_DIR}"/*.fastq

echo "  FASTQ file compressed"

echo
echo "6_convert_sra.sh COMPLETE"
echo