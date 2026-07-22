#!/usr/bin/env bash
set -euo pipefail


TRAIN_DATASET=klimt.tar.gz
TRAIN_ARGS="--push_to_hub --hub_model_id=klimt-diffusion"

function usage() {
  echo "Usage: $0 -p <port> <remote host>" >&2
  exit 1
}

PORT=

while getopts "p:h" option; do 
    case "${option}" in 
        p)
            PORT=$OPTARG
            ;;
        h)
            usage
            ;;
    esac
done

HOST=${@:$OPTIND:1}

if [[ -z "$PORT" ]] || [[ -z "$HOST" ]]; then 
    usage
fi

FILES=(pyproject.toml uv.lock train_unconditional.py train.sh data/*.gz .env)

scp -rP ${PORT} ${FILES[@]} ${HOST}:/workspace

ssh -L 6007:localhost:6007 -tp "${PORT}" "${HOST}" "tmux new-session -s diffusion \"cd /workspace && ./train.sh ${TRAIN_DATASET} ${TRAIN_ARGS} 2>&1 | tee ./train-output.log\""

# tensorboard --logdir ddpm-model-64 --port 6007