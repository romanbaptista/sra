#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${MODULES_DIR:?MODULES_DIR not set (check PATHS section in run_pipeline.sh)}"
: "${PREFLIGHT_DIR:?PREFLIGHT_DIR not set (check PATHS section in run_pipeline.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### MAIN ############################

echo
echo "  RUNNING ${SCRIPT_NAME} ..."

# Define preflight array
PREFLIGHT_ARRAY=(
    "preflight_variables.sh"
    "preflight_scripts.sh"
    "preflight_commands.sh"
    "preflight_edirect.sh"
    "preflight_sratoolkit.sh"
)

# Iterate through preflight checks
for script in "${PREFLIGHT_ARRAY[@]}"; do
    check_file "${PREFLIGHT_DIR}/${script}" || fail "  Please ensure that preflight script exists: ${script}"
    check_file_data "${PREFLIGHT_DIR}/${script}" || fail "  Please ensure that preflight script contains data: ${script}"
    source "${PREFLIGHT_DIR}/${script}"
done

echo
echo "  ${SCRIPT_NAME} COMPLETE"