#!/bin/bash

# Load user configuration
source run_config.sh

echo
echo "RUNNING 0_install_packages.sh..."
echo

# Exit on error
set -euo pipefail

# Check if edirect is present
if command -v esearch >/dev/null 2>&1 || [[ -x "$HOME/edirect/esearch" ]]; then
    echo "  EDirect already installed at $(command -v esearch)"
    echo "  Skipping installation"
else
    echo "  Downloading and installing EDirect..."
    # Install EDirect
    sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"
    echo "  EDirect installed at $HOME/edirect"
    echo "  PATH for EDirect will be set by run_config.sh"
fi

echo
echo "  Installing SRA Toolkit 2.10.9 locally..."

# Define install parameters
SRATOOLS_VERSION="2.10.9"
SRATOOLS_ARCHIVE="sratoolkit.${SRATOOLS_VERSION}-centos_linux64.tar.gz"
SRATOOLS_DIR="$HOME/sratoolkit.${SRATOOLS_VERSION}-centos_linux64"
SRATOOLS_URL="https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${SRATOOLS_VERSION}/${SRATOOLS_ARCHIVE}"

# Check if toolkit is usable (not just present)
if [[ -x "$SRATOOLS_DIR/bin/prefetch" && -x "$SRATOOLS_DIR/bin/fasterq-dump" ]]; then
    echo "  SRA Toolkit already installed at: $SRATOOLS_DIR"
else
    echo "  Installing SRA Toolkit..."

    cd "$HOME"

    # Download if missing
    if [[ ! -f "$SRATOOLS_ARCHIVE" ]]; then
        echo "  Downloading SRA Toolkit..."
        wget -q "$SRATOOLS_URL"
    else
        echo "  Archive already exists"
    fi

    # Extract (overwrite-safe)
    if [[ -d "$SRATOOLS_DIR" ]]; then
        echo "  Existing directory found — re-extracting to ensure integrity"
        rm -rf "$SRATOOLS_DIR"
    fi

    echo "  Extracting SRA Toolkit..."
    tar -xzf "$SRATOOLS_ARCHIVE"

    echo "  SRA Toolkit installed at: $SRATOOLS_DIR"
fi

echo
echo "0_install_packages.sh COMPLETE"
echo