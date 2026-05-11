#!/bin/bash
set -euo pipefail

######################### MAIN ############################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

# Define variable array
VARIABLE_ARRAY=(
    TMUX_SESSION_NAME
    BIOPROJECT
    SLURM_MAX_JOBS
)

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for core user-defined variables..."

# Iterate over variables
for variable in "${VARIABLE_ARRAY[@]}"; do
    check_variable "${variable}" || fail "  Set variable in config.sh: '${variable}'"
done

echo "  All core user-defined variables confirmed"
echo "  ${SCRIPT_NAME} COMPLETE"