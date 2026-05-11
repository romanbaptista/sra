#!/bin/bash

# download_bbtools
# Downloads and installs BBTools into a given directory.
# Arguments:
#   $1 - Directory in which to install
# Operation:
#   Downloads BBMap tarball, extracts it, renames folder to 'bbtools'.
# Returns:
#   0 on successful download and extraction
#   1 on download/extraction failure
#   2 if function called without required argument
# Example:
# download_bbtools "$PIPELINE_DIR"
download_edirect() {

    echo "  Installing EDirect..."

    # Install
    sh -c "$(curl -fsSL https://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/install-edirect.sh)" || fail "  EDirect installation failed"

    # Ensure current shell can see esearch
    export PATH="${HOME}/edirect:$PATH"

    echo "  EDirect installed"
}