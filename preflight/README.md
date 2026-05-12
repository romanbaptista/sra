# `preflight`

This directory contains the preflight validation layer for the `sra-download` pipeline.

Preflight scripts are responsible for all validation and environment checks required to safely execute the pipeline on an HPC login node inside a persistent tmux session.

No pipeline modules are executed unless all preflight checks succeed.

Preflight scripts are sourced and executed by `run_pipeline.sh` on the login node before any network access or data download occurs.

# Design Contract
All preflight scripts adhere to the following principles:
- Fail‑fast validation before any pipeline execution
- No side effects beyond controlled, deterministic tool installation
- Clear and actionable error messages
- Deterministic checks with no reliance on execution order beyond orchestration
- Validation only — no pipeline execution logic
- Centralized enforcement of pipeline invariants

Once preflight validation completes successfully, downstream scripts may assume:
- All required configuration variables, tools, commands, and directories are valid and usable.

# Responsibilities of Preflight
The preflight layer ensures that:
- User configuration is complete and non‑empty
- Pipeline module scripts exist, are non‑empty, and executable
- Required framework‑level commands are available on the system
- Required toolchains (EDirect and SRA Toolkit) are installed and usable
- Tool installations are reproducible and environment files are written

This avoids late‑stage download failures and prevents partially‑executed pipelines caused by missing dependencies or misconfiguration.

# Preflight Script Overview
The set and execution order of all preflight scripts is centrally defined in:
```text
utils/arrays.sh  → PREFLIGHT_ARRAY
```

`preflight/preflight.sh` sources and executes each script listed in `PREFLIGHT_ARRAY` sequentially, terminating immediately on failure.

Current preflight order:

```text
preflight_variables.sh
preflight_scripts.sh
preflight_commands.sh
preflight_edirect.sh
preflight_sratoolkit.sh
```

## `preflight_variables.sh`
Validates core user‑defined configuration variables.

### Responsibilities
Confirms all required configuration variables are:
- Defined in `config.sh`
- Non‑empty

Variables validated here include:
- `BIOPROJECT`
- `TMUX_SESSION_NAME`

This script ensures that the pipeline has sufficient user input to perform accession discovery and data acquisition.

## `preflight_scripts.sh`
Validates pipeline module integrity.

### Responsibilities
- Confirms all expected module scripts exist in `modules/`
- Verifies that each module script is non‑empty
- Ensures each module script is executable (setting permissions if required)
- Confirms presence and integrity of `modules/pipeline.sh`

This prevents execution of incomplete, corrupted, or non‑executable module code.

## `preflight_commands.sh`
Validates required framework‑level external commands.

### Responsibilities
- Confirms availability of all non‑tool‑specific commands used by the pipeline
- Uses strict `PATH`‑based validation via check_command

Commands validated here include:
- Shell and filesystem utilities
- Networking and archive tools
- `tmux` session management commands

Tool‑specific binaries (e.g. EDirect and SRA Toolkit executables) are intentionally excluded and handled by dedicated tool preflight scripts.

## `preflight_edirect.sh`
Validates and installs NCBI EDirect.

### Responsibilities
- Confirms the esearch executable is available and usable
- Determines the EDirect installation directory
- Installs EDirect if missing
- Writes a reproducible environment file (`env/edirect.env`) exporting PATH updates

Once this script completes successfully, downstream code may assume all required EDirect tools are available.

## `preflight_sratoolkit.sh`
Validates and installs the SRA Toolkit.

### Responsibilities
- Confirms a coherent SRA Toolkit installation is available
- Verifies toolkit version compatibility
- Downloads and installs the toolkit if missing or incorrect
- Writes a reproducible environment file (`env/sratoolkit.env`)
- Ensures prefetch and vdb-config are available for downstream use

This script centralizes all SRA Toolkit invariants so that module scripts do not repeat validation logic.

# Execution Model
All preflight scripts are:
- Executed on the login node
- Sourced into the same shell for shared context
- Terminated immediately on failure

The pipeline does not proceed unless all applicable preflight scripts complete successfully.

# Invariants Guaranteed After Preflight
After preflight completes, downstream pipeline stages may assume:
- Configuration variables are set and non‑empty
- Required commands are available on `PATH`
- EDirect is installed and usable
- SRA Toolkit is installed, version‑correct, and usable
- Tool environment files exist and can be safely sourced
- Module scripts exist, contain data, and are executable

This contract enforces a clean separation between validation and execution throughout the pipeline.

# Notes
- Preflight scripts are not intended to be run directly by end users
- Tool installation performed during preflight is deterministic and restart‑safe
- All validation logic is centralized; module scripts do not repeat checks
- Any modification to configuration or pipeline code requires rerunning preflight