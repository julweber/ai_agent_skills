# Windows & Pane Layouts

## Windows

### Creating and Navigating Windows

```bash
# CLI:
tmux new-window -t myapp                 # New window in session
tmux new-window -t myapp -n mywindow    # New named window
tmux new-window -t myapp:3              # New window at index 3
tmux new-window -c /path/to/dir         # New window in directory

# Inside tmux (default prefix: Ctrl+b):
Ctrl+b c          # Create new window
Ctrl+b ,          # Rename current window
Ctrl+b &          # Close current window (with confirmation)
Ctrl+b p          # Previous window
Ctrl+b n          # Next window
Ctrl+b l          # Last (previously active) window
Ctrl+b 0-9        # Jump to window by number
Ctrl+b '          # Prompt for window index to switch to
Ctrl+b f          # Find window by name/content
Ctrl+b w          # Interactive window/session list
```

### Managing Windows

```bash
# List windows:
tmux list-windows -t myapp
tmux list-windows -t myapp -F '#{window_index}: #{window_name} #{window_active}'

# Rename:
tmux rename-window -t myapp:0 editor

# Move / swap:
tmux move-window -t myapp:2 -t myapp:5         # Move window 2 to index 5
tmux swap-window -s myapp:2 -t myapp:4         # Swap windows 2 and 4

# Inside tmux:
:swap-window -s 2 -t 1         # Swap 2 and 1
:move-window -t 3              # Move current window to index 3
:move-window -r                # Renumber windows (remove gaps)

# Kill:
tmux kill-window -t myapp:3
```

### Window Options

```bash
tmux set-window-option -t myapp:0 automatic-rename off
tmux set-window-option -t myapp:0 monitor-activity on    # Alert on activity
tmux set-window-option -t myapp:0 monitor-silence 10     # Alert on silence (seconds)
```

---

## Panes

### Splitting Panes

```bash
# CLI:
tmux split-window -h -t TARGET           # Split horizontally (side by side)
tmux split-window -v -t TARGET           # Split vertically (top/bottom)
tmux split-window -h -p 30 -t TARGET    # Horizontal, give new pane 30% width
tmux split-window -v -c /path           # Split, start in directory

# Inside tmux:
Ctrl+b %          # Split horizontally (left/right)
Ctrl+b "          # Split vertically (top/bottom)
```

### Navigating Panes

```bash
# Inside tmux:
Ctrl+b ←↑↓→       # Move to pane in direction
Ctrl+b o          # Cycle to next pane
Ctrl+b ;          # Last (previously active) pane
Ctrl+b q          # Show pane numbers (press number to jump)
Ctrl+b q 0-9      # Jump to pane number while numbers are shown

# CLI:
tmux select-pane -t TARGET
tmux select-pane -L / -R / -U / -D      # Move left/right/up/down
```

### Resizing Panes

```bash
# Inside tmux (hold key to repeat):
Ctrl+b ↑ / ↓ / ← / →    # Resize by 1 cell
Ctrl+b Alt+↑/↓/←/→      # Resize by 5 cells

# CLI:
tmux resize-pane -t TARGET -U 5         # Up 5 rows
tmux resize-pane -t TARGET -D 5         # Down 5 rows
tmux resize-pane -t TARGET -L 10        # Left 10 cols
tmux resize-pane -t TARGET -R 10        # Right 10 cols
tmux resize-pane -t TARGET -x 80        # Set exact width
tmux resize-pane -t TARGET -y 24        # Set exact height
```

### Zooming a Pane

```bash
Ctrl+b z                                 # Toggle zoom (full-screen for current pane)
tmux resize-pane -Z -t TARGET           # Zoom via CLI
```

### Moving & Joining Panes

```bash
# Break pane out into its own window:
Ctrl+b !
tmux break-pane -t TARGET

# Join a window's pane into another window:
tmux join-pane -s src_session:window.pane -t dest_session:window

# Move pane to another window:
tmux move-pane -s SESSION:WIN.PANE -t SESSION:WIN

# Swap panes:
tmux swap-pane -s PANE_A -t PANE_B
Ctrl+b {          # Swap current pane with previous
Ctrl+b }          # Swap current pane with next
```

### Killing Panes

```bash
Ctrl+b x                                 # Kill current pane (with confirmation)
tmux kill-pane -t TARGET
```

---

## Built-in Layouts

Apply a preset layout to the current window:

```bash
Ctrl+b Space                             # Cycle through layouts
tmux select-layout even-horizontal       # Side-by-side, equal widths
tmux select-layout even-vertical         # Stacked, equal heights
tmux select-layout main-horizontal       # Large pane on top, rest below
tmux select-layout main-vertical         # Large pane on left, rest on right
tmux select-layout tiled                 # Grid-like arrangement
```

### Saving and Restoring Custom Layouts

```bash
# Get current layout string for a window:
tmux display-message -t myapp:0 -p '#{window_layout}'
# Example output: b25c,220x50,0,0{110x50,0,0,0,109x50,111,0,1}

# Restore that exact layout:
tmux select-layout -t myapp:0 'b25c,220x50,0,0{110x50,0,0,0,109x50,111,0,1}'
```

---

## Synchronize Panes

Send the same keystrokes to all panes in a window simultaneously:

```bash
# Toggle synchronize-panes for the current window:
Ctrl+b :setw synchronize-panes

# On/off explicitly:
tmux set-window-option synchronize-panes on
tmux set-window-option synchronize-panes off
```

---

## Common Multi-Pane Layouts

### Dev Layout (editor + shell + logs)
```bash
SESSION=dev
tmux new-session -d -s $SESSION -n main
tmux split-window -h -t $SESSION:main         # right pane
tmux split-window -v -t $SESSION:main.1       # split right into top/bottom
tmux select-pane -t $SESSION:main.0           # focus left (editor)
```

### 4-Pane Grid
```bash
tmux new-session -d -s grid -n main
tmux split-window -h -t grid:main
tmux split-window -v -t grid:main.0
tmux split-window -v -t grid:main.1
tmux select-layout -t grid:main tiled
```

### Monitoring Dashboard (main + log tails)
```bash
SESSION=monitor
tmux new-session -d -s $SESSION -n dashboard
tmux split-window -v -p 30 -t $SESSION:dashboard       # bottom 30%
tmux split-window -h -t $SESSION:dashboard.1           # split bottom
# Send tail commands:
tmux send-keys -t $SESSION:dashboard.1 'tail -f /var/log/syslog' Enter
tmux send-keys -t $SESSION:dashboard.2 'tail -f /var/log/app.log' Enter
```

---

## Pane Information & Formats

```bash
# List all panes in a session:
tmux list-panes -s -t myapp
tmux list-panes -s -t myapp -F '#{pane_index}: #{pane_title} #{pane_pid} #{pane_current_command}'

# List panes in a window:
tmux list-panes -t myapp:0

# Show pane size:
tmux display-message -t TARGET -p '#{pane_width}x#{pane_height}'

# Check if a pane is running a specific command:
tmux list-panes -s -F '#{pane_pid} #{pane_current_command}' | grep python
```
