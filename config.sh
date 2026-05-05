#!/bin/bash

######################### TMUX SETTINGS #################################
# TMUX_SESSION_NAME:
# Name of the tmux session used to run the SRA pipeline.
# Using a named session allows users to safely disconnect from the HPC
# while long-running steps (e.g., downloads) continue uninterrupted.
TMUX_SESSION_NAME="sra"

######################### 3_GET_ACCESSIONS.SH ###########################

# BIOPROJECT:
# NCBI BioProject accession ID to query.
# This identifier is used to retrieve all associated BioSample and SRA
# run accessions (SRR IDs) for downstream download and processing.
BIOPROJECT=""

######################### 5_SUBMIT_ARRAY.SH #############################

# SLURM_MAX_JOBS:
# Maximum number of concurrent SLURM array tasks.
# This value limits how many SRA downloads or conversions are run in
# parallel to avoid overwhelming cluster resources or job limits.
SLURM_MAX_JOBS=20

######################### 6_CONVERT_SRA.SH ##############################

# FASTERQ_CPUS:
# Number of CPU threads allocated per fasterq-dump task.
# Increasing this value can improve conversion speed but will increase
# per-job CPU usage.
FASTERQ_CPUS=8


# FASTERQ_MEM_PER_CPU:
# Amount of memory allocated per CPU thread for fasterq-dump.
# This value is typically passed to the scheduler as memory-per-CPU
# and should be adjusted based on dataset size and cluster policy.
FASTERQ_MEM_PER_CPU=16G