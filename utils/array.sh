#!/usr/bin/env bash

#################### PIPELINE SCRIPTS #####################

# SCRIPT_ARRAY:
# Ordered list of pipeline module scripts.
# This array defines the exact execution order of all module scripts
# that make up the SRA pipeline. Each script is executed sequentially
# by pipeline.sh, and the order of entries must reflect required
# biological or computational dependencies between steps.
SCRIPT_ARRAY=(
    "1_install_edirect.sh"
    "2_install_sratoolkit.sh"
    "3_get_accessions.sh"
    "4_download_sra.sh"
    "5_submit_array.sh"
)