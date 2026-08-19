from huggingface_hub import snapshot_download, HfApi
import argparse, logging

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def latest_checkpoint_folder(repo_items) -> str | None:
    checkpoints = [
        item.path for item in repo_items if item.path.startswith("checkpoint-")
    ]
    checkpoints.sort(key=lambda x: int(x.split("-")[-1]), reverse=True)
    return checkpoints[0] if len(checkpoints) > 0 else None


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--resume_from_checkpoint",
        type=str,
        default=None,
    )

    parser.add_argument(
        "--output_dir",
        type=str,
        default="ddpm-model-64",
    )
    parser.add_argument(
        "--hub_model_id",
        type=str,
        default=None,
        help="The name of the repository to keep in sync with the local `output_dir`.",
    )

    args, _ = parser.parse_known_args()

    if checkpoint := args.resume_from_checkpoint:
        if (repo_id := args.hub_model_id) is None:
            raise RuntimeError(
                "you need to specify hub_model_id when resuming from a checkpoint"
            )

        api = HfApi()
        repo_items = api.list_repo_tree(repo_id=repo_id)
        checkpoint = (
            latest_checkpoint_folder(repo_items)
            if checkpoint == "latest"
            else checkpoint
        )
        if checkpoint is None:
            raise RuntimeError("couldn't identify latest checkpoint")
        logging.info(f"downloading {checkpoint} to {args.output_dir}")
        snapshot_download(
            repo_id=repo_id,
            local_dir=args.output_dir,
            allow_patterns=f"{checkpoint}/**",
        )
