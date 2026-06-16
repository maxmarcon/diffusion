FROM python:3.11-slim

RUN apt-get update && \
    apt-get install curl git -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR /diffusion
COPY .python-version ./
COPY pyproject.toml ./
COPY uv.lock ./
COPY train_unconditional.py ./

ENTRYPOINT [ "bash" ]

