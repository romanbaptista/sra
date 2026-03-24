#!/bin/bash

# Load user configuration
source run_config.sh

echo
echo "RUNNING 0_install_packages.sh..."
echo

# Exit on error
set -euo pipefail

# Check if edirect is present
if command -v esearch >/dev/null 2>&1; then
    echo "  EDirect already installed at $(command -v esearch)"
    echo "  Skipping installation and ending script"
fi

echo "  Downloading and installing EDirect..."

# Install EDirect
sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"

echo "  EDirect installed at $HOME/edirect"
echo "  PATH for EDirect will be set by run_config.sh"

echo
echo "  Installing SRA Toolkit 2.10.9 locally..."

# Navigate to user's home directory
cd "$HOME"

# Download SRA Toolkit
if [ ! -f sratoolkit.2.10.9-centos_linux64.tar.gz ]; then
    echo "  Downloading SRA Toolkit..."
    wget -q https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.10.9/sratoolkit.2.10.9-centos_linux64.tar.gz
fi

# Install SRA Toolkit
if [ ! -d "$HOME/sratoolkit.2.10.9-centos_linux64" ]; then
    echo "  Extracting SRA Toolkit..."
    tar -xzf sratoolkit.2.10.9-centos_linux64.tar.gz
else
    echo "  SRA Toolkit already extracted"
fi

echo "  SRA Toolkit installed at: $HOME/sratoolkit.2.10.9-centos_linux64"
echo
echo "0_install_packages.sh COMPLETE"
echo