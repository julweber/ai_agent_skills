# Scripting & Automation

## Core Scripting Primitives

### send-keys

```bash
# Send literal text (no shell interpretation):
tmux send-keys -t TARGET -l -- "some text"

# Send text + Enter in one call:
tmux send-keys -t TARGET "some text" Enter

# Send a control key:
tmux send-keys -t TARGET C-c      # SIGINT
tmux send-keys -t TARGET C-d      # EOF
tmux send-keys -t TARGET C-l      # Clear screen
tmux send-keys -t TARGET Escape
tmux send-keys -t TARGET Tab
tmux send-keys -t TARGET BSpace
tmux send-keys -t TARGET F1       # Function keys

# ANSI C quoting avoids quoting issues with special chars:
tmux send-keys -t TARGET -- $'echo "hello world"\n'

# Send to multiple panes via synchronize-panes (window must have it enabled):
tmux set-window-option -t SESSION:WIN synchronize-panes on
tmux send-keys -t SESSION:WIN "" Enter
tmux set-window-option -t SESSION:WIN synchronize-panes off
```

### capture-pane

```bash
# Visible area only:
tmux capture-pane -p -t TARGET

# Include scrollback (negative = lines back from bottom):
tmux capture-pane -p -t TARGET -S -500

# Join wrapped lines (removes spurious line breaks from narrow terminals):
tmux capture-pane -p -J -t TARGET -S -200

# With ANSI escape sequences (color codes, etc.):
tmux capture-pane -p -e -t TARGET

# Capture to paste buffer instead of stdout:
tmux capture-pane -t TARGET            # stored in buffer
tmux show-buffer                        # retrieve

# Between specific lines (0 = top of scrollback, -1 = current bottom):
tmux capture-pane -p -t TARGET -S 0 -E -1
```

### Polling Pattern

Wait for a condition by looping over capture-pane:

```bash
wait_for_pattern() {
  local socket="$1" target="$2" pattern="$3" timeout="${4:-15}"
  local deadline=$(( $(date +%s) + timeout ))
  while true; do
    if tmux -S "$socket" capture-pane -p -J -t "$target" -S -200 \
        | grep -qE "$pattern"; then
      return 0
    fi
    (( $(date +%s) >= deadline )) && { echo "Timeout waiting for: $pattern" >&2; return 1; }
    sleep 0.3
  done
}

wait_for_pattern "$SOCKET" "$SESSION:0.0" '^\$\s*$' 30
```

Or use the provided helper:
```bash
./scripts/wait-for-text.sh -S "$SOCKET" -t "$SESSION:0.0" -p '^\$\s*$' -T 30
```

---

## run-shell

Execute a shell command from inside tmux (e.g., from a key binding or hook):

```bash
# Print output to the status bar:
tmux run-shell 'echo $(date)'

# Run a background command:
tmux run-shell -b 'sleep 5 && tmux display-message "Done"'

# In tmux.conf:
bind x run-shell 'notify-send "tmux" "Done!"'
```

---

## display-message

Print to the tmux status bar (message area):

```bash
tmux display-message "Hello from script"
tmux display-message -d 5000 "Shown for 5 seconds"

# Print a format string (variable interpolation):
tmux display-message -p '#{session_name}: #{window_name}'

# Silent (suppress output, useful just for side effects):
tmux display-message -p '#{pane_pid}' > /dev/null
```

---

## Format Strings

tmux formats are `#{variable}` expressions evaluated in the context of a target.

### Common Variables

| Variable | Description |
|----------|-------------|
| `#{session_name}` | Session name |
| `#{session_id}` | Session unique ID (`$0`, `$1`, …) |
| `#{window_index}` | Window number |
| `#{window_name}` | Window name |
| `#{window_active}` | 1 if window is active |
| `#{pane_index}` | Pane number |
| `#{pane_id}` | Pane unique ID (`%0`, `%1`, …) |
| `#{pane_pid}` | PID of process in pane |
| `#{pane_current_command}` | Current command name |
| `#{pane_current_path}` | Working directory |
| `#{pane_width}` / `#{pane_height}` | Pane dimensions |
| `#{cursor_x}` / `#{cursor_y}` | Cursor position |
| `#{host}` | Hostname |

### Conditionals in Formats

```
# #{?condition,true-str,false-str}
#{?window_active,[ACTIVE],}
#{?pane_in_mode,[copy],}
#{?mouse_any_flag,[M],}
```

### Arithmetic and String Manipulation

```
#{e|+|5,3}          # 5+3 = 8
#{e|-|10,4}         # 10-4 = 6
#{=/10/...:pane_title}  # Truncate to 10 chars, add ...
#{s|foo|bar|:variable}  # Substitute foo → bar in variable
#{t:window_activity}    # Format timestamp as human-readable
```

---

## Scripting a Session from Scratch

```bash
#!/usr/bin/env bash
SOCKET=/tmp/my-project.sock
SESSION=project

# Ensure no stale session:
tmux -S "$SOCKET" kill-session -t "$SESSION" 2>/dev/null || true

# Create session with initial window:
tmux -S "$SOCKET" new-session -d -s "$SESSION" -n editor -c ~/projects/myapp

# Window 2: shell for running tasks:
tmux -S "$SOCKET" new-window -t "$SESSION" -n shell -c ~/projects/myapp

# Window 3: logs:
tmux -S "$SOCKET" new-window -t "$SESSION" -n logs

# Split the editor window:
tmux -S "$SOCKET" split-window -h -t "$SESSION":editor -p 40

# Start programs:
tmux -S "$SOCKET" send-keys -t "$SESSION":editor.0 'nvim .' Enter
tmux -S "$SOCKET" send-keys -t "$SESSION":logs.0   'tail -f /var/log/syslog' Enter

# Focus on editor:
tmux -S "$SOCKET" select-window -t "$SESSION":editor
tmux -S "$SOCKET" select-pane   -t "$SESSION":editor.0

echo "Session started. Attach with:"
echo "  tmux -S '$SOCKET' attach -t '$SESSION'"
```

---

## Conditionals in Shell Scripts

```bash
# Check if tmux is running:
if pgrep -x tmux > /dev/null; then
  echo "tmux server is running"
fi

# Check if a specific session exists:
if tmux -S "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
  echo "Session $SESSION exists"
else
  echo "Creating session..."
fi

# Check if a window exists:
if tmux -S "$SOCKET" list-windows -t "$SESSION" -F '#{window_name}' \
     | grep -qx "editor"; then
  echo "editor window exists"
fi

# Check if a pane is running a specific command:
if tmux -S "$SOCKET" list-panes -s -t "$SESSION" \
     -F '#{pane_current_command}' | grep -qx "python3"; then
  echo "Python REPL is open"
fi
```

---

## Batch Command Execution

```bash
# Run multiple tmux commands from a file:
cat <<'CMDS' | while read cmd; do tmux -S "$SOCKET" $cmd; done
  new-session -d -s batch
  new-window -t batch -n window2
  send-keys -t batch:0 'echo hello' Enter
CMDS
```

---

## Scripting via tmux Command Mode

From inside tmux you can chain commands with `;`:

```
Ctrl+b : new-window \; split-window -h \; send-keys 'htop' Enter
```

In scripts you can pass multiple commands:
```bash
tmux -S "$SOCKET" \
  new-session -d -s demo \; \
  split-window -h -t demo \; \
  send-keys -t demo:0.0 'vim' Enter
```

---

## Useful One-Liners

```bash
# Kill all windows matching a pattern:
tmux -S "$SOCKET" list-windows -t "$SESSION" -F '#{window_index} #{window_name}' \
  | awk '/logs/{print $1}' \
  | xargs -I{} tmux -S "$SOCKET" kill-window -t "$SESSION":{}

# Get PID of process in a pane:
tmux -S "$SOCKET" display-message -t "$SESSION":0.0 -p '#{pane_pid}'

# Wait for pane PID to exit:
PID=$(tmux -S "$SOCKET" display-message -t "$SESSION":0.0 -p '#{pane_pid}')
while kill -0 "$PID" 2>/dev/null; do sleep 0.5; done

# Resize all panes in a window to equal size:
tmux -S "$SOCKET" select-layout -t "$SESSION":0 even-horizontal
```
