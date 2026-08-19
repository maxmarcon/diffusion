#!/usr/bin/env bash
set -euo pipefail


TRAIN_DATASET=klimt.tar.gz
TRAIN_ARGS="--push_to_hub --hub_model_id=klimt-diffusion --resolution=256 --num_epochs=1000 --train_batch_size=8 --ddpm_num_inference_steps=100 --resume_from_checkpoint=latest"

function usage() {
  echo "Usage: $0 -p <port> <remote host> <other_options>" >&2
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
REST=${@:$OPTIND+1}

if [[ -z "$PORT" ]] || [[ -z "$HOST" ]]; then 
    usage
fi

FILES=(pyproject.toml uv.lock train_unconditional.py maybe_fetch_repo_snapshot.py train.sh .env)

scp -rP ${PORT} ${FILES[@]} ${HOST}:/workspace

ssh "${REST}" -tp "${PORT}" "${HOST}" "tmux new-session -s diffusion \"cd /workspace && ./train.sh ${TRAIN_DATASET} ${TRAIN_ARGS} 2>&1 | tee ./train-output.log\""

# tensorboard --logdir ddpm-model-64 --port ${TB_PORT}