#!/bin/bash
set -euo pipefail

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### PATHS ###########################

# Define directory paths
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
MODULES_DIR="${PIPELINE_DIR}/modules"
PREFLIGHT_DIR="${PIPELINE_DIR}/preflight"
UTILS_DIR="${PIPELINE_DIR}/utils"
LOG_DIR="${PIPELINE_DIR}/logs"
ENV_DIR="${PIPELINE_DIR}/env"
OUTPUT_DIR="${PIPELINE_DIR}/output"

# Define directories to create
DIR_ARRAY=(
    OUTPUT_DIR
    LOG_DIR
    ENV_DIR
)

# Create directories
for dir in "${DIR_ARRAY[@]}":
    mkdir -p "${!dir}"

######################### SOURCE ##########################

# Source scripts
source "${UTILS_DIR}/functions_base.sh"
source "${UTILS_DIR}/arrays.sh"
source "${PIPELINE_DIR}/config.sh"

######################### LOGS ############################

# Define log file for pipeline.sh
LOG_FILE="${LOG_DIR}/pipeline.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Scripts to run:"

for script in "${SCRIPT_ARRAY[@]}"; do
    echo "      ${script}"
done

echo
echo "  Pipeline starting..."

# Iterate over scripts
for script in "${SCRIPT_ARRAY[@]}"; do

    echo
    echo "  Running script: '${script}'..."
    echo "  Creating log file..."
    
    # Create log file
    SCRIPT_LOG="${LOG_DIR}/${script%.sh}.log"

    echo "  Log file created: '${SCRIPT_LOG}'"

    # Run script
    if ! bash "${MODULES_DIR}/${script}" > "${SCRIPT_LOG}" 2>&1; then
        fail "  ERROR: Error in script: ${script}"
    fi

    echo "  Script finished: '${script}'"
    
done

echo
echo "${SCRIPT_NAME} COMPLETE"
echo