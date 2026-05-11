# `modules`

This directory contains the implementation modules for the sra-download pipeline.

Each module is responsible for exactly one pipeline role and is executed sequentially as part of a deterministic, preflight‑validated workflow designed for HPC login‑node execution.

Modules are coordinated by `modules/pipeline.sh`, which is invoked by `run_pipeline.sh` only after all preflight checks have completed successfully.

# Design Contract

All modules in this directory adhere to the following principles:
- Single responsibility per script
- Explicit, absolute input and output paths
- Strong separation between validation and execution
- Restart‑safe behavior where possible
- Deterministic execution order
- No reliance on implicit working directories
- No reliance on undeclared global state
- Assumption that all preflight invariants have already been enforced

Modules do not repeat preflight checks and may assume that all required inputs, tools, and configuration variables are valid at runtime.

# Execution Order

The `sra-download` pipeline uses a sequential execution model:
- Modules are executed one at a time in a fixed order
- All execution occurs inside a persistent `tmux` session
- This pipeline runs exclusively on the HPC login node

The current set of modules is:

```text
pipeline.sh
1_get_accessions.sh
2_download_sra.sh
```

Execution logic is explicitly defined in `modules/pipeline.sh`.

# Module Overview

## `pipeline.sh`

Internal module orchestrator for the `sra-download` pipeline.

### Role
`pipeline.sh` is responsible for coordinating sequential execution of the download pipeline. It is not intended to be executed directly by end users.

### Workflow
- Runs inside a `tmux` session started by `run_pipeline.sh`
- Re-establishes pipeline context and sources shared configuration
- Creates pipeline‑level logging infrastructure
- Iterates over all module scripts defined in `SCRIPT_ARRAY`
- Executes each module in order, capturing per‑module logs
- Aborts immediately if any module fails

`pipeline.sh` performs no data acquisition itself.

### Guarantees
- Executes modules in a deterministic order
- Produces a dedicated log file per module
- Does not duplicate preflight validation logic
- Does not rely on inherited shell state
- Does not submit SLURM jobs

## `1_get_accessions.sh`
Discovers BioSample and SRA run accessions associated with a BioProject.

### Inputs
- `BIOPROJECT` (from `config.sh`)
- NCBI EDirect tools (validated in preflight)
- Network access on the login node

### Workflow
- Queries the NCBI BioProject database
- Retrieves associated BioSample UIDs
- Downloads BioSample metadata in XML format
- Extracts BioSample accession identifiers (SAMN)
- Queries SRA to derive run accessions (SRR)
- Writes accession lists to stage‑specific output files

## Outputs
```text
output/1_get_accessions/
├── biosample_uids.txt
├── biosample_docsum.xml
├── biosample_samn_accessions.txt
└── biosample_srr_accessions.txt
```

### Guarantees
- Deterministic accession discovery for a given BioProject
- Explicit failure if no accessions are found
- Output files are overwritten on each run
- Assumes all EDirect tools were validated in preflight

## `2_download_sra.sh`
Downloads `.sra` files for each SRR accession.

### Inputs
- SRR accession list from `1_get_accessions.sh`
- SRA Toolkit (`prefetch`, `vdb-config`, validated in preflight)
- Network access on the login node

### Expected Input Layout
```text
output/1_get_accessions/
└── biosample_srr_accessions.txt
```

### Workflow
- Reads SRR accessions sequentially
- Normalizes and validates each accession ID
- Creates a per‑SRR output directory
- Configures a per‑SRR VDB configuration file
- Downloads the `.sra` file using prefetch
- Skips accessions that have already been downloaded
- Aborts immediately on download failure

### Outputs
```text
output/2_download_sra/
└── SRRXXXXXXXX/
    ├── SRRXXXXXXXX.sra
    └── .vdb-config
```

### Guarantees
- No shared state between accessions
- Per‑accession configuration isolation
- Restart‑safe behavior (already‑downloaded runs are skipped)
- Deterministic directory layout
- Assumes all SRA Toolkit requirements were satisfied in preflight

# Notes
- All module scripts assume that preflight validation has already succeeded
- No module installs software or modifies user environment files
- All filesystem paths are absolute and derived from pipeline context
- No module requires interactive user input
- The pipeline is safe to re‑run to resume partial downloads
- FASTQ conversion is intentionally handled by a separate downstream pipeline