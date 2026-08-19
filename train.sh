#!/usr/bin/env bash
set -euo pipefail

DATASETDIR=./tmp_data_dir

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 [train_unconditional.py options...]" >&2
  exit 1
fi

set -a
source .env
set +a

uv run --no-dev "./maybe_fetch_checkpoint.py" "$@"

if [[ -z ${HF_TOKEN:-} ]] && [[ "$@" =~ "--push_to_hub" ]]; then
    echo "No HF_TOKEN found!"
    exit 1
fi

set -x
uv run --no-dev "./train_unconditional.py" \
  "$@"

