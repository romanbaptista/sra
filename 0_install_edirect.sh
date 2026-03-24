#!/bin/bash

echo
echo "RUNNING 0_install_edirect.sh..."
echo
echo "  Getting current directory"

# Exit on error
set -euo pipefail

# Check if edirect is present
if command -v esearch >/dev/null 2>&1; then
    echo "  EDirect already installed at $(command -v esearch)"
    echo "  Skipping installation and ending script"
    exit 0
fi

echo "  Downloading and installing EDirect..."

# Install EDirect
sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"

# Add to PATH if not present
if grep -q '\$HOME/edirect' ~/.bashrc; then
    echo "  EDirect PATH entry already present in ~/.bashrc"
else
    echo 'export PATH="$HOME/edirect:$PATH"' >> ~/.bashrc
    echo "  Added EDirect to PATH in ~/.bashrc"
fi

echo "  Updating PATH"

# Updating PATH for current session
export PATH="$HOME/edirect:$PATH"

echo
echo "0_install_edirect.sh COMPLETE"
echo


# echo
# echo "RUNNING 0_install_edirect.sh..."
# echo
# echo "Getting current directory"

# # Get current working directory
# PWD="$(pwd)"

# echo "Installing NCBI edirect"

# # Install edirect
# sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)"

# echo ">> edirect installed"
# echo "Downloading SRA toolkit (2.10.9)"

# # Download SRA toolkit
# wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.10.9/sratoolkit.2.10.9-centos_linux64.tar.gz

# echo ">> toolkit downloaded"
# echo "Extracting toolkit"

# # Extract SRA toolkit
# tar -xzf sratoolkit.2.10.9-centos_linux64.tar.gz

# # Get directory name
# SRA_DIR=$(tar -tf sratoolkit.2.10.9-centos_linux64.tar.gz | head -1 | cut -f1 -d"/")

# echo ">> toolkit extracted"
# echo "Adding packages to PATH"

# # Add edirect to PATH
# echo "export PATH=${HOME}/edirect:\${PATH}" >> ${HOME}/.bashrc
# # Add SRA toolkit to PATH
# echo "export PATH=${PWD}/${SRA_DIR}/bin:\$PATH" >> ${HOME}/.bashrc

# echo "Updating PATH"

# # Reload for use in current session
# source ~/.bashrc

# echo
# echo "0_install_packages.sh COMPLETE"
# echo