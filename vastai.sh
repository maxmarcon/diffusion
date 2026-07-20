#!/usr/bin/env bash
set -exuo pipefail


TRAIN_DATASET=klimt.tar.gz
TRAIN_ARGS="--push_to_hub --hub_model_id=klimt-diffusion"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <port> <remote host>" >&2
  exit 1
fi

PORT=$1
HOST=$2

FILES=(pyproject.toml uv.lock train_unconditional.py train.sh data/*.gz .env)

scp -rP ${PORT} ${FILES[@]} ${HOST}:/workspace

ssh -L 6007:localhost:6007 -tp "${PORT}" "${HOST}" "tmux new-session -s diffusion \"cd /workspace && ./train.sh ${TRAIN_DATASET} ${TRAIN_ARGS} 2>&1 | tee ./train-output.log\""

# tensorboard --logdir ddpm-model-64 --port 6007