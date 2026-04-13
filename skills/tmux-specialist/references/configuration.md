# Configuration (~/.tmux.conf)

## Loading & Reloading Config

```bash
# Reload config without restarting tmux:
tmux source-file ~/.tmux.conf

# Inside tmux:
Ctrl+b :source-file ~/.tmux.conf

# Bind a key to reload:
bind r source-file ~/.tmux.conf \; display-message "Config reloaded"
```

---

## Essential Options

```tmux
# Change prefix from Ctrl+b to Ctrl+a (screen-style):
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse support:
set -g mouse on

# Increase scrollback buffer:
set -g history-limit 50000

# Start windows and panes at 1 (not 0):
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows automatically when one is closed:
set -g renumber-windows on

# Reduce escape-key delay (important for vim/neovim):
set -s escape-time 0
# Or with newer tmux (≥3.4):
set -s escape-time 10

# Display status messages longer:
set -g display-time 3000

# Focus events (for vim/neovim autoread):
set -g focus-events on

# 256-color and true-color:
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
```

---

## Window & Pane Behavior

```tmux
# Automatically rename windows to current command:
setw -g automatic-rename on

# Monitor windows for activity:
setw -g monitor-activity on
set -g visual-activity off   # Don't flash status bar; just change color

# Aggressive resize (use smallest client that's actually viewing):
setw -g aggressive-resize on

# Wrap around when switching windows:
set -g wrap-search off

# Keep the window open if the program exits (for debugging):
set -g remain-on-exit on     # apply per window with setw
```

---

## Key Bindings

```tmux
# ── Prefix-based bindings ──────────────────────────────────────────────
# Reload config:
bind r source-file ~/.tmux.conf \; display-message "Reloaded"

# Splits that open in current directory:
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# New window in current directory:
bind c new-window -c "#{pane_current_path}"

# Pane navigation (vim-style):
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Pane resizing (repeatable):
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Swap windows left/right:
bind -r < swap-window -d -t -1
bind -r > swap-window -d -t +1

# ── Root (no prefix) bindings ──────────────────────────────────────────
# These fire without pressing the prefix first — use sparingly:
bind -n M-Left  select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up    select-pane -U
bind -n M-Down  select-pane -D

# ── Copy-mode vi bindings ──────────────────────────────────────────────
setw -g mode-keys vi
bind -T copy-mode-vi v   send-keys -X begin-selection
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind -T copy-mode-vi y   send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind -T copy-mode-vi H   send-keys -X start-of-line
bind -T copy-mode-vi L   send-keys -X end-of-line

# ── Listing / removing bindings ────────────────────────────────────────
# tmux list-keys              # show all bindings
# tmux list-keys -T copy-mode-vi
# unbind C-b                  # remove a binding
```

---

## Status Bar

```tmux
# Position:
set -g status-position bottom    # or top

# Refresh interval (seconds):
set -g status-interval 5

# Status bar colors (256-color or #RRGGBB):
set -g status-style bg=colour235,fg=colour136

# Left side (session name):
set -g status-left-length 30
set -g status-left '#[fg=green,bold]#S #[default]'

# Right side (host + date + time):
set -g status-right-length 60
set -g status-right '#[fg=colour244]#H #[fg=colour136]%Y-%m-%d %H:%M'

# Window list:
setw -g window-status-format         '#I:#W#F'
setw -g window-status-current-format '#[fg=colour81,bold]#I:#W#F'
setw -g window-status-current-style  bg=colour238

# Pane borders:
set -g pane-border-style             fg=colour238
set -g pane-active-border-style      fg=colour51

# Message/command line:
set -g message-style bg=colour166,fg=colour232
```

---

## Environment & Shell

```tmux
# Default shell:
set -g default-shell /bin/zsh

# Default command (what the shell runs on new panes):
set -g default-command "${SHELL}"

# Pass environment variables to new sessions:
set-environment -g SOME_VAR value

# Remove a variable from the global environment:
set-environment -gu SOME_VAR

# Variables to copy from outer env into tmux env:
set -g update-environment "DISPLAY SSH_AUTH_SOCK SSH_CONNECTION"
```

---

## Nested tmux (Local + Remote)

When SSHing into a remote machine that also has tmux:

```tmux
# Outer tmux prefix: Ctrl+b
# Inner tmux prefix: Ctrl+a  (change on remote)

# To send a command to the inner tmux, press prefix twice:
# Ctrl+a Ctrl+a c   → new window in inner tmux
```

Recommended pattern: use different prefixes on local vs. remote.

```tmux
# ~/.tmux.conf on remote server:
set -g prefix C-a
unbind C-b
bind C-a send-prefix
```

---

## Conditional Configuration

```tmux
# Run block only on tmux >= 2.9:
if-shell '[ "$(tmux -V | cut -d" " -f2 | tr -d "[:alpha:]")" -ge "2.9" ]' \
  'set -g default-terminal "tmux-256color"'

# Include OS-specific config:
if-shell "uname | grep -q Darwin" "source ~/.tmux.macos.conf"
```

---

## Sample Minimal tmux.conf

```tmux
# ~/.tmux.conf — minimal, sensible defaults

set -g prefix C-a
unbind C-b
bind C-a send-prefix

set -s escape-time 0
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g mouse on
set -g focus-events on
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

setw -g mode-keys vi

bind r source-file ~/.tmux.conf \; display-message "Config reloaded"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind -T copy-mode-vi v   send-keys -X begin-selection
bind -T copy-mode-vi y   send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
```
