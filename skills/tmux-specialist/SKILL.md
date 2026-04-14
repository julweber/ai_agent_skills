---
name: tmux-specialist
description: "Complete tmux expertise: session/window/pane management, scripting, automation, copy mode, configuration, plugins, agent steering, and all advanced features. Use when working with tmux in any capacity."
license: Vibecoded
---

# tmux Specialist

Full-spectrum tmux expertise covering interactive use, scripting, automation, configuration, and steering agents via tmux panes.

## Terminology

- **Session**: a persistent workspace container (survives detach/disconnect). All work lives inside sessions.
- **Window** (tab): each session has one or more windows, each with independent content.
- **Pane** (split): windows are subdivided into panes; each runs an independent shell or program.
- **Target format**: `{session}:{window}.{pane}` — e.g., `myapp:editor.0`. Omit parts to use current.

---

## Reference Documents

Read the relevant reference file(s) **before** answering any question or executing any task in that area:

| Topic | File |
|-------|------|
| Quick-reference keybindings & CLI cheat sheet | `references/cheat-sheet.md` |
| Session create/attach/rename/kill/env | `references/session-management.md` |
| Windows, panes, splits, layouts, synchronize | `references/window-pane-layouts.md` |
| `~/.tmux.conf` options, keybindings, status bar | `references/configuration.md` |
| Copy mode navigation, paste buffers, clipboard, `pipe-pane` | `references/copy-mode-buffers.md` |
| Hooks, monitoring, popups, shared sessions, control mode | `references/advanced-features.md` |
| TPM, tmux-resurrect, tmux-yank, themes, etc. | `references/plugins.md` |
| `send-keys`, `capture-pane`, format strings, scripting sessions | `references/scripting-automation.md` |
| Steering agents/TUIs (pi, vim, REPLs, gdb) via send-keys | `references/steering-agents.md` |

---

## Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/wait-for-text.sh` | Poll a pane until a regex appears (with timeout) |
| `scripts/find-sessions.sh` | List sessions on one socket or scan all sockets |
| `scripts/session-layout.sh` | Create named multi-pane layouts (dev, monitor, grid4, triple-h, triple-v, custom) |
| `scripts/tmux-snapshot.sh` | Dump all pane scrollbacks to files or stdout |
| `scripts/session-watch.sh` | Watch and display status of all panes in a multi-agent session (updates every 60s by default) |

---

## Socket Convention (Agents)

Agents MUST use a private socket to avoid interfering with the user's personal tmux:

```bash
SOCKET_DIR="${CLAUDE_TMUX_SOCKET_DIR:-${TMPDIR:-/tmp}/claude-tmux-sockets}"
mkdir -p "$SOCKET_DIR"
SOCKET="$SOCKET_DIR/claude.sock"
SESSION="claude-myproject"   # slug-like, no spaces

tmux -S "$SOCKET" new-session -d -s "$SESSION" -n shell
```

After starting a session, **immediately** print a copy-paste monitor command for the user:

```
To monitor this session:
  tmux -S "$SOCKET" attach -t "$SESSION"

Or capture output once:
  tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION":0.0 -S -200
```

Print this again at the end of the tool loop.

---

## Quickstart Examples

### Start a session and run a command

```bash
SOCKET=/tmp/claude-tmux-sockets/claude.sock
SESSION=mywork
tmux -S "$SOCKET" new-session -d -s "$SESSION" -n main
tmux -S "$SOCKET" send-keys -t "$SESSION":main.0 -l -- 'python3 -q'
tmux -S "$SOCKET" send-keys -t "$SESSION":main.0 Enter
tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION":main.0 -S -200
```

### Wait for a prompt before proceeding

```bash
./scripts/wait-for-text.sh -S "$SOCKET" -t "$SESSION:0.0" -p '^\$\s*$' -T 30
```

### Create a dev layout (editor + build + logs)

```bash
./scripts/session-layout.sh -S "$SOCKET" -s myapp dev
```

### Snapshot all panes to files

```bash
./scripts/tmux-snapshot.sh -S "$SOCKET" -o /tmp/snapshots "$SESSION"
```

### Watch a multi-agent session

Monitor all panes in a session with periodic status updates:

```bash
./scripts/session-watch.sh -S "$SOCKET" -s "pi-multiagent" -i 30
```

This displays a formatted table showing the last non-empty line from each pane (truncated to 40 chars), updated every N seconds. Ideal for watching multi-agent workflows where different panes run parallel tasks.

### Find sessions across all sockets

```bash
./scripts/find-sessions.sh --all
```

---

## Sending Input Safely

Always use `-l` to prevent shell interpretation of special characters:

```bash
tmux -S "$SOCKET" send-keys -t TARGET -l -- "your command here"
tmux -S "$SOCKET" send-keys -t TARGET Enter
```

Control keys: `C-c` (interrupt), `C-d` (EOF), `C-l` (clear), `Escape`, `Tab`, `BSpace`, `F1`–`F12`.

---

---

## Session Watching

The `session-watch.sh` script provides a convenient way to monitor multi-agent tmux sessions with a formatted display that shows the current state of each pane at regular intervals.

### Basic Usage

```bash
./scripts/session-watch.sh [OPTIONS]
```

**Options:**
- `-S, --socket-path` — tmux socket path (default: `/tmp/pi-tmux-sockets/pi.sock`)
- `-s, --session`     — session name (default: `pi-multiagent`)
- `-i, --interval`    — update interval in seconds (default: 60)
- `-h, --help`        — show usage information

**Example:**
```bash
# Watch with default settings
./scripts/session-watch.sh

# Custom socket and session
./scripts/session-watch.sh -S /tmp/my.sock -s mysession

# Update every 15 seconds
./scripts/session-watch.sh -i 15
```

**Output Format:**
The script displays a table with:
- Timestamp of each update
- Pane index and label (0=Dev, 1=QA, 2=QA)
- Last non-empty line from each pane (truncated to 40 characters)
- Context usage from tmux environment variable `#E`

**Use Cases:**
- Monitoring parallel agent tasks running in separate panes
- Quick status checks without attaching to the session
- Watching long-running workflows in a read-only manner

---

## Watching Output

```bash
# Capture last 200 lines (joined, no wrapping artifacts):
tmux -S "$SOCKET" capture-pane -p -J -t TARGET -S -200

# Poll until text appears (preferred over sleep loops):
./scripts/wait-for-text.sh -S "$SOCKET" -t TARGET -p 'pattern' -T 20 -i 0.5 -l 2000
```

`wait-for-text.sh` options:
- `-t` target (required)
- `-p` regex pattern (required); add `-F` for fixed string
- `-T` timeout seconds (default 15)
- `-i` poll interval (default 0.3)
- `-l` history lines to search (default 1000)
- Exits 0 on match, 1 on timeout; prints last capture to stderr on failure.

---

## Stability Detection (Agent Completion)

Use when you need to know if a long-running agent/command has truly finished:

```bash
prev=""
stable=0
STABLE_ROUNDS=3
while true; do
  current=$(tmux -S "$SOCKET" capture-pane -t TARGET -p \
    | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -vE '[0-9]{2}:[0-9]{2}:[0-9]{2}')
  if [ "$current" = "$prev" ]; then
    ((stable++))
    [ "$stable" -ge "$STABLE_ROUNDS" ] && break
  else
    stable=0
    prev="$current"
  fi
  sleep 2
done
```

---

## Interactive Tool Recipes

See `references/steering-agents.md` for the full guide. Quick patterns:

- **Python REPL**: set `PYTHON_BASIC_REPL=1`; start `python3 -q`; wait for `^>>>`; send code with `-l`.
- **gdb/lldb**: start with `--quiet`; disable paging; wait for `(gdb)`/`(lldb)` prompt; send commands with `-l`.
- **Node / psql / mysql / bash**: same pattern — start program, poll for prompt, send literal text + Enter.
- When debugging, prefer **lldb** by default.

---

## Common Scripting Patterns

See `references/scripting-automation.md` for the full reference including format strings, conditionals, and one-liners.

```bash
# Check if session exists before creating:
if ! tmux -S "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
  tmux -S "$SOCKET" new-session -d -s "$SESSION"
fi

# Get PID of process in pane and wait for it to exit:
PID=$(tmux -S "$SOCKET" display-message -t "$SESSION":0.0 -p '#{pane_pid}')
while kill -0 "$PID" 2>/dev/null; do sleep 0.5; done
```

---

## Configuration

See `references/configuration.md` for the full `~/.tmux.conf` guide.

Reload config at runtime:
```bash
tmux source-file ~/.tmux.conf
```

---

## Plugins

See `references/plugins.md` for TPM, tmux-resurrect, tmux-continuum, tmux-yank, themes, and more.

---

## Cleanup

```bash
tmux -S "$SOCKET" kill-session -t "$SESSION"          # kill one session
tmux -S "$SOCKET" kill-server                          # kill everything on this socket
```
