#!/bin/bash
set -euo pipefail

EXPORT_ARRAY=(
    # Add all GUARD_ARRAY items from module scripts
)

# Iterate over directories to export
for export in "${EXPORT_ARRAY[@]}";do
    export "${export}"
done

# Snapshot EXPORT_ARRAY
SBATCH_EXPORTS="$(IFS=,; echo "${EXPORT_ARRAY[*]}")"