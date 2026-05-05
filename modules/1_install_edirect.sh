#!/usr/bin/env bash
set -euo pipefail

######################### SETUP ###########################

# Define pipeline root directory
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

######################### SOURCE ##########################

# Source functions
source "${UTILS_DIR}/functions.sh"

######################### PATHS ###########################

# Define directory paths
ENV_DIR="${PIPELINE_DIR}/env"

# Define directory array
DIRECTORIES=(
    "${ENV_DIR}"
)

# Create directories
for DIR in "${DIRECTORIES[@]}"; do
    mkdir -p "${DIR}"
done

# Define file paths
ENV_FILE="${ENV_DIR}/edirect.env"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 1_install_edirect.sh ..."

echo
echo "  Checking for curl installation..."


check_command curl || {
    echo "  ERROR: curl is required to install EDirect"
    echo "  Exiting..."
    exit 1
}

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 1_install_edirect.sh ..."

echo
echo "  Checking for EDirect installation..."

check_command esearch || {
    echo "  Downloading and installing EDirect..."

    # Install EDirect
    if ! sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"; then
        echo "  ERROR: EDirect installation failed"
        echo "  Exiting..."
        exit 1
    fi
    
    # Ensure current shell can see esearch
    export PATH="$HOME/edirect:$PATH"

    echo "  EDirect installed"
}

echo
echo "  Confirming installation..."

check_command esearch || {
    echo "  EDirect installation may have failed or esearch may be unavailable"
    echo "  Exiting..."
    exit 1
}

echo "  Installation confirmed"
echo
echo "  Saving install location to '${ENV_FILE}'..."

# Get esearch path
ESEARCH_PATH="$(command -v esearch)"
# Get EDirect directory path
EDIRECT_DIR="$(cd "$(dirname "${ESEARCH_PATH}")" && pwd)"
# Export EDirect path to ENV_FILE (DO NOT EDIT)
cat > "${ENV_FILE}" <<EOF
export EDIRECT_DIR="${EDIRECT_DIR}"
export PATH="\${EDIRECT_DIR}:\${PATH}"
EOF

echo "  Installation location saved"

echo
echo "  1_install_edirect.sh COMPLETE"
echo