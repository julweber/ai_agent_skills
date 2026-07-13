---
name: herdr-cli
description: Expert guide for herdr, the terminal workspace manager for AI coding agents.
disable-model-invocation: true
---

# herdr — Terminal Workspace Manager for AI Agents

herdr is a terminal workspace manager that hosts and orchestrates AI coding agents (pi, Claude Code, Codex, Opencode, etc.) in persistent terminal sessions behind a UNIX socket.

## Primary Workflow — Launching an Agent

1. Ensure the server is running: `herdr status`. If not, start it with `herdr server`.
2. Create a workspace: `herdr workspace create --label "my-project"`.
3. Start an agent in a pane: `herdr agent start "name" --workspace w1 --split right -- /path/to/agent`.
4. Send a task: `herdr pane run <pane_id> "your instruction"`.
5. Read output: `herdr agent read "name" --source recent --lines 50`. The workflow is complete when the agent reaches `idle` status (verify with `herdr agent list`).

## Architecture

> For details, see [ARCHITECTURE.md](./ARCHITECTURE.md).

**Hierarchy:** Session → Workspace → Tab → Pane → Agent. You can have multiple workspaces in a session, but typically one is enough.

## Starting the Server

```bash
# Start the daemon in background
nohup herdr server > /tmp/herdr-server.log 2>&1 &
sleep 2

# Verify it started
herdr status
```

## Creating a Workspace

```bash
# Create a workspace for your agents
herdr workspace create --label "my-project" [--cwd /path]
```

## Starting Agents (one per tab)

Each agent runs in its own tab for isolation:

```bash
# Create a new tab in the workspace
herdr tab create --workspace <workspace_id> --label "agent-name" --cwd /path

# Start an agent in that tab
herdr agent start "agent-name" --workspace <workspace_id> --tab <tab_id> -- <full-path-to-agent-binary>
```

Or combine into one step using `herdr agent start` with `--split new-tab` (if supported) or just create the tab first, then start.

Common agent paths:
- pi: `pi`, find with `which pi`
- claude: find with `which claude`
- codex: find with `which codex`

After starting, verify with `herdr agent list`. Look for the pane_id and tab_id to use in subsequent commands.

## Sending Commands to Agents

Use `herdr pane run` to send text and trigger the agent in a single command:

```bash
# Send instruction to an agent (sends text + Enter)
herdr pane run <pane_id> "Your instruction here"
```

Find the pane_id from `herdr agent list` or `herdr agent get <name>`.

### Batch dispatch to multiple agents

```bash
# Send to agent-1
herdr pane run w1:p2 "Task A"

# Send to agent-2
herdr pane run w1:p3 "Task B"
```

**Two-step queue + trigger** (when you need to queue text before triggering):
- `herdr agent send <target> <text>` writes text but **never presses Enter**
- Follow with `herdr pane send-keys <pane_id> Return` to trigger

## Reading Agent Output

```bash
# Read recent output from an agent
herdr agent read "agent-name" --source recent --lines 50

# Read the current visible pane content
herdr pane read <pane_id> --source visible --lines 50
```

## Monitoring Agent Status

```bash
# Check status of all agents
herdr agent list

# Get details on a specific agent
herdr agent get "agent-name"

# Wait for an agent to reach a specific status
herdr agent wait "agent-name" --status idle --timeout 30000
```

Agent statuses: `idle`, `working`, `blocked`, `unknown`

## Focusing an Agent

```bash
# Focus an agent's pane
herdr agent focus "agent-name"
```

## Workspace Management

```bash
# List workspaces
herdr workspace list

# Create a workspace
herdr workspace create --label "name" [--cwd /path]

# Get workspace details
herdr workspace get <workspace_id>

# Focus a workspace
herdr workspace focus <workspace_id>

# Rename a workspace
herdr workspace rename <workspace_id> <new-label>

# Close a workspace
herdr workspace close <workspace_id>
```

## Agent Lifecycle

```bash
# Start an agent
herdr agent start "name" --workspace w1 --split right -- <binary>

# Rename an agent
herdr agent rename "name" <new-name>

# Get detailed explanation of what an agent is doing (generates docs)
herdr agent explain "name" --json

# Explain a file for an agent (feeds context to the agent)
herdr agent explain --file PATH --agent "name"

# Attach to an agent's terminal (interactive takeover)
herdr agent attach "name" [--takeover]

# Send text to an agent without pressing Enter
herdr agent send "name" "text to queue"
```

## Pane Management

```bash
# List panes in a workspace
herdr pane list --workspace w1

# Run a command in a pane (sends text + Enter)
herdr pane run <pane_id> "echo hello"

# Split a pane
herdr pane split <pane_id> --direction right

# Resize a pane
herdr pane resize --direction right --amount 0.3

# Close a pane
herdr pane close <pane_id>

# Zoom/unzoom a pane
herdr pane zoom <pane_id> --toggle

# Focus a pane by direction
herdr pane focus --direction left
herdr pane focus --direction right
herdr pane focus --direction up
herdr pane focus --direction down

# Send raw text to a pane (no Enter)
herdr pane send-text <pane_id> "text"

# Send key presses to a pane
herdr pane send-keys <pane_id> Return
herdr pane send-keys <pane_id> Ctrl+c
```

## Session Management

```bash
# List sessions
herdr session list

# Create a named session
herdr session create <name>

# Attach to a named session
herdr session attach <name>

# Stop a session
herdr session stop <name>

# Rename a session
herdr session rename <name> <new-name>

# Delete a session
herdr session delete <name>
```

## Integration Management

herdr supports built-in integrations for major AI coding agents:

```bash
# List available integrations
herdr integration status

# Install an integration (sets up agent detection)
herdr integration install pi
herdr integration install claude
herdr integration install codex
herdr integration install opencode
herdr integration install copilot
herdr integration install devin

# Uninstall
herdr integration uninstall pi
```

## Useful Patterns

### Launch 2 agents for parallel work (one per tab)

```bash
# Create workspace
WS=$(herdr workspace create --label "parallel" --json | grep -o '"workspace_id":"[^"]*"' | cut -d'"' -f4)
# If --json fails, use: WS=$(herdr workspace get "parallel" --json | jq -r '.workspace_id')

# Create tab and start agent 1
T1=$(herdr tab create --workspace "$WS" --label "researcher" --json | grep -o '"tab_id":"[^"]*"' | cut -d'"' -f4)
herdr agent start "researcher" --workspace "$WS" --tab "$T1" -- pi
sleep 1

# Create tab and start agent 2
T2=$(herdr tab create --workspace "$WS" --label "coder" --json | grep -o '"tab_id":"[^"]*"' | cut -d'"' -f4)
herdr agent start "coder" --workspace "$WS" --tab "$T2" -- pi
sleep 1

# Assign tasks
herdr pane run w1:p2 "Research the requirements for feature X"
herdr pane run w1:p3 "Implement the feature based on requirements"
```

### Check all agent statuses in a loop

```bash
herdr agent list | jq '.result.agents[] | {name: .name, status: .agent_status}'
```

### Get live runtime snapshot

```bash
herdr api snapshot
```

## Configuration

Config file: `~/.config/herdr/config.toml`

```bash
# Show default config
herdr --default-config

# Reload config in running server
herdr server reload-config

# Reset keybindings
herdr config reset-keys
```

## Common Gotchas

1. **Server must be running** before any agent commands work — check with `herdr status`. If not running, start with `herdr server`.
2. **Agent binary paths vary** — prefer `which <agent>` over hardcoded paths. Default pi path on macOS is `pi`.
3. **Agent status may show `unknown`** briefly after start — wait a moment before reading output.
4. **herdr --help** reveals all available subcommands and flags — it's the most comprehensive discovery command.
5. **Workspace ID parsing** — when capturing workspace_id from JSON output, prefer `herdr workspace get <label>` over fragile grep patterns.
