---
name: hf-cli
description: Use the `hf` CLI tool to interact with Hugging Face Hub — downloading models/datasets, uploading files, managing repos, running jobs, and managing authentication and cache. Use when the user wants to work with Hugging Face Hub from the command line.
---

# hf CLI — Hugging Face Hub CLI

The `hf` command is the official CLI for Hugging Face Hub.

## Authentication

```bash
hf auth login                          # Interactive login (prompts for token)
hf auth login --token hf_xxx          # Login with token directly
hf auth login --add-to-git-credential # Also save token to git credentials
hf auth logout                         # Logout current token
hf auth logout --token-name mytoken   # Logout specific named token
hf auth whoami                         # Show current logged-in user
hf auth list                           # List all stored tokens
hf auth switch                         # Interactive switch between tokens
hf auth switch --token-name mytoken   # Switch to specific token
```

Token from: https://huggingface.co/settings/tokens
Env var alternative: `HF_TOKEN=hf_xxx hf <command>`

## Download

```bash
hf download username/repo-name                          # Download entire repo (model by default)
hf download username/repo-name config.json              # Download specific file
hf download username/repo-name "*.safetensors"          # Download matching files
hf download username/repo-name --repo-type dataset      # Download dataset
hf download username/repo-name --repo-type space        # Download space
hf download username/repo-name --revision main          # Specific branch/tag/commit
hf download username/repo-name --local-dir ./my-model   # Download to specific dir (not cache)
hf download username/repo-name --cache-dir /tmp/cache   # Custom cache dir
hf download username/repo-name --include "*.json"       # Include glob pattern
hf download username/repo-name --exclude "*.bin"        # Exclude glob pattern
hf download username/repo-name --force-download         # Re-download even if cached
hf download username/repo-name --quiet                  # Suppress progress bars
hf download username/repo-name --max-workers 4          # Parallel workers (default: 8)
```

`--repo-type`: `model` (default), `dataset`, `space`

## Upload

For single-commit uploads:

```bash
hf upload username/repo-name ./local-file.bin          # Upload single file
hf upload username/repo-name ./local-folder            # Upload folder
hf upload username/repo-name ./file.bin path/in/repo   # Upload to specific path in repo
hf upload username/repo-name --repo-type dataset       # Upload to dataset repo
hf upload username/repo-name --private                 # Create private repo if new
hf upload username/repo-name --revision mybranch       # Push to specific branch
hf upload username/repo-name --create-pr               # Upload as a PR
hf upload username/repo-name --include "*.safetensors" # Only upload matching files
hf upload username/repo-name --exclude "*.tmp"         # Exclude matching files
hf upload username/repo-name --delete "old/*.bin"      # Delete files while committing
hf upload username/repo-name --commit-message "Update" # Custom commit message
hf upload username/repo-name --every 5                 # Auto-commit every 5 minutes
hf upload username/repo-name --quiet                   # Suppress progress bars
```

## Upload Large Folder (resumable)

For large uploads that may need to resume:

```bash
hf upload-large-folder username/repo-name ./large-folder
hf upload-large-folder username/repo-name ./folder --repo-type dataset
hf upload-large-folder username/repo-name ./folder --num-workers 4
hf upload-large-folder username/repo-name ./folder --include "*.bin"
hf upload-large-folder username/repo-name ./folder --exclude "*.tmp"
hf upload-large-folder username/repo-name ./folder --no-report  # Disable status reports
hf upload-large-folder username/repo-name ./folder --no-bars    # Disable progress bars
```

## Cache Management

Default cache: `~/.cache/huggingface/hub`

```bash
hf cache scan                          # Show cached models/datasets
hf cache scan -v                       # Verbose (show all revisions)
hf cache scan --dir /custom/cache      # Scan custom cache dir
hf cache delete                        # Interactive TUI to select and delete revisions
hf cache delete --disable-tui         # Non-interactive mode (pipe-friendly)
hf cache delete --sort size           # Sort by: alphabetical, lastUpdated, lastUsed, size
hf cache delete --dir /custom/cache   # Delete from custom cache dir
```

## Repo Management

```bash
# Create repos
hf repo create username/my-model                           # Create model repo
hf repo create my-dataset --repo-type dataset              # Create dataset
hf repo create my-space --repo-type space --space_sdk gradio  # Create space
hf repo create username/repo --private                     # Create private repo
hf repo create username/repo --exist-ok                    # No error if exists

# Tags
hf repo tag create username/repo v1.0                      # Create tag
hf repo tag create username/repo v1.0 --revision mybranch  # Tag specific revision
hf repo tag create username/repo v1.0 -m "Release 1.0"    # Tag with message
hf repo tag list username/repo                             # List all tags
hf repo tag delete username/repo v1.0                      # Delete tag
hf repo tag delete username/repo v1.0 -y                   # Skip confirmation
```

`--repo-type` for tag commands: `model` (default), `dataset`, `space`

## Repo Files

```bash
hf repo-files delete username/repo "old_file.bin"          # Delete file
hf repo-files delete username/repo "*.tmp" "*.bak"         # Delete by glob patterns
hf repo-files delete username/repo "data/" --repo-type dataset
hf repo-files delete username/repo "file.bin" --create-pr  # Delete via PR
hf repo-files delete username/repo "file.bin" --revision branch
```

## Jobs (HF Infrastructure)

Run Docker or Python scripts on Hugging Face infrastructure.

```bash
# List/inspect jobs
hf jobs ps                             # List running jobs
hf jobs ps -a                          # List all jobs (including stopped)
hf jobs ps --namespace myorg          # Jobs in org namespace
hf jobs inspect JOB_ID                # Detailed info on job(s)
hf jobs logs JOB_ID                   # Stream logs from a job
hf jobs cancel JOB_ID                 # Cancel a job

# Run Docker image
hf jobs run python:3.11 python -c "print('hello')"
hf jobs run --flavor t4-small myimage python train.py
hf jobs run -e KEY=val -e OTHER=val myimage ./script.sh
hf jobs run --env-file .env myimage ./run.sh
hf jobs run -s SECRET_KEY=val myimage ./secure.sh
hf jobs run --timeout 30m myimage ./script.sh
hf jobs run -d myimage ./script.sh    # Detach (background), prints job ID
```

Hardware flavors: `cpu-basic` (default), `cpu-upgrade`, `cpu-xl`, `t4-small`, `t4-medium`, `l4x1`, `l4x4`, `l40sx1`, `l40sx4`, `l40sx8`, `a10g-small`, `a10g-large`, `a10g-largex2`, `a10g-largex4`, `a100-large`, `h100`, `h100x8`

```bash
# Run UV Python scripts (inline dependencies)
hf jobs uv run script.py              # Run local script on HF infra
hf jobs uv run https://example.com/script.py  # Run script from URL
hf jobs uv run --flavor t4-small script.py
hf jobs uv run --with numpy --with pandas script.py  # Extra packages
hf jobs uv run -p 3.12 script.py     # Specific Python version
hf jobs uv run -d script.py          # Detach (background)
hf jobs uv run --timeout 1h script.py
```

## Utility Commands

```bash
hf env      # Print environment info (token, cache dir, versions)
hf version  # Print hf version
```

## Common Workflows

**Download a model to a local dir (no cache):**
```bash
hf download mistralai/Mistral-7B-v0.1 --local-dir ./mistral-7b
```

**Upload a fine-tuned model:**
```bash
hf upload myusername/my-finetuned-model ./output/ --commit-message "Add fine-tuned weights"
```

**Clean up large cached models:**
```bash
hf cache scan -v
hf cache delete --sort size
```

**Run a GPU training job:**
```bash
hf jobs run --flavor a10g-large pytorch/pytorch:latest python train.py -e WANDB_KEY=$WANDB_KEY -d
hf jobs logs <JOB_ID>
```
