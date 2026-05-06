# SRA Pipeline

# Overview

This repository contains the sra pipeline — a modular, SLURM‑compatible workflow for:

> Downloading sequencing runs from an NCBI BioProject and converting them into compressed paired‑end FASTQ files for downstream analysis.

The pipeline is designed specifically for HPC environments and handles:

- Querying NCBI metadata (BioProject → BioSample → SRA runs)
- Downloading `.sra` files in an isolated, restart‑safe manner
- Converting SRA files to FASTQ using SLURM array jobs
- Writing reproducible, per‑sample logs suitable for large cohorts

All pipeline outputs are written to a dedicated output/ directory, enabling seamless hand‑off to downstream workflows (QC, trimming, alignment, variant calling, etc.).

# Repository Structure

```text
sra/
├── README.md                       # Top-level overview (this file)
├── config.sh                       # User configuration (BioProject, resources, limits)
├── run_pipeline.sh                 # Entry point (tmux + orchestration)
├── utils/                          # Shared utilities
│   ├── array.sh                    # Ordered list of pipeline modules
│   └── functions.sh                # Reusable helper functions
├── modules/                        # Pipeline modules (executed sequentially)
│   ├── pipeline.sh
│   ├── 1_install_edirect.sh
│   ├── 2_install_sratoolkit.sh
│   ├── 3_get_accessions.sh
│   ├── 4_download_sra.sh
│   ├── 5_submit_array.sh
│   └── 6_convert_sra.sh
└── output/                         # Pipeline-generated data (created at runtime)
```

# Workflow

At a high level, the pipeline proceeds as follows:

### Environment setup
- Installs and verifies NCBI EDirect
- Installs and verifies SRA Toolkit (local, reproducible version)

### Accession discovery
- Queries the configured BioProject
- Retrieves associated BioSample and SRA run accessions (SRRs)

### Data acquisition
- Downloads `.sra` files per SRR
- Stores each run in an isolated directory

### FASTQ conversion
- Submits a SLURM array job
- Converts each `.sra` file to compressed FASTQ
- Writes per‑SRR conversion logs

The final conversion step runs asynchronously via SLURM, allowing large datasets to be processed efficiently.

# Configuration

All user‑tunable parameters are defined in `config.sh`.

| Variable | Description |
|--------|-------------|
| `BIOPROJECT` | NCBI BioProject accession (required) |
| `TMUX_SESSION_NAME` | tmux session name for pipeline execution |
| `SLURM_MAX_JOBS` | Maximum concurrent SLURM array tasks |
| `FASTERQ_CPUS` | CPUs allocated per FASTQ conversion |
| `FASTERQ_MEM_PER_CPU` | Memory allocated per CPU for conversion |

At minimum, the pipeline requires user definition of the BioProject ID in `config.sh`:

```bash
BIOPROJECT="PRJNAXXXXXX"
```

Other parameters (SLURM limits, CPUs, memory per CPU) have sensible defaults and can be adjusted if required.

# Usage

Navigate to the folder containing the pipeline and run:

```bash
bash run_pipeline.sh
```

This will:
- Start a dedicated tmux session
- Perform all preflight checks
- Submit the pipeline to run safely in the background

You can detach/re‑attach to monitor progress without interrupting downloads or jobs.

# Outputs

All pipeline outputs are written under output/, grouped by stage.
Example structure after a complete run:

```text
output/
├── 3_get_accessions/
│   ├── biosample_uids.txt
│   ├── biosample_docsum.xml
│   ├── biosample_samn_accessions.txt
│   └── biosample_srr_accessions.txt
├── 4_download_sra/
│   └── SRRXXXXXXXX/
│       └── SRRXXXXXXXX.sra
└── 6_convert_sra/
    └── SRRXXXXXXXX/
        ├── SRRXXXXXXXX_1.fastq.gz
        ├── SRRXXXXXXXX_2.fastq.gz
        └── SRRXXXXXXXX_conversion.log
```

Per‑sample logs allow individual failures or performance issues to be inspected without scanning global job output.

# Further Documentation

For a detailed explanation of each pipeline module, execution order, and implementation decisions, see `modules/README.md`

# Citation
If you use this pipeline in published work, please cite:

> Baptista, R. _sra: A SLURM‑compatible pipeline for BioProject‑scale SRA download and FASTQ conversion_.
> GitHub repository: https://github.com/romanbaptista/sra

Optionally, include the commit hash or release tag used for analysis.

# Why SRA Toolkit 2.10.9?

Many HPC systems provide an older SRA Toolkit module such as sra-tools-2.10.3.tcl, available on the RVC cluster. While functional, these older builds often suffer from:
- Outdated HTTPS handling (leading to prefetch failures)
- Incomplete or buggy fasterq-dump behavior
- Missing improvements to VDB configuration handling
- Reduced compatibility with newer SRA accessions
- Occasional failures when writing to user-specific repository paths

v2.10.9 includes important fixes and improvements:
- More reliable HTTPS downloads via prefetch
- Better performance and stability in fasterq-dump
- Improved handling of per-directory VDB_CONFIG files
- Fewer failures when running many jobs in parallel on HPC clusters

For these reasons, the pipeline installs and uses a local copy of SRA Toolkit 2.10.9 by default, ensuring consistent and reproducible behavior across all users and clusters.