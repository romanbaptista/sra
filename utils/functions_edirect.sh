#!/bin/bash

# check_edirect
# Verifies that a coherent EDirect installation is available on PATH.
#
# Arguments:
#   None
#
# Operation:
#   - Checks that the 'esearch' binary is available on PATH.
#   - Derives the EDirect installation directory from the binary location.
#   - Exports EDIRECT_DIR on success.
#
# Returns:
#   0 if EDirect is available
#   1 if EDirect is missing or unusable
#
# Example:
#   check_edirect || install_edirect
check_edirect() {
    local esearch_path
    local edirect_dir

    # Get esearch location
    esearch_path="$(command -v esearch)" || return 1
    # Get edirect directory
    edirect_dir="$(cd "$(dirname "${esearch_path}")" && pwd)"
    # Check for command in directory
    [[ -x "${edirect_dir}/esearch" ]] || return 1
    
    # Export the relevant directory
    export EDIRECT_DIR="${edirect_dir}"
    echo "  EDirect already installed"

    return 0
}

# download_edirect
# Downloads and installs NCBI EDirect into the user's home directory.
#
# Arguments:
#   None
#
# Operation:
#   - Downloads the official EDirect installation script from NCBI using curl.
#   - Executes the installer via /bin/sh.
#   - Updates PATH in the current shell to include the EDirect binary directory.
#
# Notes:
#   - Assumes required dependencies (e.g. curl, sh) have already been validated.
#   - Intended for execution on an HPC login node with internet access.
#   - PATH modification affects the calling shell only; persistence is handled
#     separately via an environment file in preflight logic.
#
# Returns:
#   0 on successful installation
#   Exits via fail() on installation failure
#
# Example:
#   download_edirect
download_edirect() {

    echo "  Installing EDirect..."

    # Install
    sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)" || fail "  EDirect installation failed"

    # Ensure current shell can see esearch
    export PATH="${HOME}/edirect:$PATH"

    echo "  EDirect installed"

    return 0
}

# install_edirect
# Installs EDirect and verifies successful installation.
#
# Arguments:
#   None
#
# Operation:
#   - Runs the EDirect installer.
#   - Verifies installation via check_edirect().
#
# Returns:
#   0 on successful install and validation
#   Exits via fail() on failure
#
# Example:
#   install_edirect
install_edirect() {
    
    download_edirect
    echo "  Confirming installation..."
    check_edirect || fail "  EDirect installation may have failed or esearch is unavailable"

    return 0
}