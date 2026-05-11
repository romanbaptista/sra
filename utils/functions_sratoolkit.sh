#!/bin/bash

check_sratoolkit() {
    local prefetch_path
    local sra_dir

    # Get prefecth path
    prefetch_path="$(command -v prefetch)" || return 1
    # Get parent directory
    sra_dir="$(get_parent_directory "${prefetch_path}")"

    # Check for all commands in directory
    if [[ -x "${sra_dir}/bin/prefetch" && -x "${sra_dir}/bin/fasterq-dump" && -x "${sra_dir}/bin/vdb-config" ]]; then
        # Export the relevant directory
        export SRA_DIR="${sra_dir}"
        echo "  SRA Toolkit already installed"
        return 0
    else
        return 1
    fi
}

download_sratoolkit() {
    local archive="$1"
    local url="$2"

    check_arg "${archive}" || return $?
    check_arg "${url}" || return $?

    echo "  Checking for existing SRA Toolkit archive: ${archive}..."

    # Check for existing archive
    [[ -f "${HOME}/${archive}" ]] && return 0

    echo "  Downloading SRA Toolkit archive..."

    # Download SRA Toolkit archive
    wget -q -O "${HOME}/${archive}" "${url}" || return 1

    echo "  Archive downloaded"
}

extract_sratoolkit() {
    local archive="$1"
    local extract_dir="$2"

    check_arg "${archive}" || return $?
    check_arg "${extract_dir}" || return $?

    # Remove any existing extraction directory
    rm -rf "${extract_dir}"
    # Extract archive
    tar -xzf "${HOME}/${archive}" -C "${HOME}" || return 1
    # Export extract directory to PATH
    export PATH="${extract_dir}/bin:${PATH}"
}

write_env() {
    local extract_dir="$1"
    local env_file="$2"

    check_arg "${extract_dir}" || return $?
    check_arg "${env_file}" || return $?

    cat > "${env_file}" << EOF
export SRA_DIR="${extract_dir}"
export PATH="\${SRA_DIR}/bin:\${PATH}"
EOF
}

install_sratoolkit() {
    local archive="$1"
    local url="$2"
    local extract_dir="$3"
    local env_file="$4"

    check_arg "${archive}" || return $?
    check_arg "${url}" || return $?
    check_arg "${extract_dir}" || return $?
    check_arg "${env_file}" || return $?
    
    # If not, download
    download_sratoolkit "${archive}" "${url}" || fail "  Unable to download SRA Toolkit using 'wget'"
    # Extract
    extract_sratoolkit "${archive}" "${extract_dir}" || fail "  Unable to extract SRA Toolkit archive using 'tar'"
    # Confirm installation
    check_sratoolkit || fail "  Archive location not on PATH"

    return 0
}