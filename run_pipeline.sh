#!/usr/bin/env bash
set -euo pipefail

######################### PATHS ###########################

# Define pipeline root path
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Define log directory
LOG_DIR="${PIPELINE_DIR}/logs"
# Create log directory
mkdir -p "${LOG_DIR}"

# Define log file for run_pipeline.sh
LOG_FILE="${LOG_DIR}/run_pipeline.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for run_pipeline.sh ..."

echo
echo "  Checking for user defined variables..."

VARIABLES=(
    BIOPROJECT
    SLURM_MAX_JOBS
    FASTERQ_CPUS
    FASTERQ_MEM_PER_CPU
)

# Iterate over variables
for variable in "${VARIABLES[@]}"; do
    
    # Check for variable in config.sh
    check_variable "${variable}" || {
        echo "  Set variable in config.sh: '${variable}' "
        echo "  Exiting..."
        exit 1
    }

done

echo "  All user defined variables set"
echo
echo "  Checking for tmux..."

# Check for tmux installation
check_command tmux || {
    echo "  Please install tmux"
    echo "  Exiting..."
    exit 1
}

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

echo "  All module scripts found"
echo
echo "  Making module scripts executable..."

# Iterate over scripts
for script in "${SCRIPT_ARRAY[@]}"; do
    
    # Check if script is executable
    check_executable "${MODULES_DIR}/${script}" || {
        echo "  Please check if file exists or can be made executable: '${script}'"
        echo "  Exiting..."
        exit 1
    }

done

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING run_pipeline.sh ..."

echo
echo "  User configuration:"
echo "      tmux session name:          ${TMUX_SESSION_NAME}"
echo "      BioProject ID:              ${BIOPROJECT}"
echo "      Max SLURM array jobs:       ${SLURM_MAX_JOBS}"
echo "      CPUs allocated per task:    ${FASTERQ_CPUS}"
echo "      Memory per CPU:             ${FASTERQ_MEM_PER_CPU}"

echo
echo "  Scripts to be executed:"

for script in "${SCRIPT_ARRAY[@]}"; do
    echo "      ${script}"
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
echo "  Submitting pipeline to tmux session..."

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