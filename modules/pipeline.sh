#!/bin/bash
set -euo pipefail

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### SOURCE ##########################

# Source scripts
source "${UTILS_DIR}/functions_base.sh"
source "${UTILS_DIR}/array.sh"
source "${PIPELINE_DIR}/config.sh"

######################### PATHS ###########################

# Define key directories
PIPELINE_DIR="$(get_parent_directory "${BASH_SOURCE[0]}")"
MODULES_DIR="${PIPELINE_DIR}/modules"
UTILS_DIR="${PIPELINE_DIR}/utils"
LOG_DIR="${PIPELINE_DIR}/logs"
ENV_DIR="${PIPELINE_DIR}/env"

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

for script in "${RUN_ARRAY[@]}"; do
    echo "      ${script}"
done

echo
echo "  Pipeline starting..."

# Iterate over scripts
for script in "${RUN_ARRAY[@]}"; do

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
echo "Pipeline SUBMITTED"
echo