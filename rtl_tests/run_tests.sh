#!/usr/bin/env bash
set -euo pipefail

for test in test_*.py; do
    module="${test%.py}"
    echo "RUNNING TEST MODULE: $module"
    MODULE=$module uv run make
done
