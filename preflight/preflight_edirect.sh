#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${UTILS_DIR:?UTILS_DIR not set (check PATHS section in run_pipeline.sh)}"
: "${ENV_DIR:?ENV_DIR not set (check PATHS section in run_pipeline.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
# Define toolname
TOOLNAME="edirect"

######################### SOURCE ##########################

# Source tool-specific functions
source "${UTILS_DIR}/functions_${TOOLNAME}.sh"

######################### PATHS ###########################

# Define environment file path
ENV_FILE="${ENV_DIR}/${TOOLNAME}.env"

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for ${TOOLNAME} install..."

# Check for edirect
if ! check_edirect; then
    install_edirect
fi

# Write environment file (EDIRECT_DIR exported from check_edirect)
write_env "${EDIRECT_DIR}" "${ENV_FILE}"

echo "  Environment file written: ${ENV_FILE}"
echo "  Install confirmed: ${TOOLNAME}"
echo "  ${SCRIPT_NAME} COMPLETE"