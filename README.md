# SRA BioProject Processing Pipeline
This repository contains a modular, SLURM-compatible pipeline for retrieving, downloading, and converting sequencing data from an NCBI BioProject into compressed FASTQ files. It is designed for HPC environments and supports safe throttling, per-sample logging, and clean directory isolation for each SRR accession.

The pipeline is fully automated, users: 
- Configure a single file (`run_config.sh`)
- Run one command (`bash run_pipeline.sh`)

and the workflow handles the rest.

----
# Table of Contents

- ### [📁 Repository Structure](#repository-structure)
- ### [📄 Script Descriptions](#script-descriptions)
  - [0_install_packages.sh](#0_install_packagessh)
  - [1_get_accessions.sh](#1_get_accessionssh)
  - [2_download_sra.sh](#2_download_srash)
  - [3_submit_array.sh](#3_submit_arraysh)
  - [4_convert_sra.sh](#4_convert_srash)
  - [run_config.sh](#run_configsh)
  - [run_pipeline.sh](#run_pipelinesh)
- ### [⚙️ User Configuration](#user-configuration)
  - [BIOPROJECT](#bioproject)
  - [ACCESSION_FILE](#accession_file)
  - [MAX_JOBS](#max_jobs)
  - [THREADS](#threads)
  - [SRA_TOOLKIT_PATH](#sra_toolkit_path)

----
# 📁 Repository Structure

```text
.
├── run_pipeline.sh          # Main entry point for users
├── run_config.sh            # User-editable configuration file
│
├── 0_install_packages.sh    # Installs EDirect + SRA Toolkit locally
├── 1_get_accessions.sh      # Retrieves UIDs, SAMNs, and SRRs
├── 2_download_sra.sh        # Downloads SRA files into per-SRR directories
├── 3_submit_array.sh        # Submits SLURM array for conversion
├── 4_convert_sra.sh         # SLURM task script: SRA → FASTQ conversion
│
└── (output files generated during pipeline execution)
```

Only `run_pipeline.sh` should be executed directly.

----
# 📄 Script Descriptions

Below is a detailed description of each numbered script in the pipeline.
Users do not edit these scripts directly — all configuration is handled through run_config.sh.

## `0_install_packages.sh`

This script installs all required external dependencies locally in the user environment. It:

- Checks whether EDirect (esearch) is already available
- Installs EDirect if missing
- Downloads and extracts the SRA Toolkit (v2.10.9) into `$HOME`
- Relies on `run_config.sh` to expose both tools via `PATH`

### Output
- `$HOME/edirect/` (EDirect installation)
- `$HOME/sratoolkit.2.10.9-centos_linux64/` (SRA Toolkit)
- No data files are produced

## `1_get_accessions.sh`

This script retrieves all relevant accessions associated with the BioProject defined in `run_config.sh`. It:

- Queries NCBI for BioSample UIDs linked to the BioProject
- Downloads metadata for each UID (XML format)
- Extracts SAMN (BioSample) accessions
- Extracts SRR (run) accessions via the SRA database
- Produces the SRR list used by later pipeline stages

### Output
- `biosample_uids.txt` — list of BioSample UIDs
- `biosample_docsum.xml` — metadata for each UID
- `biosample_samn_accessions.txt` — extracted SAMN IDs
- `biosample_srr_accessions.txt` — extracted SRR run accessions

## `2_download_sra.sh`

This script downloads `.sra` files for each SRR accession listed in the file specified by `ACCESSION_FILE`. It:

- Iterates through each SRR accession
- Creates a dedicated directory per SRR
- Downloads `.sra` files using prefetch (HTTPS transport)
- Ensures clean directory isolation and failure handling

### Output

- For each SRR:

```text
SRRxxxxxxx/
    SRRxxxxxxx.sra
```

## `3_submit_array.sh`

This script submits the SLURM array job responsible for SRA → FASTQ conversion. It:

- Counts valid SRR entries in the accession file
- Submits a SLURM array with one task per SRR
- Applies concurrency throttling using `MAX_JOBS`

### Output
- Submits a SLURM array job of the form:

```text
--array=1-N%MAX_JOBS
```

- No files are created directly by this script

## `4_convert_sra.sh`

This script is executed once per SRR as a SLURM array task. It:

- Maps `SLURM_ARRAY_TASK_ID` → SRR accession
- Verifies the `.sra` file exists
- Writes all logs to a per-SRR logfile
- Converts `.sra` → FASTQ using fasterq-dump
- Compresses FASTQ files with `gzip`

### Output

- For each SRR:

```text
SRRxxxxxxx/
    SRRxxxxxxx.sra
    SRRxxxxxxx_1.fastq.gz
    SRRxxxxxxx_2.fastq.gz
    SRRxxxxxxx_conversion.log
```

## `run_config.sh`

This script is the central configuration file for the entire pipeline. It defines all user-controlled variables and environment setup. All other scripts source this file and never require direct modification.

It also:

- Defines the BioProject and execution parameters
- Configures `PATH` for both EDirect and the locally installed SRA Toolkit

### Output
- No files are produced directly
- Provides configuration values and environment setup to all scripts

## `run_pipeline.sh`

This is the main entry point for users and orchestrates the full workflow. It:

- Loads configuration from `run_config.sh`
- Runs `0_install_packages.sh` to install dependencies
- Runs `1_get_accessions.sh` to retrieve all accessions
- Runs `2_download_sra.sh` to download .sra files
- Runs `3_submit_array.sh` to submit the SLURM array for conversion

Once this script completes, all remaining work is handled asynchronously by SLURM.

### Output
- No data files are produced directly
- Submits the SLURM array job executing `4_convert_sra.sh`

----
# ⚙️ User Configuration

All user-controlled settings are defined in one place: `run_config.sh`.

```bash
BIOPROJECT="PRJNA925215"
ACCESSION_FILE="biosample_srr_accessions.txt"
MAX_JOBS=20
THREADS=8
```

## Config Variables

### `BIOPROJECT`
- Primary user input
- Specifies the BioProject ID to query from NCBI

### `ACCESSION_FILE`
- File containing SRR accessions used downstream
- Typically generated automatically as:

```text
biosample_srr_accessions.txt
```

- Can be overridden for custom SRR subsets

### `MAX_JOBS`
- Maximum number of concurrent SLURM array tasks
- Controls cluster load and job scheduling behaviour

### `THREADS`
- Number of threads passed to `fasterq-dump`
- Should be aligned with SLURM `--cpus-per-task`

### `SRA_TOOLKIT_PATH`
- Internally defined in `run_config.sh` as:

```bash
export SRATOOLS_DIR="$HOME/sratoolkit.2.10.9-centos_linux64"
export PATH="$SRATOOLS_DIR/bin:$PATH"
```

- Users typically do not need to modify this unless changing toolkit version or install location