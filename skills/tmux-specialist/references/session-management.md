# Session Management

## Creating Sessions

```bash
tmux                                      # New session, auto-named
tmux new-session                          # Same as above (alias: new)
tmux new -s myapp                         # Named session "myapp"
tmux new -s myapp -n editor              # Named session + named first window
tmux new -s myapp -d                     # Detached (don't attach immediately)
tmux new -s myapp -d -x 220 -y 50       # Detached with explicit dimensions
tmux new-session -A -s myapp             # Attach if exists, create if not
tmux new -s myapp -c /path/to/dir        # Start in specific directory
tmux new -s myapp -e VAR=value           # Set environment variable
```

## Listing Sessions

```bash
tmux list-sessions                        # Verbose list (alias: ls)
tmux ls                                   # Short form
tmux ls -F '#{session_name}: #{session_windows} windows'  # Custom format
tmux ls -F '#{session_name}\t#{session_attached}'         # Show attach status
```

## Attaching to Sessions

```bash
tmux attach                               # Attach to most recent session
tmux attach -t myapp                      # Attach to named session
tmux attach -t myapp -d                  # Detach other clients first
tmux attach -t myapp:editor              # Attach to session at specific window
tmux a                                    # Shortcut for attach
tmux a -t myapp                           # Shortcut with target
```

## Detaching

```bash
# Inside tmux:
Ctrl+b d                                  # Detach from session (keep it alive)
Ctrl+b D                                  # Choose which client to detach

# From command line:
tmux detach-client -s myapp              # Detach all clients from session
tmux detach-client -t %0                 # Detach specific pane/client
```

## Renaming Sessions

```bash
tmux rename-session -t oldname newname   # CLI rename
# Inside tmux:
Ctrl+b $                                  # Interactive rename prompt
```

## Killing Sessions

```bash
tmux kill-session -t myapp               # Kill named session
tmux kill-session -a                     # Kill all EXCEPT current session
tmux kill-session -a -t myapp           # Kill all EXCEPT myapp
tmux kill-server                         # Kill entire tmux server (all sessions)
# Inside tmux:
Ctrl+b :kill-session                     # Kill current session via command mode
```

## Switching Between Sessions

```bash
# Inside tmux:
Ctrl+b s                                  # Interactive session tree (navigate with arrows)
Ctrl+b w                                  # Session + window preview
Ctrl+b (                                  # Switch to previous session
Ctrl+b )                                  # Switch to next session
Ctrl+b L                                  # Switch to last (previously used) session
```

## Session Options

```bash
# Set an option on a session:
tmux set-option -t myapp option-name value

# Common session options:
tmux set-option -t myapp base-index 1              # Windows start at 1
tmux set-option -t myapp renumber-windows on       # Auto-renumber after close
tmux set-option -t myapp display-time 2000         # Status msg display time (ms)
```

## Saving & Restoring Sessions

Manual snapshot (without plugins):
```bash
# Save session layout to file:
tmux list-windows -t myapp -F '#{window_name} #{window_layout}' > session.layout

# Restore by reading the layout file in a script
```

For persistent save/restore across reboots, see [plugins.md](plugins.md) — use `tmux-resurrect`.

## Environment Variables in Sessions

```bash
# Show session environment:
tmux show-environment -t myapp

# Set a variable in session environment:
tmux set-environment -t myapp MY_VAR "hello"

# Remove a variable from session environment:
tmux set-environment -t myapp -r MY_VAR

# Global environment (all new sessions inherit):
tmux set-environment -g MY_VAR "global-value"
```

## Working with Multiple Clients

```bash
tmux list-clients                         # Show all connected clients
tmux list-clients -F '#{client_name}: #{client_session}'

# Refresh client (re-read config):
tmux refresh-client
tmux refresh-client -S                   # Refresh status bar only

# Move client to a different session:
tmux switch-client -t othersession
```
