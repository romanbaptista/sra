#!/bin/bash
set -euo pipefail

######################### SETUP ###########################

# Define pipeline root directory
PIPELINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
# Define utils directory
UTILS_DIR="${PIPELINE_DIR}/utils"

# Define SRA Toolkit parameters
SRA_VERSION="2.10.9"
SRA_ARCHIVE="sratoolkit.${SRA_VERSION}-centos_linux64.tar.gz"
SRA_URL="https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${SRA_VERSION}/${SRA_ARCHIVE}"

######################### SOURCE ##########################

# Source functions
source "${UTILS_DIR}/functions.sh"

######################### PATHS ###########################

# Define directory paths
EXTRACT_DIR="${HOME}/sratoolkit.${SRA_VERSION}-centos_linux64"
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
ENV_FILE="${ENV_DIR}/sratoolkit.env"

######################### CHECKS ##########################

echo
echo "PREFLIGHT CHECKS for 2_install_sratoolkit.sh ..."

echo
echo "  Checking for wget installation..."


check_command wget || {
    echo "  ERROR: wget is required to install SRA Toolkit"
    echo "  Exiting..."
    exit 1
}

echo
echo "  Checking for tar installation..."


check_command tar || {
    echo "  ERROR: tar is required to extract SRA Toolkit archive"
    echo "  Exiting..."
    exit 1
}

echo
echo "Preflight checks COMPLETE"
echo "Proceeding to main execution..."

######################### MAIN ############################

echo
echo "RUNNING 2_install_sratoolkit.sh ..."

echo
echo "  Checking for SRA Toolkit ${SRA_VERSION} installation..."

# Check for prefetch/fasterq-dump
if check_command prefetch && check_command fasterq-dump; then
    echo "  SRA Toolkit already installed"
else
    echo "  WARNING: SRA Toolkit not fully available"
    echo "  Checking for appropriate archive file..."

    # Check for archive
    check_file "${HOME}/${SRA_ARCHIVE}" || {
        echo "  Downloading SRA Toolkit ${SRA_VERSION} archive..."
        # Download archive
        wget -q -O "${HOME}/${SRA_ARCHIVE}" "${SRA_URL}"
        echo "  Archive downloaded"
    }

    echo "  Extracting archive..."

    # Remove any existing directory
    check_directory "${EXTRACT_DIR}" && {
        rm -rf "${EXTRACT_DIR}"
    }

    # Extract toolkit
    tar -xzf "${HOME}/${SRA_ARCHIVE}" -C "${HOME}"

    echo "  Archive extracted"

    # Temporarily expose bin to PATH for installation confirmation 
    export PATH="${EXTRACT_DIR}/bin:${PATH}"
fi

echo
echo "  Confirming installation..."

if check_command prefetch && check_command fasterq-dump; then
    echo "  prefetch and fasterq-dump commands available"
else
    echo "  ERROR: SRA Toolkit installation incomplete"
    echo "  One or more of prefetch and fasterq-dump not found"
    echo "  Exiting..."
    exit 1
fi

echo
echo "  Saving install location to '${ENV_FILE}'..."

# Get prefetch path
PREFETCH_PATH="$(command -v prefetch)"
# Get prefetch directory path
PREFETCH_DIR="$(dirname "${PREFETCH_PATH}")"
# Get SRA Toolkit directory path
SRA_DIR="$(dirname "${PREFETCH_DIR}")"

# Export SRA Toolkit location and path to ENV_FILE (DO NOT EDIT)
cat > "${ENV_FILE}" <<EOF
export SRA_DIR="${SRA_DIR}"
export PATH="\${SRA_DIR}/bin:\${PATH}"
EOF

echo "  Installation location saved"

echo
echo "2_install_sratoolkit.sh COMPLETE"
echo