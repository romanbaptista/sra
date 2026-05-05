# Pipeline Modules

This directory contains the implementation modules for the sra pipeline.

Each module is responsible for exactly one pipeline stage and may be safely rerun if previous outputs already exist.

Modules are executed sequentially by `modules/pipeline.sh`, which itself is launched inside a tmux session by `run_pipeline.sh`.

# Design Contract

All modules adhere to the following principles:
- Single responsibility per script
- Explicit input and output locations
- Fail‑fast preflight checks
- Restart‑safe behavior
- No reliance on global system configuration
- No shared mutable state between samples

# Execution Order

Modules are executed in the order defined in `utils/array.sh`. The current execution order is:

```text
1_install_edirect.sh
2_install_sratoolkit.sh
3_get_accessions.sh
4_download_sra.sh
5_submit_array.sh
6_convert_sra.sh
```

# Module Overview

## `pipeline.sh`

Internal orchestrator for the pipeline.

### Workflow
- Sources configuration and shared utilities
- Validates that all module scripts exist
- Executes each module in order
- Captures high‑level pipeline output into logs/pipeline.log
- Stops immediately if any module fails

`pipeline.sh` is not intended to be run directly by the user.

## `1_install_edirect.sh`
Installs and verifies NCBI EDirect, which is required for querying BioProject and BioSample metadata.

### Workflow
- Checks for the presence of esearch, efetch, elink, and related tools
- Downloads and installs EDirect locally if not found
- Ensures the current shell can access EDirect binaries
- Writes an environment file 
```
    env/edirect.env
```
This file exports:
- `EDIRECT_DIR`
- an updated `PATH`

### Guarantees
- Safe to rerun
- Will not reinstall EDirect unnecessarily
- Does not modify global system paths

## `2_install_sratoolkit.sh`
Installs and verifies the SRA Toolkit, used for downloading and converting SRA files.

### Workflow
- Checks for `prefetch` and `fasterq-dump`
- Downloads a pinned SRA Toolkit archive if missing
- Extracts the toolkit into the user’s home directory
- Temporarily exposes toolkit binaries for verification
- Writes an environment file:
```
    env/sratoolkit.env
```
This file exports:
- `SRA_DIR`
- an updated `PATH`

### Guarantees
- Local, reproducible SRA Toolkit installation
- No reliance on system modules
- Safe to rerun without duplicate downloads

## `3_get_accessions.sh`
Discovers sequencing accessions associated with a user‑supplied BioProject ID.

### Inputs
- `BIOPROJECT` (from `config.sh`)
- Active EDirect environment (`env/edirect.env`)

### Workflow
- Query BioProject
- Retrieve BioSample UIDs
- Fetch BioSample docsum metadata
- Extract SAMN accessions
- Query SRA to derive SRR (run) accessions
- Normalize output formatting

### Outputs
```text
output/3_get_accessions/
├── biosample_uids.txt
├── biosample_docsum.xml
├── biosample_samn_accessions.txt
└── biosample_srr_accessions.txt
```

### Guarantees
- Fails if no BioSamples or SRRs are found
- Produces deterministic accession lists
- Safe to rerun without overwriting unrelated stages

## `4_download_sra.sh`
Downloads `.sra` files for each SRR accession.

### Inputs
- SRR list from `3_get_accessions.sh`
- Active SRA Toolkit environment (`env/sratoolkit.env`)

### Workflow

- Iterates through SRR accessions
- Creates a dedicated directory per SRR
- Uses a per‑SRR VDB_CONFIG to isolate repository state
- Downloads `.sra` files using prefetch
- Skips SRRs that have already been downloaded

### Outputs
```text
output/4_download_sra/
└── SRRXXXXXXXX/
    └── SRRXXXXXXXX.sra
```

### Guarantees
- Restart‑safe
- No cross‑contamination between SRR downloads
- Partial downloads cause a controlled failure

## `5_submit_array.sh`
Creates the SLURM array job responsible for FASTQ conversion.

### Inputs
- SRR accessions file
- Downloaded `.sra` files
- SLURM configuration from `config.sh`

### Workflow
- Validates SLURM availability (`sbatch`)
- Counts non‑empty SRR accessions
- Submits `6_convert_sra.sh` as a bounded SLURM array job

### Outputs
None directly (job submission only).

### Guarantees
- Array size matches number of valid SRRs
- Respects user‑defined concurrency limits
- Submits no jobs if SRR list is empty

## `6_convert_sra.sh`
Converts `.sra` files to compressed FASTQ files using SLURM array jobs.

### Execution Context
- Must be run under SLURM
- Uses `SLURM_ARRAY_TASK_ID` to select the SRR to process

### Workflow

- Resolves SRR accession by array index
- Verifies input `.sra`
- Creates a per‑SRR output directory
- Redirects all output to a per‑sample log file
- Skips conversion if compressed FASTQs already exist
- Runs `fasterq-dump` with allocated CPUs
- Compresses FASTQs and removes partial outputs on failure

### Outputs
```text
output/6_convert_sra/
└── SRRXXXXXXXX/
    ├── SRRXXXXXXXX_1.fastq.gz
    ├── SRRXXXXXXXX_2.fastq.gz
    └── SRRXXXXXXXX_conversion.log
```

### Guarantees
- Idempotent under re‑run
- Safe parallel execution
- No shared filesystem state between array tasks
- Partial FASTQs are cleaned up automatically on error