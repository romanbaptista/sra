#!/bin/bash

# BioProject ID to query
BIOPROJECT="PRJNA925215"

# File containing SRR accessions
ACCESSION_FILE="accessions_test.txt"
# Maximum number of concurrent SLURM array jobs
MAX_JOBS=20
# Number of threads for fasterq-dump
THREADS=8
# SRA Toolkit module to load
SRA_MODULE="apps/sra-tools-2.10.3"