# Advanced Features

## Hooks

tmux hooks run shell commands or tmux commands automatically when specific events occur.

### Setting Hooks

```bash
# Set a hook (runs every time session is created):
tmux set-hook session-created 'run-shell "notify-send tmux New session created"'

# Set a hook on a specific session:
tmux set-hook -t myapp session-renamed 'display-message "Session renamed to #{session_name}"'

# Global hook (all sessions):
tmux set-hook -g window-linked 'run-shell "echo #{window_name} >> /tmp/tmux-windows.log"'

# Remove a hook:
tmux set-hook -gu session-created
```

### Common Hook Events

| Hook | Fires when |
|------|-----------|
| `session-created` | New session is created |
| `session-closed` | Session is destroyed |
| `session-renamed` | Session is renamed |
| `session-window-changed` | Active window in a session changes |
| `window-linked` | Window added to a session |
| `window-unlinked` | Window removed |
| `window-renamed` | Window renamed |
| `pane-exited` | A pane's process exits |
| `pane-focus-in` | Pane receives focus |
| `pane-focus-out` | Pane loses focus |
| `client-attached` | Client attaches to a session |
| `client-detached` | Client detaches |
| `alert-activity` | Activity detected in a monitored window |
| `after-new-session` | After new-session command |
| `after-split-window` | After split-window command |

### Hook Recipes

```tmux
# Auto-rename window based on SSH hostname:
set-hook -g pane-focus-in "run-shell '
  cmd=$(tmux display-message -p -t #{pane_id} \"#{pane_current_command}\")
  if [ \"$cmd\" = \"ssh\" ]; then
    title=$(tmux display-message -p -t #{pane_id} \"#{pane_title}\")
    tmux rename-window -t #{window_id} \"$title\"
  fi
'"

# Notify when a long command finishes:
set-hook -g pane-exited 'run-shell "notify-send tmux \"Pane exited: #{pane_current_command}\""'
```

---

## Monitoring & Alerts

```tmux
# Alert when any activity occurs in a window:
setw -g monitor-activity on
set  -g visual-activity  on    # flash status bar (or use bell/off)

# Alert when a window is silent for N seconds:
setw -g monitor-silence 30
set  -g visual-silence  on

# Bell handling:
set -g bell-action any         # any / current / other / none
set -g visual-bell on          # show bell visually (not audibly)
```

---

## Respawning Panes and Windows

```bash
# Respawn a dead pane (restart its shell):
tmux respawn-pane -t TARGET
tmux respawn-pane -k -t TARGET    # kill first, then respawn
tmux respawn-pane -t TARGET -c /new/dir

# Respawn a window:
tmux respawn-window -t SESSION:WIN
tmux respawn-window -k -t SESSION:WIN
```

---

## tmux Command From Within a Pane

Inside a shell running in a tmux pane, you can communicate back to the server:

```bash
# Display a message on the status bar:
tmux display-message "Build complete!"

# Send keys to another pane from the current shell:
tmux send-keys -t :0.1 'echo hello' Enter

# Create a new window:
tmux new-window -n results
```

---

## Server Options

```bash
# List all server options:
tmux show-options -s

# Set server option:
tmux set-option -s buffer-limit 20        # max paste buffers
tmux set-option -s escape-time 10         # ms to wait after Esc
tmux set-option -s exit-empty off         # keep server alive with no sessions
```

---

## Global vs. Session vs. Window Options

```bash
# Global (affects new sessions/windows):
tmux set-option -g option value

# Current session only:
tmux set-option option value

# All windows globally:
tmux set-window-option -g option value

# Current window only:
tmux set-window-option option value

# Specific target:
tmux set-option -t myapp:editor option value
```

---

## Environment Inspection

```bash
# Dump all tmux server info:
tmux info

# Show all options:
tmux show-options -A          # all options (global + session + window)
tmux show-options -g          # global session options
tmux show-window-options -g   # global window options
tmux show-options -s          # server options

# Show environment for a session:
tmux show-environment -t myapp

# Show a specific option value:
tmux show-options -gv history-limit
```

---

## External Terminal Integration

### Titles

```tmux
# Set terminal window title:
set -g set-titles on
set -g set-titles-string '#S:#W'
```

### Passthrough (for tools like OSC 52 clipboard, image protocols):

```tmux
set -g allow-passthrough on    # tmux >= 3.3; lets panes send escape sequences through
```

---

## Scripted Layouts with `select-layout` Checkpoints

Save and restore complex window layouts:

```bash
# Get current layout string:
LAYOUT=$(tmux display-message -t myapp:editor -p '#{window_layout}')

# Save it:
echo "$LAYOUT" > /tmp/editor.layout

# Restore it later:
tmux select-layout -t myapp:editor "$(cat /tmp/editor.layout)"
```

---

## Shared Sessions (Pair Programming)

Multiple users attach to the same session — they see and control the same terminal.

```bash
# Host creates a session:
tmux new -s shared

# Guest attaches:
tmux attach -t shared

# Read-only access for guest (tmux >= 2.0):
tmux attach -t shared -r
```

For separate views (each client has independent window focus):

```bash
# Host:
tmux new -s pair

# Guest creates a grouped session (shares windows, independent focus):
tmux new-session -t pair -s guest
```

---

## Popup Windows (tmux >= 3.2)

Display a floating popup pane:

```bash
# Open a shell in a popup:
tmux display-popup

# Specific command:
tmux display-popup -E 'htop'

# Sized popup:
tmux display-popup -w 80 -h 24 -E 'fzf'

# Bind to a key:
# In tmux.conf:
bind p display-popup -E 'fzf --tmux'
```

---

## Choose Trees and Interactive Pickers

```bash
# Session/window/pane tree:
tmux choose-tree

# Sessions only:
tmux choose-session

# Windows:
tmux choose-window

# Buffer picker:
tmux choose-buffer

# Custom list (pipe into choose-tree):
# See also: fzf-tmux for fzf integration
```

---

## Scripting with tmux -C (Control Mode)

tmux's control mode outputs structured events — useful for building wrappers:

```bash
# Start control mode:
tmux -C

# Attach in control mode:
tmux -C attach -t myapp
```

Each command you send gets a structured response. This is how iTerm2 tmux integration works.
