#!/bin/bash

# Load user configuration
source run_config.sh

echo
echo "RUNNING 0_install_edirect.sh..."
echo

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