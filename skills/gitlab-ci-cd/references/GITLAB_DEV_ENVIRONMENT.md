# Local GitLab CI/CD Development Environment

Setting up GitLab and GitLab Runner locally for development and testing pipelines without pushing to a remote instance.

## Overview

Running GitLab CE locally with a connected runner enables developers to test pipelines, debug CI/CD configurations, and iterate quickly — all on their machine.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Developer Machine                   │
│                                                  │
│  ┌──────────────┐    ┌──────────────────────┐   │
│  │  GitLab CE    │    │  GitLab Runner       │   │
│  │  (Docker)     │    │  (Native/Binary)     │   │
│  │              │    │                      │   │
│  │  :80 (HTTP)  │◄──►│  :shell executor     │   │
│  │  :22 (SSH)   │    │  :docker executor    │   │
│  │  :5432 (PG)  │    │                      │   │
│  └──────────────┘    └──────────────────────┘   │
│                                                  │
│  ┌────────────────────────────────────────────┐  │
│  │  Local Repository (.gitlab-ci.yml)         │  │
│  └────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

**Data Flow:**
1. Developer commits → local GitLab detects changes
2. GitLab CI triggers pipeline
3. Runner (registered to local GitLab) picks up job
4. Runner executes jobs on localhost (shell) or in containers (docker)

---

## Phase 1: Run GitLab CE Locally

### Create Directory Structure

```bash
mkdir -p ~/gitlab-local/{config,data,logs}
```

### Create docker-compose.yml

```yaml
# ~/gitlab-local/docker-compose.yml
version: '3.8'
services:
  gitlab:
    image: gitlab/gitlab-ce:16.11.5-ce.0
    container_name: gitlab-local
    restart: always
    hostname: 'gitlab-local'
    ports:
      - "80:80"
      - "443:443"
      - "2222:22"
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
        # Disable SSL for local dev
        letsencrypt['enable'] = false
    volumes:
      - ./config:/etc/gitlab
      - ./data:/var/opt/gitlab
      - ./logs:/var/log/gitlab
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 5
```

### Start GitLab

```bash
cd ~/gitlab-local
docker compose up -d
```

> **Note:** First startup takes 5–15 minutes. Watch for "GitLab is ready" in logs.

```bash
docker compose logs -f gitlab
```

### Access GitLab

Open http://localhost in your browser. On first login, set the root password.

---

## Phase 2: Install and Configure GitLab Runner

### Install GitLab Runner

**Ubuntu/Debian:**
```bash
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt-get install gitlab-runner
```

**macOS (Homebrew):**
```bash
brew install gitlab-runner
```

**Windows:**
Download the installer from https://gitlab.com/gitlab-org/gitlab-runner/-/releases

### Register Runner with Local GitLab

1. In GitLab UI: **Settings → CI/CD → Runners → New project runner → Registration token**
2. Register the runner:

```bash
sudo gitlab-runner register \
  --url http://localhost \
  --token <REGISTRATION_TOKEN> \
  --description "local-dev-runner" \
  --executor shell \
  --tag-list "docker,shell" \
  --locked=false \
  --non-interactive
```

### Verify Registration

```bash
sudo gitlab-runner verify
```

---

## Phase 3: Runner Configuration

**Config file:** `/etc/gitlab-runner/config.toml`

```toml
concurrent = 2
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "local-dev-runner"
  url = "http://localhost"
  token = "YOUR_TOKEN"
  executor = "shell"
  shell = "bash"

  # Cache configuration
  [runners.cache]
    Type = "local"
    Path = "/tmp/gitlab-runner/cache"
    ShowStatus = false

  # Security settings for local dev
  [runners.security]
    AllowLocaldir = true
    AllowedDirectories = ["~", "/home", "/tmp"]

[runners.metrics]
  enabled = false
```

### Executor Options

| Executor | Use Case | Docker-in-Docker |
|----------|----------|------------------|
| `shell` | Simple scripts, no containerization needed | No |
| `docker` | Containerized jobs, matches production | Yes (dind) |
| `kubernetes` | Complex parallel jobs | Yes |

For most local development, `shell` is sufficient. Use `docker` when testing jobs that require Docker features.

---

## Phase 4: Local CI/CD Development Workflow

### Tool 1: gitlab-ci-lint (Validate Pipelines Locally)

```bash
# Install
pip install gitlab-ci-lint

# Validate .gitlab-ci.yml locally
gitlab-ci-lint .gitlab-ci.yml

# Validate with remote GitLab API (requires token)
gitlab-ci-lint --remote http://localhost/api/v4 --token <API_TOKEN>
```

### Tool 2: Pipeline Debugging with Debug Mode

Enable trace output in your `.gitlab-ci.yml`:

```yaml
variables:
  CI_DEBUG_TRACE: "true"
```

This prints every command executed by the runner.

### Tool 3: Quick Pipeline Validation Script

```bash
# validate-pipeline.sh
#!/bin/bash
set -e

echo "=== Validating .gitlab-ci.yml ==="
gitlab-ci-lint .gitlab-ci.yml

echo "=== Checking YAML syntax ==="
python -c "import yaml; yaml.safe_load(open('.gitlab-ci.yml'))"

echo "=== Pipeline validation complete ==="
```

---

## Phase 5: Best Practices for Local Development

### 1. Use Local Includes for Modular Pipelines

```yaml
include:
  - local: '.gitlab/ci/base.yml'
  - local: '.gitlab/ci/test.yml'
  - local: '.gitlab/ci/build.yml'
```

### 2. Enable Debug Mode for Troubleshooting

```yaml
variables:
  CI_DEBUG_TRACE: "true"
  RAILS_LOG_LEVEL: "debug"
```

### 3. Use .dockerignore to Optimize Build Context

```
node_modules/
.git/
.env
*.log
```

### 4. Local Runner Service Management

```bash
# Start runner as service
sudo gitlab-runner start

# View runner status
sudo gitlab-runner status

# Check runner logs
sudo journalctl -u gitlab-runner -f

# Restart runner
sudo gitlab-runner restart
```

### 5. Docker Executor for Production-Like Testing

When testing Docker-dependent pipelines locally:

```yaml
# .gitlab-runner/config.toml
[[runners]]
  executor = "docker"
  [runners.docker]
    image = "docker:24-dind"
    privileged = true
    volumes = ["/var/run/docker.sock:/var/run/docker.sock"]
```

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Start GitLab | `docker compose up -d` |
| Stop GitLab | `docker compose down` |
| View GitLab logs | `docker compose logs -f gitlab` |
| Register runner | `sudo gitlab-runner register --url http://localhost --token TOKEN` |
| Run runner | `sudo gitlab-runner run` |
| Validate CI file | `gitlab-ci-lint .gitlab-ci.yml` |
| Check runner status | `sudo gitlab-runner status` |

---

## Source URLs

| Topic | URL |
|-------|-----|
| GitLab CE Docker image | https://hub.docker.com/r/gitlab/gitlab-ce |
| GitLab CE Docker setup guide | https://docs.gitlab.com/omnibus/docker/ |
| GitLab Runner installation | https://docs.gitlab.com/runner/install/ |
| GitLab Runner configuration | https://docs.gitlab.com/runner/configuration/ |
| GitLab Runner executors | https://docs.gitlab.com/runner/executors/ |
| gitlab-ci-lint tool | https://github.com/sztomi/gitlab-ci-lint |
| GitLab CI Lint API | https://docs.gitlab.com/ci/yaml/lint/#ci-lint-api |
| GitLab Runner security settings | https://docs.gitlab.com/runner/security/ |
| Docker-in-Docker (dind) | https://docs.gitlab.com/runner/executors/docker.html#docker-in-docker |
