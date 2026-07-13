# herdr Architecture

herdr runs a long-lived server behind a UNIX socket, and all CLI commands talk to that server.

## Components

- **Server** — a daemon process managed by `herdr server`, listens on a UNIX socket at `~/.config/herdr/herdr.sock`
- **Client** — the `herdr` CLI, talks to the server via the socket
- **Session** — a persistent terminal environment (like a tmux session); the top-level container that holds workspaces
- **Workspace** — a container *inside* a session (like a VSCode workspace); holds tabs and panes
- **Pane** — a terminal pane inside a tab; hosts an agent or shell
- **Agent** — a named AI coding agent running in a pane; herdr tracks its status and output

## Hierarchy

```
Session → Workspace → Tab → Pane → Agent
```

You can have multiple workspaces in a session, but typically one is enough.

## Agent Statuses

`idle`, `working`, `blocked`, `unknown`
