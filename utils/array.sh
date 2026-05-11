#!/bin/bash

#################### PIPELINE SCRIPTS #####################

# SCRIPT_ARRAY:
# List of module scripts for preflight checks.
# This array defines all module scripts that make up the SRA pipeline. 
# Each script is checked sequentially by preflight_scripts.
SCRIPT_ARRAY=(
    "1_get_accessions.sh"
    "2_download_sra.sh"
    "3_submit_array.sh"
    "4_convert_sra.sh"
)

# RUN_ARRAY:
# Ordered list of module scripts that are run by pipeline.sh.
# This array defines the exact execution order of all module scripts
# that make up the SRA pipeline. Each script is executed sequentially
# by pipeline.sh, and the order of entries must reflect required
# biological or computational dependencies between steps.
RUN_ARRAY=(
    "1_get_accessions.sh"
    "2_download_sra.sh"
    "3_submit_array.sh"
)