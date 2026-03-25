# SRA BioProject Processing Pipeline

This repository contains a modular, SLURM-compatible pipeline for retrieving, downloading, and converting sequencing data from an NCBI BioProject into compressed FASTQ files. It is designed for HPC environments and supports safe throttling, per-sample logging, and clean directory isolation for each SRR accession.

The pipeline is fully automated. Users:
- Configure a single file (run_config.sh)
- Run one command (bash run_pipeline.sh)

The workflow handles the rest.
<br>

----
# Table of Contents
### [📁 Repository Structure](#repository-structure)
### [📄 Script Descriptions](#script-descriptions)
  - [0_install_packages.sh](#0_install_packagessh)
  - [1_get_accessions.sh](#1_get_accessionssh)
  - [2_download_sra.sh](#2_download_srash)
  - [3_submit_array.sh](#3_submit_arraysh)
  - [4_convert_sra.sh](#4_convert_srash)
  - [run_config.sh](#run_configsh)
  - [run_pipeline.sh](#run_pipelinesh)
### [⚙️ User Configuration](#user-configuration)
  - [BIOPROJECT](#bioproject)
  - [ACCESSION_FILE](#accession_file)
  - [MAX_JOBS](#max_jobs)
  - [THREADS](#threads)
  - [SRA_TOOLKIT_PATH](#sra-toolkit-path)
### [❔ Why SRA Toolkit 2.10.9?](#why-sra-toolkit-2109-1)
<br>

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

Only run_pipeline.sh should be executed directly.
<br>

----
# 📄 Script Descriptions

## `0_install_packages.sh`
Installs all required external dependencies locally in the user environment. It:

- Checks whether EDirect (esearch) is already available
- Installs EDirect if missing
- Downloads and extracts the SRA Toolkit (v2.10.9) into `$HOME`
- Ensures the toolkit is usable (checks for prefetch and fasterq-dump executables)
- Relies on `run_config.sh` to expose both tools via `PATH`

### Output
- `$HOME/edirect/` 
- `$HOME/sratoolkit.2.10.9-centos_linux64/` 
- No data files are produced

## `1_get_accessions.sh`
Retrieves all relevant accessions associated with the BioProject defined in `run_config.sh`. It:

- Queries NCBI for BioSample UIDs linked to the BioProject
- Downloads metadata for each UID (XML format)
- Extracts SAMN (BioSample) accessions
- Extracts SRR (run) accessions via the SRA database
- Produces the SRR list used by downstream pipeline stages

### Output
- `biosample_uids.txt`
- `biosample_docsum.xml`
- `biosample_samn_accessions.txt`
- `biosample_srr_accessions.txt`

## `2_download_sra.sh`
Downloads `.sra` files for each SRR accession listed in `ACCESSION_FILE`. It:

- Iterates through each SRR accession
- Creates a dedicated directory per SRR
- Localises VDB configuration per SRR directory by setting `VDB_CONFIG` and writing a private `.vdb-config`
- Uses prefetch with HTTPS transport
- Downloads each `.sra` file directly into its corresponding SRR directory
- Ensures clean directory isolation and robust failure handling

### Output (per SRR)
```text
SRRxxxxxxx/
    SRRxxxxxxx.sra
```

## `3_submit_array.sh`
Submits the SLURM array job responsible for SRA → FASTQ conversion. It:

- Counts valid SRR entries in the accession file
- Submits a SLURM array with one task per SRR
- Applies concurrency throttling using `MAX_JOBS`

### Output
- A SLURM array job of the form: `--array=1-N%MAX_JOBS`
- No files are created directly

## `4_convert_sra.sh`
Executed once per SRR as a SLURM array task. It:

- Maps `SLURM_ARRAY_TASK_ID` to the corresponding SRR accession
- Verifies the `.sra` file exists
- Creates a per-SRR logfile and redirects all stdout/stderr into it
- Converts SRA → FASTQ using fasterq-dump with THREADS threads
- Compresses FASTQ files using gzip
- Ensures all work is performed inside the SRR directory

### Output (per SRR)
```text
SRRxxxxxxx/
    SRRxxxxxxx.sra
    SRRxxxxxxx_1.fastq.gz
    SRRxxxxxxx_2.fastq.gz
    SRRxxxxxxx_conversion.log
```

## `run_config.sh`
The central configuration file for the entire pipeline. It defines all user-controlled variables and environment setup. All other scripts source this file. It:

- Defines the BioProject and execution parameters
- Sets the default accession file (biosample_srr_accessions.txt)
- Configures `PATH` for both EDirect and the locally installed SRA Toolkit
- Exports `SRATOOLS_DIR` and ensures the correct toolkit version is used

### Output
- No files are produced directly
- Provides configuration values and environment setup to all scripts

## `run_pipeline.sh`
The main entry point for users. It:

- Loads configuration from run_config.sh
- Runs `0_install_packages.sh` to install dependencies
- Runs `1_get_accessions.sh` to retrieve all accessions
- Runs `2_download_sra.sh` to download .sra files
- Runs `3_submit_array.sh` to submit the SLURM array for conversion
Once this script completes, all remaining work is handled asynchronously by SLURM.

### Output
- No data files are produced directly
- Submits the SLURM array job executing `4_convert_sra.sh`
<br>

----
# ⚙️ User Configuration
All user-controlled settings are defined in `run_config.sh`.

```bash
# Variables
BIOPROJECT="PRJNA925215" 
ACCESSION_FILE="biosample_srr_accessions.txt" 
MAX_JOBS=20 
THREADS=8
```

## Configuration Variables

### `BIOPROJECT`
- The BioProject ID to query from NCBI.

### `ACCESSION_FILE`
- The file containing SRR accessions used downstream.
- Default: `biosample_srr_accessions.txt` (generated automatically by `1_get_accessions.sh`).
- Users may override this to process a subset of SRRs.

### `MAX_JOBS`
- Maximum number of concurrent SLURM array tasks.
- Controls cluster load and scheduling behavior.

### `THREADS`
- Number of threads passed to `fasterq-dump`.
- Should match the `SLURM --cpus-per-task` setting in `4_convert_sra.sh`.

### SRA Toolkit Path
- Defined internally in `run_config.sh`:
```bash
export SRATOOLS_DIR="$HOME/sratoolkit.2.10.9-centos_linux64" 
export PATH="$SRATOOLS_DIR/bin:$PATH"
```
- Users normally do not need to modify this unless changing toolkit version or install location.
<br>

----
# ❔ Why SRA Toolkit 2.10.9?

Many HPC systems provide an older SRA Toolkit module such as `sra-tools-2.10.3.tcl`, available on the RVC cluster. While functional, these older builds often suffer from:

- Outdated HTTPS handling (leading to prefetch failures)
- Incomplete or buggy `fasterq-dump` behavior
- Missing improvements to VDB configuration handling
- Reduced compatibility with newer SRA accessions
- Occasional failures when writing to user-specific repository paths

Version 2.10.9 includes important fixes and improvements:
- More reliable HTTPS downloads via prefetch
- Better performance and stability in `fasterq-dump`
- Improved handling of per-directory VDB_CONFIG files
- Fewer failures when running many jobs in parallel on HPC clusters

For these reasons, the pipeline installs and uses a local copy of **SRA Toolkit 2.10.9** by default, ensuring consistent and reproducible behavior across all users and clusters.
