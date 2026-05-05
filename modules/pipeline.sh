#!/bin/bash
set -euo pipefail

######################### PATHS ###########################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Define modules directory
MODULES_DIR="${PIPELINE_DIR}/modules"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source configuration
source "${PIPELINE_DIR}/config.sh"
# Source script array
source "${UTILS_DIR}/array.sh"
# Source functions
source "${UTILS_DIR}/functions.sh"

######################### LOGS ############################

# Create LOG directory
LOG_DIR="${PIPELINE_DIR}/logs"
mkdir -p "${LOG_DIR}"

# Define log file for pipeline.sh
LOG_FILE="${LOG_DIR}/pipeline.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for pipeline.sh ..."

echo
echo "  Checking for module scripts..."

# Iterate over scripts
for script in "${SCRIPT_ARRAY[@]}"; do
    
    # Check if script exists
    check_file "${MODULES_DIR}/${script}" || {
        echo "  Please ensure pipeline script is present in 'modules/': '${script}'"
        echo "  Exiting..."
        exit 1
    }

    # Check that script is not pipeline.sh
    if [[ "${script}" == "pipeline.sh" ]]; then
        echo "  ERROR: pipeline.sh must not be listed in array.sh"
        echo "  Exiting..."
        exit 1
    fi

done

echo "  All scripts found"
echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING pipeline.sh ..."

echo
echo "  Scripts to be executed:"

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
        echo "  ERROR: Error in script: '${script}'"
        echo "  Exiting..."
        exit 1
    fi

    echo "  Script finished: '${script}'"
    
done

echo
echo "Pipeline COMPLETE"
echo