# tmux-coder Usage Guide

Complete reference for using the tmux-coder skill to orchestrate coding agents.

## Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Orchestrator Session                      │
│                                                             │
│  User: "Start 3 agents to work on feature X in parallel"    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  tmux-spawn-agent --session mywork --agent pi ...   │   │
│  │  tmux-spawn-agent --session mywork --agent claude.. │   │
│  │  tmux-spawn-agent --session mywork --agent codex... │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         tmux-ensure-progress --session mywork       │   │
│  │         (runs in background)                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  User: "What are my agents doing?"                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  tmux-agent-status --session mywork                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  User: "Kill the session when done"                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  tmux-kill-session --session mywork                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Script Reference

### tmux-spawn-agent

Spawn a new coding agent in a dedicated tmux window.

```bash
tmux-spawn-agent --session myproject --agent pi --task "Implement the auth module"
```

**Arguments:**
| Flag | Required | Description |
|------|----------|-------------|
| `-s, --session` | Yes | Session name (creates if not exists) |
| `-a, --agent` | Yes | Agent type: `pi`, `claude`, `codex`, `opencode` |
| `-t, --task` | Yes | Task description for the agent |
| `-f, --finish-string` | No | Completion marker (default: `TASK_COMPLETE`) |

**Example: Parallel feature development**
```bash
# Start three agents working on different parts of the feature
tmux-spawn-agent \
  --session payment-system \
  --agent pi \
  --task "Implement the payment processing module in src/payment.py"

tmux-spawn-agent \
  --session payment-system \
  --agent claude \
  --task "Write unit tests for payment processing in tests/test_payment.py"

tmux-spawn-agent \
  --session payment-system \
  --agent opencode \
  --task "Add API endpoints documentation to docs/api.md"
```

**Example: Code review workflow**
```bash
tmux-spawn-agent \
  --session code-review \
  --agent claude \
  --task "Review all files in src/ for security vulnerabilities"
```

### tmux-list-sessions

List active sessions.

```bash
# List only tracked sessions
tmux-list-sessions

# List all tmux sessions on all sockets
tmux-list-sessions --all
```

**Output:**
```
============================================================
 Tracked Tmux-Coder Sessions
============================================================

  payment-system         ACTIVE    /tmp/tmux-coder-sockets/payment-system.sock
  code-review            DEAD      /tmp/tmux-coder-sockets/code-review.sock
```

### tmux-agent-status

Show current status of all agents in a session.

```bash
tmux-agent-status --session myproject
```


**Flags:**
| Flag | Description |
|------|-------------|
| `-v, --verbose` | Show full last line (not truncated) |
| `-f, --finish-string` | Override completion marker |

### tmux-ensure-progress

Background watcher that monitors agents and recovers stuck ones.

```bash
# Run with defaults
tmux-ensure-progress --session myproject

# Custom settings
tmux-ensure-progress \
  --session myproject \
  --stuck-prompt "Continue working on the task autonomously" \
  --interval 5 \
  --stable-rounds 3
```

**Flags:**
| Flag | Default | Description |
|------|---------|-------------|
| `-s, --session` | Required | Session to monitor |
| `-p, --stuck-prompt` | `"Please continue working autonomously"` | Prompt to send when stuck |
| `-f, --finish-string` | `TASK_COMPLETE` | Completion marker |
| `-i, --interval` | `10` | Seconds between checks |
| `-r, --stable-rounds` | `3` | Consecutive identical snapshots before stuck |
| `-n, --iterations` | `0` (unlimited) | Max iterations before exit |
| `--verbose` | false | Log all pane states |

**Behavior:**
1. Detects agents that haven't changed output for `stable-rounds` iterations
2. Sends the stuck prompt to recover them
3. Exits automatically when all agents report `TASK_COMPLETE`

### tmux-kill-session

Terminate a session and all its agents.

```bash
# Interactive confirmation
tmux-kill-session --session myproject

# Force kill without confirmation
tmux-kill-session --session myproject --force
```

## Common Workflows

### Starting a Multi-Agent Task

```bash
# 1. Create a session with multiple agents
tmux-spawn-agent --session myproject --agent pi --task "Implement the backend API"
tmux-spawn-agent --session myproject --agent claude --task "Create the frontend components"
tmux-spawn-agent --session myproject --agent opencode --task "Write integration tests"

# 2. Start the background watcher
tmux-ensure-progress --session myproject &

# 3. Check status periodically
watch -n 30 'tmux-agent-status --session myproject'

# 4. When all done, kill the session
tmux-kill-session --session myproject --force
```

### Resuming Work Later

```bash
# List available sessions
tmux-list-sessions

# Attach to existing session
tmux-agent-status --session myproject

# Resume monitoring
tmux-ensure-progress --session myproject
```

### Attaching to Watch a Session Interactively

```bash
# Get the socket path from the session
SOCKET_DIR="${TMUX_CODER_STATE_DIR:-${TMPDIR:-/tmp}/tmux-coder-sockets}"
SOCKET="$SOCKET_DIR/myproject.sock"

# Attach with tmux
tmux -S "$SOCKET" attach -t myproject

# Or use the default socket
tmux attach -t myproject
```

## Configuration

Set these environment variables to customize behavior:

```bash
# Custom socket directory
export TMUX_CODER_SOCKET_DIR="/path/to/sockets"

# Custom state directory for session tracking
export TMUX_CODER_STATE_DIR="$HOME/.my-tmux-coder"
```

## Tips

- **Naming**: Use descriptive session names like `feature-auth`, `bugfix-login`, `refactor-db`
- **Agents**: Each agent runs in its own window - use `Ctrl+b n` / `Ctrl+b p` to switch
- **Stuck Detection**: The watcher checks for identical output snapshots; agents that produce continuous output won't be flagged
- **Finish String**: Agents should print `TASK_COMPLETE` when done (this is automatically added to task prompts)