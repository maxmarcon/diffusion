#!/usr/bin/env bash
set -euo pipefail

DATASETDIR=./tmp_data_dir

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <dataset.tar.gz> [train_unconditional.py options...]" >&2
  exit 1
fi

set -a
source .env
set +a

if [[ -z ${HF_TOKEN:-} ]] && [[ "$@" =~ "--push_to_hub" ]]; then
    echo "No HF_TOKEN found!"
    exit 1
fi


archive_file="$1"
shift

if [[ ! -f "$archive_file" ]]; then
  echo "Dataset archive not found: $archive_file" >&2
  exit 1
fi

mkdir -p "${DATASETDIR}"

echo "Extracting dataset archive: $archive_file to ${DATASETDIR}"
tar -xzf "$archive_file" -C "${DATASETDIR}"

set -x
uv run "./train_unconditional.py" \
  --train_data_dir "${DATASETDIR}" \
  "$@"

