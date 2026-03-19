# tmux command cheat sheet

## Sessions

```bash
tmux                               # Start a new session
tmux new / tmux new-session        # Start a new session
tmux new -s mysession              # Start a new session named mysession
tmux new-session -A -s mysession   # Attach to mysession or create it
tmux ls / tmux list-sessions       # List all sessions
tmux a / tmux attach               # Attach to last session
tmux a -t mysession                # Attach to session named mysession
tmux kill-session -t mysession     # Kill session mysession
tmux kill-session -a               # Kill all sessions but the current
tmux kill-session -a -t mysession  # Kill all sessions but mysession
```

| Shortcut | Description                |
| ----------| ----------------------------|
| Ctrl+b $ | Rename session             |
| Ctrl+b d | Detach from session        |
| Ctrl+b s | Show all sessions          |
| Ctrl+b w | Session and window preview |
| Ctrl+b ( | Move to previous session   |
| Ctrl+b ) | Move to next session       |

## Windows

```bash
tmux new -s mysession -n mywindow  # New session with named window
```

| Shortcut | Description |
|---|---|
| Ctrl+b c | Create window |
| Ctrl+b , | Rename current window |
| Ctrl+b & | Close current window |
| Ctrl+b w | List windows |
| Ctrl+b p | Previous window |
| Ctrl+b n | Next window |
| Ctrl+b 0-9 | Switch/select window by number |
| Ctrl+b l | Toggle last active window |

```
: swap-window -s 2 -t 1  # Swap window 2 and 1
: swap-window -t -1       # Move current window left by one
: move-window -r          # Renumber windows to remove gaps
```

## Panes

| Shortcut | Description |
|---|---|
| Ctrl+b ; | Toggle last active pane |
| Ctrl+b % | Split pane vertically (horizontal layout) |
| Ctrl+b " | Split pane horizontally (vertical layout) |
| Ctrl+b { | Move current pane left |
| Ctrl+b } | Move current pane right |
| Ctrl+b ↑↓←→ | Switch to pane in direction |
| Ctrl+b o | Switch to next pane |
| Ctrl+b q | Show pane numbers |
| Ctrl+b q 0-9 | Switch/select pane by number |
| Ctrl+b z | Toggle pane zoom |
| Ctrl+b ! | Convert pane into a window |
| Ctrl+b Space | Toggle between pane layouts |
| Ctrl+b x | Close current pane |
| Ctrl+b ↑/↓ (hold) | Resize pane height |
| Ctrl+b ←/→ (hold) | Resize pane width |

```
: join-pane -s 2 -t 1    # Merge window 2 into window 1 as panes
: setw synchronize-panes  # Toggle sending input to all panes
```

## Copy Mode

| Shortcut | Description |
|---|---|
| Ctrl+b [ | Enter copy mode |
| Ctrl+b PgUp | Enter copy mode and scroll one page up |
| Ctrl+b ] | Paste contents of buffer |
| q | Quit copy mode |
| g | Go to top line |
| G | Go to bottom line |
| ↑/↓ | Scroll up/down |
| h j k l | Move cursor (vi-style) |
| w | Move cursor forward one word |
| b | Move cursor backward one word |
| / | Search forward |
| ? | Search backward |
| n | Next search match |
| N | Previous search match |
| Space | Start selection |
| Esc | Clear selection |
| Enter | Copy selection |

```
: setw -g mode-keys vi   # Use vi keys in copy mode
: show-buffer             # Display buffer_0 contents
: capture-pane            # Copy visible pane contents to buffer
: list-buffers            # Show all buffers
: choose-buffer           # Show all buffers and paste selected
: save-buffer buf.txt     # Save buffer to file
: delete-buffer -b 1      # Delete buffer 1
```

## Misc & Config

| Shortcut | Description |
|---|---|
| Ctrl+b : | Enter command mode |
| Ctrl+b ? | List all key bindings |

```
: set -g OPTION   # Set option for all sessions
: setw -g OPTION  # Set option for all windows
: set mouse on    # Enable mouse mode
```

## Help

```bash
tmux list-keys  # List all key bindings
tmux info       # Show all sessions, windows, panes, etc.
```
