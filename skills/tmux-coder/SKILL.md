---
name: tmux-coder
description: "Spawn, monitor, and manage coding agents in tmux windows. Use to orchestrate parallel coding agents, check their status, detect stuck agents, and manage tmux sessions."
license: MIT
metadata:
  author: verfeinerer
  version: 1.0.0
  created: 2026-04-17
  last_reviewed: 2026-04-17
  review_interval_days: 90
---

# /tmux-coder — Orchestrate Coding Agents via Tmux

You are an orchestration expert. Your job is to spawn, monitor, and manage coding agents running in separate tmux windows within a single session.

## Trigger

User invokes `/tmux-coder` followed by their intent:

```
/tmux-coder start a new agent that reviews the files in src/
/tmux-coder what are my agents doing?
/tmux-coder ensure that the agents keep doing their task
/tmux-coder kill the current session
/tmux-coder list all active sessions
```

## Core Workflows

### 1. Spawn a New Agent

```bash
./scripts/tmux-spawn-agent --session SESSION --agent AGENT --task "TASK_DESCRIPTION"
```

- Adds a new window to the session with an auto-generated label (e.g., `worker-1`, `reviewer-2`)
- Starts the specified agent binary in that window
- Sends the task description via tmux send-keys
- Injects "TASK_COMPLETE" as the finish-string instruction

### 2. List Active Sessions

```bash
./scripts/tmux-list-sessions [--all]
```

- Lists tmux sessions managed by this skill
- Without `--all`: shows only sessions tracked in `~/.tmux-coder/sessions.json`
- With `--all`: shows all tmux sessions on the default socket

### 3. Check Agent Status

```bash
./scripts/tmux-agent-status --session SESSION
```

- Outputs structured status information

### 4. Ensure Progress (Background Watcher)

```bash
./scripts/tmux-ensure-progress --session SESSION --stuck-prompt "Please continue working autonomously"
```

- Runs continuously in the background
- Detects stuck agents (3 consecutive identical snapshots)
- Sends recovery prompt to stuck agents
- Exits when all agents report "TASK_COMPLETE"

### 5. Kill Session

```bash
./scripts/tmux-kill-session --session SESSION
```

- Terminates the tmux session and all its windows

## Session Management

- **Naming**: User-provided or auto-generated (e.g., `orchestration-20260417-143052`)
- **Resumption**: Run `tmux-list-sessions` to find existing sessions, then use `tmux-agent-status` or `tmux-ensure-progress`
- **Metadata**: Stored in `~/.tmux-coder/sessions.json` for tracking managed sessions

## Supported Agents

- `pi` — Pi coding agent
- `claude` — Claude CLI
- `codex` — Codex CLI
- `opencode` — OpenCode CLI

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `TMUX_CODER_SOCKET_DIR` | `${TMPDIR:-/tmp}/tmux-coder-sockets` | Socket directory |
| `TMUX_CODER_STATE_DIR` | `~/.tmux-coder` | Session metadata directory |
| `STABLE_ROUNDS` | `3` | Consecutive identical snapshots before declaring stuck |
| `INTERVAL` | `10` | Seconds between status checks |
| `STUCK_PROMPT` | `"Please continue working autonomously"` | Default recovery prompt |

## Reference Documents

| Topic | File |
|-------|------|
| Detailed script usage and examples | `references/usage-guide.md` |
| Script internals and error handling | `references/script-internals.md` |
