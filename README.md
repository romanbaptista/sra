# SRA BioProject Processing Pipeline
This repository contains a modular, SLURM‑compatible pipeline for retrieving, downloading, and converting sequencing data from an NCBI BioProject into compressed FASTQ files. It is designed for HPC environments and supports safe throttling, per‑sample logging, and clean directory isolation for each SRR accession.

The pipeline is fully automated, users: 
- Configure a single file (`run_config.sh`)
- Run one command (`bash run_pipeline.sh`)

and the workflow handles the rest.

## Table of Contents

- [Repository Structure](#repository-structure)
- [Script Descriptions](#script-descriptions)
  - [0_install_edirect.sh](#0_install_edirectsh)
  - [1_get_accessions.sh](#1_get_accessionssh)
  - [2_download_sra.sh](#2_download_srash)
  - [3_submit_array.sh](#3_submit_arraysh)
  - [4_convert_sra.sh](#4_convert_srash)
- [User Configuration](#user-configuration)
  - [BIOPROJECT](#bioproject)
  - [ACCESSION_FILE](#accession_file)
  - [MAX_JOBS](#max_jobs)
  - [THREADS](#threads)
  - [SRA_MODULE](#sra_module)

## Repository Structure
```text
.
├── run_pipeline.sh          # Main entry point for users
├── run_config.sh            # User-editable configuration file
│
├── 0_install_edirect.sh     # Installs EDirect if missing
├── 1_get_accessions.sh      # Retrieves UIDs, SAMNs, and SRRs
├── 2_download_sra.sh        # Downloads SRA files into per-SRR directories
├── 3_submit_array.sh        # Submits SLURM array for conversion
├── 4_convert_sra.sh         # SLURM task script: SRA → FASTQ conversion
│
└── (output files generated during pipeline execution)
```

Only `run_pipeline.sh` should be executed directly.

## Script Descriptions

Below is a detailed description of each numbered script in the pipeline.
Users do not edit these scripts directly — all configuration is handled through run_config.sh.

### `0_install_edirect.sh`
#### Description
This script ensures that NCBI’s Entrez Direct (EDirect) tools are installed and available in the user’s environment. It:
- Checks whether esearch is already installed
- Installs EDirect if missing
- Adds EDirect to the user’s PATH if needed
- Updates the PATH for the current session

#### Output
- Installs EDirect into $HOME/edirect (if not already present)
- Updates ~/.bashrc with the EDirect PATH entry (if missing)
- No data files are produced

### `1_get_accessions.sh`
#### Description
This script retrieves all relevant accessions associated with the BioProject defined in run_config.sh. It:
- Queries NCBI for BioSample UIDs linked to the BioProject
- Downloads metadata for each UID
- Extracts SAMN accessions
- Extracts SRR run accessions
- Produces the SRR list used by later pipeline stages

#### Output
- biosample_uids.txt — list of BioSample UIDs
- biosample_docsum.xml — metadata for each UID
- biosample_samn_accessions.txt — extracted SAMN IDs
- biosample_srr_accessions.txt — extracted SRR run accessions (typically used as the accession file for later steps)

### `2_download_sra.sh`
#### Description
This script downloads .sra files for each SRR accession listed in the file specified by ACCESSION_FILE in run_config.sh. It:
- Iterates through each SRR
- Creates a directory named after the SRR
- Downloads the .sra file using prefetch
- Ensures clean directory isolation for each sample

#### Output
For each SRR:
```text
SRRxxxxxxx/
    SRRxxxxxxx.sra
```

### `3_submit_array.sh`
#### Description
This script submits the SLURM array job that performs SRA → FASTQ conversion. It:
- Counts the number of SRRs in the accession file
- Submits a SLURM array with one task per SRR
- Applies the concurrency limit defined by MAX_JOBS in run_config.sh

#### Output
- Submits a SLURM array job
- No files are created directly by this script

### `4_convert_sra.sh`
#### Description
This script is executed once per SRR as a SLURM array task. It:
- Loads the SRA Toolkit module
- Redirects all output into a per‑SRR log file
- Converts the .sra file into FASTQ files using fasterq-dump
- Compresses the FASTQ files
- Produces clean, per‑sample output and logs

#### Output
For each SRR:
```text
SRRxxxxxxx/
    SRRxxxxxxx.sra
    SRRxxxxxxx_1.fastq.gz
    SRRxxxxxxx_2.fastq.gz
    SRRxxxxxxx_conversion.log
```

## User Configuration
All user‑controlled settings are defined in one place: `run_config.sh`.

```bash
BIOPROJECT="PRJNA925215"
ACCESSION_FILE="biosample_srr_accessions.txt"
MAX_JOBS=20
THREADS=8
SRA_MODULE="sra-tools/2.10.3"
```

### Config Variables

#### `BIOPROJECT`
- **This is the primary setting users will modify**.
- Set it to the BioProject ID you want to process.

#### `ACCESSION_FILE`
- Automatically generated as `biosample_srr_accessions.txt` when running `1_get_accessions.sh`.
- This shouldn't be changed unless users have altered the filename.

#### `MAX_JOBS`
- Controls how many SLURM array tasks run concurrently.
- Users should not increase this without consulting cluster administrators, as it may violate job scheduling policies.

#### `THREADS`
- Number of threads passed to fasterq-dump.
- Defaults to 8 — typically fine for most clusters.

#### `SRA_MODULE`
- Specifies the SRA Toolkit module to load.
- This version is already installed on the RVC cluster and won't need to be edited unless the module installation is changed.
