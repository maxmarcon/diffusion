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

ssh -p "${PORT}" "${HOST}" "tmux has-session -t diffusion 2>/dev/null || tmux new-session -d -s diffusion \"cd /workspace && ./train.sh ${TRAIN_DATASET} ${TRAIN_ARGS} 2>&1 | tee ./train-output.log\""

echo "Training started in tmux session 'diffusion'."
echo "Reconnect with: ssh -tp ${PORT} ${HOST} 'tmux attach -t diffusion'"
echo "Logs are being written to ~/logs/train-output.log"

ssh -tp ${PORT} ${HOST} 'tmux attach -t diffusion'