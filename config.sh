#!/bin/bash

######################### TMUX SETTINGS #################################
# TMUX_SESSION_NAME:
# Name of the tmux session used to run the SRA pipeline.
# Using a named session allows users to safely disconnect from the HPC
# while long-running steps (e.g., downloads) continue uninterrupted.
TMUX_SESSION_NAME="sra"

######################### 1_GET_ACCESSIONS.SH ###########################

# BIOPROJECT:
# NCBI BioProject accession ID to query.
# This identifier is used to retrieve all associated BioSample and SRA
# run accessions (SRR IDs) for downstream download and processing.
# NOTE: This variable MUST be set before running the pipeline.
BIOPROJECT=""