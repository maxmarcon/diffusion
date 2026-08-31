FROM python:3.11-slim

RUN apt-get update && \
    apt-get install curl git -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh

WORKDIR /diffusion


# Make uv globally available
RUN cp /root/.local/bin/uv /usr/local/bin/uv

RUN adduser --system --no-create-home --ingroup root diffusion
RUN chown diffusion /diffusion
USER diffusion 

COPY .python-version ./
COPY pyproject.toml ./
COPY uv.lock ./


ENV HOME=/diffusion
RUN uv sync

COPY train_unconditional.py ./
COPY maybe_fetch_checkpoint.py ./
COPY train.sh ./
COPY inference.ipynb ./

ENTRYPOINT [ "uv", "run", "jupyter-lab", "--no-browser", "--ip='*'", "--ServerApp.token=''", "--ServerApp.password=''" ]

