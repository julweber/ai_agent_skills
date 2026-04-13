# tmux Complete Cheat Sheet

Default prefix: **Ctrl+b** (shown as `^b` below).

---

## Sessions

### CLI Commands

```bash
tmux                                  # New session
tmux new -s NAME                      # New named session
tmux new -s NAME -d                   # New session, detached
tmux new-session -A -s NAME           # Attach or create
tmux ls / tmux list-sessions          # List sessions
tmux a / tmux attach                  # Attach to last session
tmux a -t NAME                        # Attach to named session
tmux kill-session -t NAME             # Kill session
tmux kill-session -a                  # Kill all but current
tmux kill-server                      # Kill everything
tmux has-session -t NAME              # Check if session exists (exit code)
```

### Key Bindings

| Shortcut | Description |
|----------|-------------|
| `^b $` | Rename current session |
| `^b d` | Detach from session |
| `^b D` | Choose client to detach |
| `^b s` | Session tree (interactive) |
| `^b w` | Session + window preview |
| `^b (` | Switch to previous session |
| `^b )` | Switch to next session |
| `^b L` | Switch to last session |

---

## Windows (Tabs)

### CLI Commands

```bash
tmux new-window -t SESSION            # New window
tmux new-window -n NAME -t SESSION   # Named window
tmux list-windows -t SESSION          # List windows
tmux select-window -t SESSION:N       # Select window N
tmux rename-window -t SESSION:N NAME  # Rename window
tmux kill-window -t SESSION:N         # Kill window
tmux move-window -t SESSION:N         # Move window
tmux swap-window -s 2 -t 4           # Swap windows
```

### Key Bindings

| Shortcut | Description |
|----------|-------------|
| `^b c` | Create window |
| `^b ,` | Rename current window |
| `^b &` | Close current window |
| `^b p` | Previous window |
| `^b n` | Next window |
| `^b l` | Last active window |
| `^b 0–9` | Switch to window by number |
| `^b '` | Prompt for window number |
| `^b f` | Find window |
| `^b w` | Interactive window list |

---

## Panes (Splits)

### CLI Commands

```bash
tmux split-window -h -t TARGET        # Split left/right
tmux split-window -v -t TARGET        # Split top/bottom
tmux split-window -h -p 40 -t TARGET  # Split, 40% for new pane
tmux select-pane -t TARGET            # Focus pane
tmux select-pane -L / -R / -U / -D   # Focus direction
tmux resize-pane -U/-D/-L/-R N -t T  # Resize N cells
tmux resize-pane -x W -y H -t TARGET  # Set exact size
tmux kill-pane -t TARGET              # Kill pane
tmux swap-pane -s SRC -t DST          # Swap panes
tmux break-pane -t TARGET             # Pane → new window
tmux join-pane -s SRC -t DST          # Window → pane
tmux list-panes -s -t SESSION         # List all panes
```

### Key Bindings

| Shortcut | Description |
|----------|-------------|
| `^b %` | Split horizontally (left/right) |
| `^b "` | Split vertically (top/bottom) |
| `^b ←↑↓→` | Move to pane in direction |
| `^b o` | Cycle to next pane |
| `^b ;` | Last active pane |
| `^b q` | Show pane numbers |
| `^b q 0–9` | Jump to pane number |
| `^b z` | Toggle zoom (full-screen) |
| `^b !` | Break pane into a new window |
| `^b {` | Swap pane with previous |
| `^b }` | Swap pane with next |
| `^b Space` | Cycle through layouts |
| `^b x` | Close current pane |
| `^b ↑/↓ (hold)` | Resize height |
| `^b ←/→ (hold)` | Resize width |
| `^b Alt+↑/↓/←/→` | Resize by 5 |

### Layouts

| Command | Layout |
|---------|--------|
| `^b Space` | Cycle layouts |
| `:select-layout even-horizontal` | Equal side-by-side |
| `:select-layout even-vertical` | Equal stacked |
| `:select-layout main-horizontal` | Large top, rest bottom |
| `:select-layout main-vertical` | Large left, rest right |
| `:select-layout tiled` | Grid |

---

## Copy Mode

| Shortcut | Description |
|----------|-------------|
| `^b [` | Enter copy mode |
| `^b PgUp` | Enter copy mode, scroll up |
| `^b ]` | Paste from buffer |
| `^b =` | Choose buffer to paste |
| `q` | Exit copy mode |

### Navigation (vi mode)

| Key | Action |
|-----|--------|
| `h j k l` | Move cursor |
| `w / b` | Forward/backward word |
| `g / G` | Top / bottom of scrollback |
| `Ctrl+u / Ctrl+d` | Half page up/down |
| `/ / ?` | Search forward/backward |
| `n / N` | Next/previous match |

### Selection (vi mode)

| Key | Action |
|-----|--------|
| `Space` or `v` | Begin selection |
| `V` | Select line |
| `Ctrl+v` | Block (rectangle) selection |
| `Enter` or `y` | Copy selection |
| `Esc` | Cancel selection |

### Buffers

```bash
tmux list-buffers                      # Show all buffers
tmux show-buffer                       # Show buffer 0
tmux save-buffer FILE                  # Save buffer to file
tmux load-buffer FILE                  # Load file into buffer
tmux set-buffer "text"                 # Set buffer from CLI
tmux delete-buffer -b NAME             # Delete a buffer
tmux paste-buffer -t TARGET            # Paste buffer into pane
```

---

## Command Mode

| Shortcut | Description |
|----------|-------------|
| `^b :` | Enter command mode |
| `^b ?` | List all key bindings |

Useful commands in command mode:

```
:new-window
:split-window -h
:rename-session NAME
:setw synchronize-panes
:source-file ~/.tmux.conf
:kill-session
:show-options -g
```

---

## Misc / Meta

| Shortcut | Description |
|----------|-------------|
| `^b t` | Show clock |
| `^b ~` | Show messages (log) |
| `^b i` | Show pane info |
| `^b r` | Refresh client (if bound) |

```bash
tmux list-keys                         # All key bindings
tmux list-commands                     # All commands
tmux info                              # Server info dump
tmux display-message -p '#{...}'      # Inspect a format variable
```

---

## Configuration

```bash
tmux source-file ~/.tmux.conf          # Reload config
tmux show-options -g                   # Global session options
tmux show-window-options -g            # Global window options
tmux show-options -s                   # Server options
tmux set-option -g OPTION VALUE        # Set global option
tmux set-window-option -g OPTION VALUE # Set global window option
```

---

## Useful Scripting Commands

```bash
tmux send-keys -t TARGET -l -- "text"  # Send literal text
tmux send-keys -t TARGET "" Enter      # Send Enter
tmux send-keys -t TARGET C-c           # Send Ctrl+C
tmux capture-pane -p -J -t TARGET -S -200  # Capture scrollback
tmux display-message "text"            # Show message in status bar
tmux display-message -p '#{var}'       # Print format variable
tmux run-shell 'shell command'         # Run shell command
tmux pipe-pane -t TARGET 'cat >> log'  # Stream pane to file
tmux respawn-pane -t TARGET            # Restart dead pane
```
