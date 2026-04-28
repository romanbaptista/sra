# SRA

# Overview

This repository contains the `sra` pipeline, a modular, SLURM‑compatible workflow for:

> Downloading sequencing runs from an NCBI BioProject and converting them into compressed paired‑end FASTQ files.

- The pipeline is designed for HPC environments
- All pipeline outputs are written to a dedicated output/ directory, enabling seamless hand‑off to downstream workflows (e.g. QC, trimming, alignment, variant calling).

# Repository Structure

Below is the structure of the repository:

```text
sra/
├── pipeline.sh                     # Top-level pipeline orchestrator
├── config.sh                       # User configuration file
├── modules/                        # Pipeline scripts
│   ├── 0_install_packages.sh
│   ├── 1_get_accessions.sh
│   ├── 2_download_sra.sh
│   ├── 3_submit_array.sh
│   └── 4_convert_sra.sh
└── README.md
```

# `pipeline.sh`

`pipeline.sh` is the entry point for the SRA pipeline. It coordinates the execution of all module scripts in the correct order.

When executed, `pipeline.sh`:

- Resolves the pipeline root directory
- Loads user configuration from `config.sh`
- Runs each pipeline module sequentially:
    - Environment setup
    - Accession discovery
    - SRA download
    - SLURM array submission for FASTQ conversion


The final FASTQ conversion step runs asynchronously via SLURM.

### Usage

After cloning this repo, navigate to the `sra` folder and run:

```bash
bash pipeline.sh
```

# `config.sh`

`config.sh` contains user‑defined parameters that control the pipeline behaviour. It intentionally avoids defining pipeline‑generated paths, which are derived internally.

## Parameters


| Variable | Description | Used By |
|----------|------------|---------|
| `BIOPROJECT` | NCBI **BioProject accession** to query for sequencing runs (e.g. `PRJNAXXXXXX`) | `1_get_accessions.sh` |
| `MAX_JOBS` | Maximum number of **concurrent SLURM array tasks** when converting SRA files to FASTQ | `3_submit_array.sh` |
| `THREADS` | Number of **CPU threads** allocated to `fasterq-dump` per SLURM array task | `4_convert_sra.sh` |
| `SRATOOLS_DIR` | Path to the **local SRA Toolkit installation** directory | `0_install_packages.sh`, `4_convert_sra.sh` |
| `PATH` (EDirect) | Extends `PATH` to include **EDirect binaries** (e.g. `esearch`, `efetch`) | `0_install_packages.sh`, `1_get_accessions.sh` |
| `PATH` (SRA Toolkit) | Extends `PATH` to include **SRA Toolkit binaries** (e.g. `prefetch`, `fasterq-dump`) | `2_download_sra.sh`, `4_convert_sra.sh` |

`BIOPROJECT` **MUST** be edited by the user before running the pipeline. All other values are acceptable defaults.

# Module Scripts

Each script in `modules/` performs exactly one pipeline task and writes outputs to a dedicated subdirectory under `output/`.

## `0_install_packages.sh`

Installs and verifies required external tools:

- NCBI EDirect
- SRA Toolkit

This script:

- Is safe to rerun (ignores installation if tools are already present)
- Writes no pipeline data
- Modifies user environment only (e.g. `$HOME/`)

### Outputs
None (environment setup only)

## `1_get_accessions.sh`

Queries NCBI for BioSamples and sequencing runs associated with the configured BioProject ID (`BIOPROJECT`).

### Workflow

- Query BioProject
- Extract BioSample UIDs
- Fetch BioSample metadata
- Extract SAMN accessions
- Derive SRR (run) accessions

### Outputs

```text
output/1_get_accessions/
├── biosample_uids.txt
├── biosample_docsum.xml
├── biosample_samn_accessions.txt
└── biosample_srr_accessions.txt
```

## `2_download_sra.sh`

Downloads `.sra` files for each SRR accession.

### Workflow

- Reads SRR accessions from `1_get_accessions.sh`
- Uses `prefetch` to download each run
- Isolates downloads per SRR

### Outputs

```text
output/2_download_sra/
└── SRRxxxxx/
    └── SRRxxxxx.sra
```

## `3_submit_array.sh`

Submits a SLURM array job to perform FASTQ conversion.

### Workflow

- Counts SRR accessions
- Exports PIPELINE_DIR for SLURM jobs
- Submits `4_convert_sra.sh` as an array job

### Outputs
None directly (job submission only)

## `4_convert_sra.sh`

Converts `.sra` files into compressed paired‑end FASTQ files.

- Runs under SLURM as an array task
- Receives pipeline context via exported `PIPELINE_DIR`
- Redirects all `stdout`/`stderr` into per‑SRR log files
- Does not rely on SLURM `.out`/`.err` files

### Workflow

- Resolve SRR from array index
- Validate input `.sra`
- Convert to FASTQ with fasterq-dump
- Compress FASTQs
- Write detailed per‑run log

### Outputs

```text
output/4_convert_sra/
└── SRRxxxxx/
    ├── SRRxxxxx_1.fastq.gz
    ├── SRRxxxxx_2.fastq.gz
    └── SRR
```

# Example Repository Structure After a Run
After running the pipeline for a dummy BioProject, the repository will look like:

```text
sra/
├── pipeline.sh
├── config.sh
├── modules/
│   ├── 0_install_packages.sh
│   ├── 1_get_accessions.sh
│   ├── 2_download_sra.sh
│   ├── 3_submit_array.sh
│   └── 4_convert_sra.sh
├── README.md
└── output/
    ├── 1_get_accessions/
    │   ├── biosample_uids.txt
    │   ├── biosample_docsum.xml
    │   ├── biosample_samn_accessions.txt
    │   └── biosample_srr_accessions.txt
    ├── 2_download_sra/
    │   └── SRRXXXXXXXX/
    │       └── SRRXXXXXXXX.sra
    └── 4_convert_sra/
        └── SRRXXXXXXXX/
            ├── SRRXXXXXXXX_1.fastq.gz
            ├── SRRXXXXXXXX_2.fastq.gz
            └── SRRXXXXXXXX_conversion.log
```

# Why SRA Toolkit 2.10.9?

Many HPC systems provide an older SRA Toolkit module such as `sra-tools-2.10.3.tcl`, available on the RVC cluster. While functional, these older builds often suffer from:

- Outdated HTTPS handling (leading to prefetch failures)
- Incomplete or buggy `fasterq-dump` behavior
- Missing improvements to VDB configuration handling
- Reduced compatibility with newer SRA accessions
- Occasional failures when writing to user-specific repository paths

v2.10.9 includes important fixes and improvements:
- More reliable HTTPS downloads via `prefetch`
- Better performance and stability in `fasterq-dump`
- Improved handling of per-directory `VDB_CONFIG` files
- Fewer failures when running many jobs in parallel on HPC clusters

For these reasons, the pipeline installs and uses a local copy of **SRA Toolkit 2.10.9** by default, ensuring consistent and reproducible behavior across all users and clusters.