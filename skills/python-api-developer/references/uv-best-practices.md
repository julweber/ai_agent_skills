# uv: Python Dependency Management — Best Practices Knowledge Seed

> **Purpose:** This document is a knowledge seed for coding agents. It captures
> the authoritative best practices, command patterns, and configuration idioms
> for `uv`, the fast Rust-based Python package manager by Astral.
> Use it as the primary reference before writing, editing, or reviewing any
> Python project that uses `uv`.

---

## Table of Contents

1. [What is uv?](#1-what-is-uv)
2. [Installation](#2-installation)
3. [Core Mental Model](#3-core-mental-model)
4. [Project Lifecycle](#4-project-lifecycle)
5. [Dependency Management](#5-dependency-management)
6. [Lock Files](#6-lock-files)
7. [Virtual Environments](#7-virtual-environments)
8. [Python Version Management](#8-python-version-management)
9. [Running Commands and Scripts](#9-running-commands-and-scripts)
10. [Tool Management (pipx Replacement)](#10-tool-management-pipx-replacement)
11. [Dependency Groups (dev / optional)](#11-dependency-groups-dev--optional)
12. [Workspaces (Monorepos)](#12-workspaces-monorepos)
13. [Docker Integration](#13-docker-integration)
14. [CI/CD Integration](#14-cicd-integration)
15. [pip-Compatibility Mode](#15-pip-compatibility-mode)
16. [Pre-commit Hooks](#16-pre-commit-hooks)
17. [Configuration Reference (pyproject.toml)](#17-configuration-reference-pyprojecttoml)
18. [Migration Cheatsheet](#18-migration-cheatsheet)
19. [Anti-Patterns to Avoid](#19-anti-patterns-to-avoid)
20. [Sources and References](#20-sources-and-references)

---

## 1. What is uv?

`uv` is an extremely fast Python package manager and project management tool
written in Rust, developed by Astral (the team behind `ruff`). It replaces an
entire stack of traditional Python tooling:

| Replaced tool | uv equivalent |
|---|---|
| `pip` | `uv pip install` / `uv add` |
| `pip-tools` | `uv pip compile` / `uv lock` |
| `virtualenv` / `venv` | `uv venv` |
| `pyenv` | `uv python install` / `uv python pin` |
| `pipx` | `uv tool install` / `uvx` |
| `poetry` / `PDM` / `Rye` | `uv` project management |

**Performance:** uv is 10–100× faster than pip due to its Rust implementation,
parallel downloads, global module cache, copy-on-write hard links, and
optimized metadata fetching (range requests instead of downloading entire wheels).

- Official docs: https://docs.astral.sh/uv/
- GitHub: https://github.com/astral-sh/uv
- Astral announcement blog: https://astral.sh/blog/uv-unified-python-packaging

---

## 2. Installation

### Recommended: standalone installer (no Python required)

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### Alternative methods

```bash
# via pip (system-wide; not recommended for most setups)
pip install uv

# via Homebrew (macOS/Linux)
brew install uv

# via pipx
pipx install uv
```

### Self-update

```bash
uv self update
```

### Verify installation

```bash
uv version
# uv 0.x.y (...)
```

> **Best Practice:** Use the standalone installer so that `uv` has no
> dependency on any Python installation and is globally available regardless
> of which Python environment is active.

---

## 3. Core Mental Model

Understanding uv's two usage tiers prevents confusion:

### Tier 1 — Project management (preferred)

Uses `pyproject.toml` + `uv.lock`. This is the "Cargo for Python" model.

```
uv init → uv add → uv sync → uv run
```

### Tier 2 — pip-compatibility mode (migration / legacy)

A drop-in for `pip` / `pip-tools` workflows, scoped under `uv pip`.

```
uv pip install / uv pip compile / uv pip sync
```

**Rule for agents:** Default to Tier 1 (project management) for all new
projects. Use Tier 2 only when integrating with tools that expect
`requirements.txt` or when migrating an existing codebase incrementally.

---

## 4. Project Lifecycle

### Initialize a new project

```bash
uv init my-project          # creates directory, pyproject.toml, .python-version, README, .gitignore
cd my-project

uv init --lib my-library    # for a publishable library (adds src/ layout)
uv init --app my-app        # for an application (default)
```

### Resulting structure

```
my-project/
├── .gitignore
├── .python-version          # pinned Python version
├── README.md
├── pyproject.toml           # project metadata + dependencies
├── uv.lock                  # generated lock file (commit this!)
└── src/
    └── my_project/
        └── __init__.py
```

### Clone and set up an existing project

```bash
git clone <repo>
cd <repo>
uv sync                      # installs exact versions from uv.lock
```

---

## 5. Dependency Management

### Add a runtime dependency

```bash
uv add requests
uv add "fastapi>=0.100"
uv add "django>=4.2,<5.0"
```

`uv add` atomically:
1. Adds the package to `[project.dependencies]` in `pyproject.toml`
2. Updates `uv.lock`
3. Syncs the virtual environment

### Remove a dependency

```bash
uv remove requests
```

### Add a development dependency

```bash
uv add --dev pytest ruff mypy
```

### Add to a named dependency group

```bash
uv add --group docs sphinx
uv add --group test pytest pytest-cov
```

### Add optional dependencies (extras / published packages)

```bash
uv add --optional viz matplotlib seaborn
```

### Update dependencies

```bash
uv lock --upgrade                      # upgrade all to latest within constraints
uv lock --upgrade-package requests     # upgrade one package only
```

### Inspect dependencies

```bash
uv tree                  # dependency tree
uv pip list              # installed packages
uv pip show requests     # details for a package
```

### Declare constraints without installing

Edit `pyproject.toml` directly, then run:

```bash
uv lock     # update lock file only (no install)
uv sync     # update lock file and install
```

### Platform-specific dependencies (environment markers)

```toml
[project]
dependencies = [
  "pywin32>=306; sys_platform == 'win32'",
  "uvloop>=0.19; sys_platform != 'win32'",
]
```

### Custom package indexes

```bash
uv add torch --index pytorch=https://download.pytorch.org/whl/cpu
```

This writes to `[[tool.uv.index]]` and `[tool.uv.sources]` in `pyproject.toml`.

---

## 6. Lock Files

### Key facts

- `uv.lock` is a cross-platform, human-readable lockfile in TOML format.
- It pins **all** transitive dependencies to exact versions and hashes.
- **Always commit `uv.lock` to version control** for applications.
- For libraries intended for distribution, committing the lockfile is optional
  but still recommended for reproducible CI.

### Core operations

```bash
uv lock              # generate or refresh uv.lock (no install)
uv sync              # install from uv.lock (may update it if stale)
uv sync --locked     # strict: error if uv.lock is not up-to-date
uv sync --frozen     # skip lockfile staleness check entirely (fastest; use in Docker)
```

### Export to requirements.txt (for legacy tooling)

```bash
uv export --output-file requirements.txt --no-dev
uv export --output-file dev-requirements.txt --only-dev
```

### Upgrade workflow

```bash
uv lock --upgrade                        # upgrade all
uv lock --upgrade-package <pkg>          # upgrade one
uv add "requests>=2.32" --upgrade-package requests  # constrain + upgrade
```

> **Best Practice for CI/CD:** Use `uv sync --locked` or `uv sync --frozen`
> in automated pipelines to guarantee the lock file is respected and no
> surprise upgrades occur.

---

## 7. Virtual Environments

uv places the virtual environment in `.venv/` at the project root by default.

### Automatic management (recommended)

With project commands (`uv run`, `uv sync`, `uv add`), uv creates and manages
`.venv` automatically. You rarely need to activate the environment manually.

### Manual creation

```bash
uv venv                         # creates .venv/ with default Python
uv venv --python 3.12           # specify Python version
uv venv .venv-test              # custom location/name
```

### Activation (when needed)

```bash
source .venv/bin/activate        # macOS / Linux
.venv\Scripts\activate           # Windows
```

### Best practices for IDEs

Point your IDE (VS Code, PyCharm) at `.venv/` in the project root. uv's venv
is standards-compliant and works with any tool.

```bash
uv sync    # always sync before opening the project to ensure the venv is fresh
```

---

## 8. Python Version Management

### Install Python versions

```bash
uv python install 3.12
uv python install 3.12 3.13 3.14    # multiple at once
uv python list                       # list available / installed versions
```

### Pin a project to a Python version

```bash
uv python pin 3.12     # writes to .python-version file
```

The `.python-version` file should be committed. uv reads it automatically.

### Specify Python in pyproject.toml

```toml
[project]
requires-python = ">=3.11"
```

### Run with a specific Python

```bash
uv run --python 3.12 python script.py
uv venv --python 3.11
```

> **Best Practice:** Always set `requires-python` in `pyproject.toml` and
> commit `.python-version`. uv will auto-download the correct Python version
> if it is not installed — no separate pyenv needed.

---

## 9. Running Commands and Scripts

### Run a command in the project environment

```bash
uv run python script.py
uv run pytest
uv run -- python -m mymodule arg1 arg2
```

`uv run` automatically:
- Creates `.venv` if missing
- Syncs all dependencies from `uv.lock`
- Executes the command in the environment

> **Best Practice:** Replace every `python` invocation in scripts and Makefiles
> with `uv run python`. This eliminates forgotten `source .venv/bin/activate`
> steps.

### Inline script dependencies (PEP 723 — single-file scripts)

```python
# /// script
# requires-python = ">=3.11"
# dependencies = ["requests", "rich"]
# ///
import requests
from rich import print
print(requests.get("https://example.com").status_code)
```

```bash
uv run my_script.py              # installs deps in an isolated env and runs
uv add --script my_script.py requests rich   # add deps to the inline metadata
```

This pattern is ideal for standalone automation scripts shared across teams.

---

## 10. Tool Management (pipx Replacement)

### Run a tool ephemerally (no install)

```bash
uvx ruff check .
uvx black --check .
uvx pycowsay "hello"
```

`uvx` is an alias for `uv tool run`. The tool runs in an isolated, disposable
virtual environment.

### Install a tool globally

```bash
uv tool install ruff
uv tool install black
ruff --version    # now available on PATH
```

### Upgrade tools

```bash
uv tool upgrade ruff
uv tool upgrade --all
```

### List installed tools

```bash
uv tool list
```

> **Best Practice:** For CI, prefer `uvx <tool>` to avoid polluting the global
> tool namespace and to always use the latest version. For local development,
> `uv tool install` makes frequently used tools persistent.

---

## 11. Dependency Groups (dev / optional)

### Standard dependency groups (PEP 735)

```toml
[dependency-groups]
dev = [
  { include-group = "lint" },
  { include-group = "test" },
]
lint = ["ruff>=0.6", "mypy>=1.10"]
test = ["pytest>=8.0", "pytest-cov"]
docs = ["sphinx>=7.0", "myst-parser"]
```

### Working with groups

```bash
uv sync                          # installs project + dev group (default)
uv sync --no-dev                 # production: no dev deps
uv sync --group docs             # add docs group
uv sync --only-group test        # test deps only (no project install)
uv sync --all-groups             # all groups

uv run --no-dev pytest           # run without dev deps
```

### Optional dependencies (for published packages / extras)

```toml
[project.optional-dependencies]
viz = ["matplotlib>=3.8", "seaborn"]
async = ["aiohttp>=3.9"]
```

```bash
uv add --optional viz matplotlib seaborn
uv sync --extra viz
pip install mypackage[viz]       # consumers install extras this way
```

> **Best Practice:** Use `[dependency-groups]` for internal dev tooling (pytest,
> ruff, mypy). Use `[project.optional-dependencies]` for features that end-users
> of your published library might want.

---

## 12. Workspaces (Monorepos)

uv supports Cargo-style workspaces, where multiple packages share one
`uv.lock` file at the workspace root.

### Root `pyproject.toml`

```toml
[build-system]
requires = ["uv_build>=0.9,<0.10"]
build-backend = "uv_build"

[tool.uv.workspace]
members = ["packages/*", "apps/*", "libs/*"]
exclude = ["packages/legacy"]
```

### Member `pyproject.toml` (e.g. `apps/server/pyproject.toml`)

```toml
[project]
name = "server"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = ["fastapi>=0.110", "shared-lib"]

[tool.uv.sources]
shared-lib = { workspace = true }     # reference another workspace member

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Workspace directory layout

```
monorepo/
├── pyproject.toml      # workspace root
├── uv.lock             # single lockfile for all members
├── .python-version
├── apps/
│   └── server/
│       └── pyproject.toml
└── libs/
    └── shared/
        └── pyproject.toml
```

### Useful workspace commands

```bash
uv sync                            # sync all members
uv sync --package server           # sync only 'server'
uv sync --all-packages             # explicit all
uv run --package server pytest     # run tests for one member
uv add requests --package server   # add dep to a specific member
```

> **Best Practice:** Use `uv_build` as the workspace root's build backend.
> Individual members can use `hatchling`, `setuptools`, etc. Keep global dev
> tools (ruff, pyright, pytest) in the root `pyproject.toml`'s
> `[dependency-groups]`. Repeat them without version specifiers in each member
> to prevent IDE confusion.

---

## 13. Docker Integration

### Standard single-project Dockerfile

```dockerfile
FROM python:3.12-slim

# Copy uv binary from official image (pins uv version)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Install dependencies first (cached layer)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Copy source and install the project itself
COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

ENV PATH="/app/.venv/bin:$PATH"
CMD ["python", "-m", "myapp"]
```

### Key Docker flags

| Flag | Purpose |
|---|---|
| `--frozen` | Use lockfile as-is; skip staleness check |
| `--no-install-project` | Install deps only, not the project (for layer caching) |
| `--no-dev` | Skip development dependencies |
| `--no-editable` | Install project as a real package (not editable) |
| `--mount=type=cache` | Persist uv cache between builds (huge speedup) |

### Pin the uv version in Docker (production)

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:0.5.4 /uv /uvx /bin/
```

### Workspace Dockerfile pattern

```dockerfile
FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app

# Workspace: use --frozen instead of --locked; add --no-install-workspace
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-workspace

COPY . .
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

ENV PATH="/app/.venv/bin:$PATH"
```

### Environment variables for Docker

```dockerfile
ENV UV_PYTHON_DOWNLOADS=never    # don't download Python; use the image's Python
ENV UV_COMPILE_BYTECODE=1        # compile .pyc at install time (faster startup)
ENV UV_LINK_MODE=copy            # use copy instead of hard links (safer in containers)
```

---

## 14. CI/CD Integration

### GitHub Actions example

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install uv
        uses: astral-sh/setup-uv@v3
        with:
          version: "latest"          # or pin: "0.5.4"
          enable-cache: true         # cache uv's package cache across runs

      - name: Set up Python
        run: uv python install       # uses .python-version

      - name: Install dependencies
        run: uv sync --locked --all-groups

      - name: Run tests
        run: uv run pytest

      - name: Lint
        run: uv run ruff check .

      - name: Type check
        run: uv run mypy .
```

### Key CI best practices

- Always use `uv sync --locked` in CI — never allow silent lock file drift.
- Cache the uv package cache directory (`~/.cache/uv` on Linux) across runs.
- Pin the `uv` version used in CI to match the local version used by the team.
- Use the official `astral-sh/setup-uv` GitHub Action for GitHub Actions.
- In Docker-based CI, use `--mount=type=cache` for the uv cache.

---

## 15. pip-Compatibility Mode

Use this mode when migrating from pip/pip-tools or integrating with legacy tooling.

### Drop-in replacements

```bash
# instead of: pip install requests
uv pip install requests

# instead of: pip install -r requirements.txt
uv pip install -r requirements.txt

# instead of: pip-compile requirements.in
uv pip compile requirements.in -o requirements.txt

# instead of: pip-compile requirements.in --universal (cross-platform lockfile)
uv pip compile requirements.in --universal -o requirements.txt

# instead of: pip-sync requirements.txt (removes unlisted packages)
uv pip sync requirements.txt
```

> **Best Practice:** `uv pip sync` is stricter than `uv pip install` —
> it removes packages not in the requirements file, ensuring an exact
> match with the pinned set. Use `uv pip sync` (not `uv pip install`) when
> you want reproducible, hermetic environments.

---

## 16. Pre-commit Hooks

Keep `pyproject.toml`, `uv.lock`, and exported `requirements.txt` in sync
automatically using `astral-sh/uv-pre-commit`:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.7.18    # pin to a version
    hooks:
      - id: uv-lock                    # re-lock if pyproject.toml changes
      - id: uv-export                  # export requirements.txt after lock
        args:
          - --no-dev
          - --output-file=requirements.txt
          - --no-hashes
```

Install hooks:

```bash
pre-commit install
```

---

## 17. Configuration Reference (pyproject.toml)

### Minimal application

```toml
[project]
name = "my-app"
version = "0.1.0"
description = "A sample application"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110",
    "httpx>=0.27",
]

[dependency-groups]
dev = ["pytest>=8", "ruff>=0.6", "mypy>=1.10"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = []    # deprecated; prefer [dependency-groups]
```

### Library with extras

```toml
[project]
name = "my-lib"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = ["numpy>=1.26"]

[project.optional-dependencies]
plot = ["matplotlib>=3.8"]
dev = ["pytest", "ruff"]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

### Custom index (e.g. private PyPI or PyTorch)

```toml
[[tool.uv.index]]
name = "private"
url = "https://my.pypi.company.com/simple"
default = true          # set as default index

[[tool.uv.index]]
name = "pytorch"
url = "https://download.pytorch.org/whl/cpu"

[tool.uv.sources]
torch = { index = "pytorch" }
```

### Local / editable workspace source

```toml
[tool.uv.sources]
my-lib = { workspace = true }              # another workspace member
my-other-lib = { path = "../other-lib", editable = true }   # local path
experimental = { git = "https://github.com/org/repo", branch = "main" }
```

### uv tool configuration

```toml
[tool.uv]
python-preference = "managed"     # prefer uv-managed Python
cache-dir = "/custom/cache/path"
compile-bytecode = true           # compile .pyc on install
link-mode = "copy"                # copy instead of hardlink (safer in containers)
```

---

## 18. Migration Cheatsheet

### From pip + venv

| Old command | uv equivalent |
|---|---|
| `python -m venv .venv` | `uv venv` (or automatic) |
| `pip install requests` | `uv add requests` |
| `pip install -r requirements.txt` | `uv pip install -r requirements.txt` |
| `pip uninstall requests` | `uv remove requests` |
| `pip freeze > requirements.txt` | `uv export -o requirements.txt` |
| `python script.py` | `uv run python script.py` |

### From pip-tools

| Old command | uv equivalent |
|---|---|
| `pip-compile requirements.in` | `uv pip compile requirements.in -o requirements.txt` |
| `pip-sync requirements.txt` | `uv pip sync requirements.txt` |

### From Poetry

| Old command | uv equivalent |
|---|---|
| `poetry new project` | `uv init project` |
| `poetry add requests` | `uv add requests` |
| `poetry add --dev pytest` | `uv add --dev pytest` |
| `poetry install` | `uv sync` |
| `poetry run pytest` | `uv run pytest` |
| `poetry lock` | `uv lock` |
| `poetry show --tree` | `uv tree` |
| `poetry build` | `uv build` |
| `poetry publish` | `uv publish` |

### From pyenv

```bash
pyenv install 3.12      →   uv python install 3.12
pyenv local 3.12        →   uv python pin 3.12
pyenv global 3.12       →   (uv manages per-project; no global pin needed)
```

---

## 19. Anti-Patterns to Avoid

| Anti-pattern | Correct approach |
|---|---|
| Manually editing `uv.lock` | Never edit manually; run `uv lock` or `uv add` |
| Not committing `uv.lock` | Always commit `uv.lock` for applications |
| Running `pip install` inside a uv-managed project | Use `uv add` or `uv pip install` |
| Using `uv sync` without `--locked` in CI | Use `uv sync --locked` to enforce the lockfile |
| Activating `.venv` manually before `uv run` | Use `uv run` — it handles activation automatically |
| Using `[tool.uv.dev-dependencies]` | Use `[dependency-groups]` (PEP 735 standard) |
| Storing the venv in a central location | Keep `.venv/` local to the project root |
| Using `uv sync` without `--frozen` in Docker | Use `--frozen` in Docker for performance and determinism |
| Installing `uv` via `pip` in Docker | Copy from `ghcr.io/astral-sh/uv:latest` image |
| Running `python` instead of `uv run python` in scripts | Always use `uv run` to ensure env is synced |

---

## 20. Sources and References

- **Official uv documentation:** https://docs.astral.sh/uv/
- **uv GitHub repository:** https://github.com/astral-sh/uv
- **Astral announcement — uv unified packaging:** https://astral.sh/blog/uv-unified-python-packaging
- **Astral announcement — original uv release:** https://astral.sh/blog/uv
- **Official Docker integration guide:** https://docs.astral.sh/uv/guides/integration/docker/
- **Official dependency management docs:** https://docs.astral.sh/uv/concepts/projects/dependencies/
- **Official locking and syncing docs:** https://docs.astral.sh/uv/concepts/projects/sync/
- **Official pip compile docs:** https://docs.astral.sh/uv/pip/compile/
- **Real Python — Managing Python Projects With uv:** https://realpython.com/python-uv/
- **DataCamp — Python UV Ultimate Guide:** https://www.datacamp.com/tutorial/python-uv
- **SaaS Pegasus — uv In-Depth Guide:** https://www.saaspegasus.com/guides/uv-deep-dive/
- **Python Cheatsheet — UV Package Manager:** https://pythoncheatsheet.org/blog/python-uv-package-manager
- **DevToolbox — Complete uv Guide:** https://devtoolbox.dedyn.io/blog/python-uv-packaging-guide
- **geOps — Modern Python Tooling with uv:** https://geops.com/en/blog/modern-python-tooling-with-uv
- **Cracking the Python Monorepo (uv + Dagger):** https://gafni.dev/blog/cracking-the-python-monorepo/
- **Beyond Hypermodern — Monorepo with uv workspaces:** https://rdrn.me/postmodern-python/
- **Python workspaces with uv:** https://tomasrepcik.dev/blog/2025/2025-10-26-python-workspaces/
- **fastapi-best-architecture uv dependency management:** https://deepwiki.com/fastapi-practices/fastapi_best_architecture/12.4-dependency-management-with-uv
- **uv lockfile reproducible environments handbook:** https://pydevtools.com/handbook/how-to/how-to-use-a-uv-lockfile-for-reproducible-python-environments/
- **Move from pip-tools to uv:** https://medium.com/@theomeb/move-from-pip-tools-to-uv-to-lock-python-dependencies-48c5aade1453
- **uv Monorepo example (carderne/postmodern-mono):** https://github.com/carderne/postmodern-mono

---

*Last updated: February 2026. uv is under active development — always check
https://docs.astral.sh/uv/ for the latest commands and configuration options.*