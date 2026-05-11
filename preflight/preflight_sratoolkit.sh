#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${UTILS_DIR:?UTILS_DIR not set (check PATHS section in run_pipeline.sh)}"
: "${ENV_DIR:?ENV_DIR not set (check PATHS section in run_pipeline.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
# Define toolname
TOOLNAME="sratoolkit"

# Define tool parameters
SRA_VERSION="2.10.9"
SRA_ARCHIVE="sratoolkit.${SRA_VERSION}-centos_linux64.tar.gz"
SRA_URL="https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${SRA_VERSION}/${SRA_ARCHIVE}"

######################## SOURCE ##########################

# Source tool-specific functions
source "${UTILS_DIR}/functions_${TOOLNAME}.sh"

######################### PATHS ###########################

# Define tool extract directory path
EXTRACT_DIR="${HOME}/sratoolkit.${SRA_VERSION}-centos_linux64"
# Define environment file path
SRA_ENV="${ENV_DIR}/${TOOLNAME}.env"

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for ${TOOLNAME}-specific user-defined variables..."

# Define config variables
VARIABLE_ARRAY=(
    FASTERQ_CPUS
    FASTERQ_MEM_PER_CPU
)

# Iterate over variables
for variable in "${VARIABLE_ARRAY[@]}"; do
    check_variable "${variable}" || fail "  Set variable in config.sh: ${variable}"
done

echo "  All ${TOOLNAME} variables confirmed"
echo "  Checking for ${TOOLNAME} ${SRA_VERSION} install..."

# Check for sratoolkit
if ! check_sratoolkit; then
    # If not found, download and extract
    install_sratoolkit "${SRA_ARCHIVE}" "${SRA_URL}" "${EXTRACT_DIR}" "${SRA_ENV}"
    # Write to environment file
    write_env "${EXTRACT_DIR}" "${SRA_ENV}" || fail "  Unable to write SRA Toolkit environment file"
else
    # Write to environment file
    write_env "${SRA_DIR}" "${SRA_ENV}" || fail "  Unable to write SRA Toolkit environment file"
fi

echo "  ${TOOLNAME} install confirmed"
echo "  ${SCRIPT_NAME} COMPLETE"

