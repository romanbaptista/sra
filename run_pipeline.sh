#!/bin/bash
set -euo pipefail

######################### SETUP ##########################

# Define pipeline name
PIPELINE_NAME="sra"
# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### PATHS ###########################

# Define directory paths
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="${PIPELINE_DIR}/modules"
PREFLIGHT_DIR="${PIPELINE_DIR}/preflight"
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source scripts
source "${UTILS_DIR}/functions_base.sh"
source "${UTILS_DIR}/arrays.sh"
source "${UTILS_DIR}/exports.sh"
source "${PIPELINE_DIR}/config.sh"

######################### ENV #############################

# Create environment directory
ENV_DIR="${PIPELINE_DIR}/env"
mkdir -p "${ENV_DIR}"

######################### LOGS ############################

# Define log directory
LOG_DIR="${PIPELINE_DIR}/logs"
mkdir -p "${LOG_DIR}"

# Define log file for this script
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT for ${PIPELINE_NAME} ..."

check_file "${PREFLIGHT_DIR}/preflight.sh" || fail "  Please ensure that preflight.sh exists"
source "${PREFLIGHT_DIR}/preflight.sh"

echo
echo "Preflight COMPLETE"
echo "Moving to main execution"

######################### MAIN ############################

echo
echo "RUNNING ${PIPELINE_NAME} ${SCRIPT_NAME} ..."

echo
echo "  User configuration:"
echo "      tmux session name:          ${TMUX_SESSION_NAME}"
echo "      BioProject ID:              ${BIOPROJECT}"
echo "      Max SLURM array jobs:       ${SLURM_MAX_JOBS}"
echo "      CPUs allocated per task:    ${FASTERQ_CPUS}"
echo "      Memory per CPU:             ${FASTERQ_MEM_PER_CPU}"

echo
echo "  Scripts to run:"

for script in "${SCRIPT_ARRAY[@]}"; do
    echo "    ${script}"
done

echo
echo "  Creating tmux session..."

# Check for tmux session
if ! tmux has-session -t "${TMUX_SESSION_NAME}" 2>/dev/null; then
    echo "  No tmux session found; creating new session..."
    tmux new-session -d -s "${TMUX_SESSION_NAME}"
    echo "  Created new tmux session: ${TMUX_SESSION_NAME}"
else
    echo "  Using existing session: ${TMUX_SESSION_NAME}"
fi

echo
echo "  Submitting pipeline.sh to tmux session..."

# Submit pipeline.sh to tmux session
tmux send-keys -t "${TMUX_SESSION_NAME}" \
    "bash '${MODULES_DIR}/pipeline.sh'" C-m

echo
echo "Pipeline submission COMPLETE"
echo
echo "To monitor progress, use:"
echo "  'tmux attach -t ${TMUX_SESSION_NAME}'"
echo
echo "To detach again, without stopping jobs:"
echo "  Press Ctrl+b then d"
echo
echo "To kill session, use:"
echo "  'tmux kill-session -t ${TMUX_SESSION_NAME}'"
echo
echo "${PIPELINE_NAME} ${SCRIPT_NAME} COMPLETE"
echo