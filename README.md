# `sra-download`

# Overview

This repository contains the sra-download pipeline — a modular, HPC‑compatible workflow for:

> Querying sequencing runs from an NCBI BioProject and downloading the corresponding .sra files in a robust, restart‑safe manner.

The pipeline is designed specifically for HPC login‑node execution and handles:
- Querying NCBI metadata (BioProject → BioSample → SRA run accessions)
- Downloading `.sra` files using the SRA Toolkit with per‑accession isolation
- Running safely inside a persistent tmux session to survive disconnections
- Performing comprehensive preflight validation before any network activity

All pipeline outputs are written to a dedicated output/ directory, enabling clean hand‑off to downstream workflows such as FASTQ conversion, QC, or alignment pipelines.

# Repository Structure

```text
sra-download/
├── README.md                           # Top-level overview (this file)
├── config.sh                           # User configuration (BioProject, session name)
├── run_pipeline.sh                     # Entry point (tmux + orchestration)
├── utils/                              # Shared utilities and helpers
│   ├── arrays.sh                       # Canonical lists of scripts, commands, variables
│   ├── functions_base.sh               # General-purpose helper functions
│   ├── functions_edirect.sh            # EDirect check/install helpers
│   └── functions_sratoolkit.sh         # SRA Toolkit check/install helpers
├── preflight/                          # Preflight validation layer
│   ├── preflight.sh
│   ├── preflight_commands.sh
│   ├── preflight_variables.sh
│   ├── preflight_scripts.sh
│   ├── preflight_edirect.sh
│   └── preflight_sratoolkit.sh
├── modules/                            # Pipeline modules (executed sequentially)
│   ├── pipeline.sh
│   ├── 1_get_accessions.sh
│   └── 2_download_sra.sh
└── output/                             # Pipeline-generated data (created at runtime)
```

# Workflow

At a high level, the pipeline proceeds as follows:

### Preflight validation
- Verifies all required framework-level commands are available
- Confirms required user configuration variables are set
- Validates module scripts exist and are executable
- Checks for and installs:
    - NCBI EDirect
    - SRA Toolkit (pinned version)
- Writes reproducible environment files for downstream sourcing

### Accession discovery
- Queries the configured BioProject via EDirect
- Retrieves associated BioSample and SRA run accessions (SRR IDs)
- Writes accession lists to `output/1_get_accessions/`

### Data acquisition
- Iterates through SRR accessions
- Downloads `.sra` files using prefetch
- Isolates each accession into its own directory
- Uses per‑SRR VDB configuration to avoid shared state
- Skips already-downloaded accessions safely

The entire pipeline runs inside a tmux session, allowing users to disconnect from the login node without interrupting long‑running downloads.

# Configuration

All user‑tunable parameters are defined in `config.sh`.

| Variable | Description |
|--------|-------------|
| `BIOPROJECT` | NCBI BioProject accession (required) |
| `TMUX_SESSION_NAME` | tmux session name for pipeline execution |

At minimum, the pipeline requires user definition of the BioProject ID in `config.sh`:

```bash
BIOPROJECT="PRJNAXXXXXX"
```

# Usage

Navigate to the folder containing the pipeline and run:

```bash
bash run_pipeline.sh
```

This will:
- Start or re‑use a dedicated tmux session
- Perform all preflight checks
- Execute the download pipeline safely on the login node

You may detach and re‑attach to the tmux session without interrupting downloads.

# Outputs

All pipeline outputs are written under `output/`, grouped by stage.
Example structure after a complete run:

```text
output/
├── 1_get_accessions/
│   ├── biosample_uids.txt
│   ├── biosample_docsum.xml
│   ├── biosample_samn_accessions.txt
│   └── biosample_srr_accessions.txt
└── 2_download_sra/
    └── SRRXXXXXXXX/
        └── SRRXXXXXXXX.sra
```

Each accession is isolated in its own directory, enabling safe restarts and partial re‑execution without corruption.

# Further Documentation

For detailed documentation on individual components, see:
- `preflight/README.md` — preflight validation design and responsibilities
- `modules/README.md` — individual module behavior
- `utils/README.md` — shared utility functions and helpers

# Citation
If you use this pipeline in published work, please cite:

> Baptista, R. _sra-download: A reproducible HPC pipeline for BioProject-scale SRA data acquisition_. GitHub repository: https://github.com/romanbaptista/sra

Optionally, include the commit hash or release tag used for analysis.

# Why SRA Toolkit 2.10.9?

Many HPC systems provide an older SRA Toolkit module such as `sra-tools-2.10.3.tcl`, available on the RVC cluster. While functional, these older builds often suffer from:
- Outdated HTTPS handling (leading to prefetch failures)
- Incomplete or buggy `fasterq-dump` behavior
- Missing improvements to VDB configuration handling
- Reduced compatibility with newer SRA accessions
- Occasional failures when writing to user-specific repository paths

v2.10.9 includes important fixes and improvements:
- More reliable HTTPS downloads via prefetch
- Better performance and stability in `fasterq-dump`
- Improved handling of per-directory `VDB_CONFIG` files
- Fewer failures when running many jobs in parallel on HPC clusters

For these reasons, the pipeline installs and uses a local copy of SRA Toolkit 2.10.9 by default, ensuring consistent and reproducible behavior across all users and clusters.