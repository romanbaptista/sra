#!/bin/bash

# SCRIPT_ARRAY:
# Ordered list of module scripts that comprise the sra-download pipeline.
#
# Scope:
#   - Used by preflight_scripts.sh to verify existence, content, and executability.
#   - Used by modules/pipeline.sh to execute the pipeline sequentially.
SCRIPT_ARRAY=(
    "1_get_accessions.sh"
    "2_download_sra.sh"
)

# COMMAND_ARRAY:
# Canonical list of generic external commands required by the sra-download
# pipeline framework.
#
# Scope:
#   - Validated by preflight_commands.sh.
#   - Includes shell utilities, filesystem commands, networking tools,
#     and session management utilities used throughout the pipeline
#     infrastructure (run_pipeline, pipeline, preflight, utils).
#
# Notes:
#   - Tool-specific binaries are intentionally excluded and validated 
#     by dedicated tool preflight scripts.
COMMAND_ARRAY=(
    # Shell / core utilities
    bash
    mkdir
    cd
    pwd
    dirname
    basename
    date
    wc
    grep
    sed
    awk
    tr
    xargs
    # File / permission utilities
    chmod
    tee
    # Networking / download (framework use)
    curl
    wget
    # Compression / extraction
    tar
    # Session management
    tmux
)

# VARIABLE_ARRAY:
# List of required user-defined configuration variables for the sra-download pipeline.
#
# Scope:
#   - Validated by preflight_variables.sh.
#   - Variables must be defined and non-empty in config.sh.
VARIABLE_ARRAY=(
    TMUX_SESSION_NAME
    BIOPROJECT
)