# herdr Architecture

herdr runs a long-lived server behind a UNIX socket, and all CLI commands talk to that server.

## Components

- **Server** — a daemon process managed by `herdr server`, listens on a UNIX socket at `~/.config/herdr/herdr.sock`
- **Client** — the `herdr` CLI, talks to the server via the socket
- **Session** — a persistent terminal environment (like a tmux session); the top-level container that holds workspaces
- **Workspace** — a container *inside* a session (like a VSCode workspace); holds tabs and panes
- **Tab** — a tab within a workspace; holds panes
- **Pane** — a terminal pane inside a tab; hosts an agent or shell
- **Agent** — a named AI coding agent running in a pane; herdr tracks its status and output

## Hierarchy

```
Session → Workspace → Tab → Pane → Agent
```

You can have multiple workspaces in a session, but typically one is enough.

## Agent Statuses

`idle`, `working`, `blocked`, `done`, `unknown`

- **idle** — Agent is ready for input
- **working** — Agent is actively processing a task
- **blocked** — Agent is waiting for external input or resolution
- **done** — Agent has completed its work
- **unknown** — Agent status could not be determined (briefly after start, or for unrecognized processes)

## Agent Integration Architecture

### Built-in Integrations

herdr ships with built-in integrations for 20+ AI coding agents. Each integration has:

- **Agent detection manifest** — defines how herdr recognizes the agent in terminal output
- **Lifecycle tracking** — monitors state transitions (idle → working → idle/done/blocked)
- **Integration version** — tracked for updates (`herdr integration status --outdated-only`)

Supported agents: `pi`, `claude`, `codex`, `gemini`, `cursor`, `devin`, `agy`, `cline`, `omp`, `mastracode`, `opencode`, `copilot`, `kimi`, `kiro`, `droid`, `amp`, `grok`, `hermes`, `kilo`, `qodercli`, `maki`

### Custom Agent Integration

For agents without built-in support, herdr provides a pane-level reporting API:

1. **`report-agent-session`** — Establishes agent session identity
2. **`report-agent`** — Reports lifecycle state transitions
3. **`report-metadata`** — Sets display-only metadata (title, state labels, tokens)
4. **`release-agent`** — Releases lifecycle authority when agent exits

### Communication Flow

```
CLI Command → UNIX Socket → Server → Session → Workspace → Tab → Pane → Agent
Agent Output → Pane → Server → UNIX Socket → CLI Response
```

## Key Subcommand Groups

| Group | Purpose |
|-------|---------|
| `herdr server` | Server lifecycle (start, stop, reload-config, manifests) |
| `herdr session` | Named persistent sessions (list, attach, stop, delete) |
| `herdr workspace` | Workspace management (create, list, get, focus, rename, close, metadata) |
| `herdr worktree` | Git worktree-backed workspaces (list, create, open, remove) |
| `herdr tab` | Tab management (list, create, get, focus, rename, close) |
| `herdr pane` | Pane control (list, run, split, resize, zoom, read, send, wait-output, layout, swap, move, report-*) |
| `herdr agent` | Agent control (list, get, start, prompt, read, send-keys, wait, focus, attach, explain) |
| `herdr integration` | Agent integration management (install, uninstall, status) |
| `herdr notification` | Desktop notifications (show) |
| `herdr config` | Configuration (check, reset-keys) |
| `herdr channel` | Update channel management (show, set) |
| `herdr api` | API inspection (snapshot, schema) |
| `herdr completion` | Shell completion generation |
| `herdr update` | Self-update |

## Configuration

- **Config file**: `~/.config/herdr/config.toml`
- **Env override**: `HERDR_CONFIG_PATH`
- **Logs**: `~/.config/herdr/herdr.log`, `herdr-client.log`, `herdr-server.log`
