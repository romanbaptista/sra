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

######################### PATHS ###########################

# Define environment file path
EDIRECT_ENV="${ENV_DIR}/${TOOLNAME}.env"

######################### SOURCE ##########################

# Source tool-specific functions
source "${UTILS_DIR}/functions_${TOOLNAME}.sh"

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking for ${TOOLNAME} install..."

# Check for esearch
check_command esearch || download_edirect

echo "  Confirming ${TOOLNAME} installation..."

check_command esearch || fail "  EDirect installation may have failed or esearch may be unavailable"

echo "  Installation confirmed"
echo "  Saving install location to '${EDIRECT_ENV}'..."

# Get esearch path
ESEARCH_PATH="$(command -v esearch)"
# Get EDirect directory path
EDIRECT_DIR="$(cd "$(dirname "${ESEARCH_PATH}")" && pwd)"
# Export EDirect path to EDIRECT_ENV (DO NOT EDIT)
cat > "${EDIRECT_ENV}" <<EOF
export EDIRECT_DIR="${EDIRECT_DIR}"
export PATH="\${EDIRECT_DIR}:\${PATH}"
EOF

echo "  Installation location saved"
echo "  ${SCRIPT_NAME} COMPLETE"