# Plugins (TPM & Common Plugins)

## TPM — Tmux Plugin Manager

### Installation

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Add to the bottom of `~/.tmux.conf`:

```tmux
# Plugin list:
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Initialize TPM (always last line):
run '~/.tmux/plugins/tpm/tpm'
```

### TPM Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+b I` | Install new plugins (from the list in tmux.conf) |
| `Ctrl+b U` | Update all plugins |
| `Ctrl+b Alt+u` | Remove/uninstall unused plugins |

### Installing from CLI (no key binding)

```bash
~/.tmux/plugins/tpm/scripts/install_plugins.sh
~/.tmux/plugins/tpm/scripts/update_plugin.sh PLUGIN_NAME
~/.tmux/plugins/tpm/scripts/clean_plugins.sh
```

---

## tmux-sensible

Sane defaults that most people agree on. Load it before your own config to avoid repetition.

```tmux
set -g @plugin 'tmux-plugins/tmux-sensible'
```

Sets: `escape-time 0`, `history-limit 50000`, `display-time 4000`, correct `$TERM`,
enables `focus-events`, `aggressive-resize`, and sensible default bindings.

---

## tmux-resurrect

Save and restore tmux sessions across reboots.

```tmux
set -g @plugin 'tmux-plugins/tmux-resurrect'

# Optional: restore vim/neovim sessions too:
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'

# Restore pane contents (the scrollback):
set -g @resurrect-capture-pane-contents 'on'
```

| Key | Action |
|-----|--------|
| `Ctrl+b Ctrl+s` | Save session |
| `Ctrl+b Ctrl+r` | Restore session |

Save files go to `~/.tmux/resurrect/`.

---

## tmux-continuum

Automatically and continuously saves sessions (every 15 minutes by default).
Optionally restores the last saved environment on tmux server start.

```tmux
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-resurrect'   # continuum depends on resurrect

# Auto-restore on server start:
set -g @continuum-restore 'on'

# Custom save interval (minutes):
set -g @continuum-save-interval '10'

# Show save status in status bar:
set -g status-right 'Continuum: #{continuum_status}'
```

---

## tmux-yank

Enhanced clipboard copy — copies to system clipboard from copy mode and from
the command line.

```tmux
set -g @plugin 'tmux-plugins/tmux-yank'

# Optional: keep cursor position after yank (instead of exiting copy mode):
set -g @yank_action 'copy-pipe'   # default: copy-pipe-and-cancel
```

Copy mode bindings added by tmux-yank:

| Key | Action |
|-----|--------|
| `y` | Copy selection to system clipboard |
| `Y` | Copy line to clipboard |
| `Ctrl+y` | Copy and paste (shortcut) |

---

## tmux-open

Open files and URLs from copy mode.

```tmux
set -g @plugin 'tmux-plugins/tmux-open'
```

| Key (copy mode) | Action |
|-----------------|--------|
| `o` | Open selection with `xdg-open` / `open` |
| `Ctrl+o` | Open with `$EDITOR` |
| `S` | Web search selection (Google by default) |

```tmux
# Custom search engine:
set -g @open-S 'https://www.duckduckgo.com/?q='
```

---

## tmux-fzf

Fuzzy-find sessions, windows, panes, and commands.

```tmux
set -g @plugin 'sainnhe/tmux-fzf'

# Bind to a key:
TMUX_FZF_LAUNCH_KEY="C-f"
```

---

## tmux-prefix-highlight

Highlights the status bar when the prefix key is pressed.

```tmux
set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
set -g status-right '#{prefix_highlight} | %a %Y-%m-%d %H:%M'
```

---

## tmux-cpu / tmux-mem-cpu-load

Show CPU/memory in the status bar.

```tmux
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g status-right '#{cpu_percentage} CPU | #{ram_percentage} RAM'
```

---

## Catppuccin / Tokyo Night / Other Themes

Popular theme plugins:

```tmux
# Catppuccin:
set -g @plugin 'catppuccin/tmux'
set -g @catppuccin_flavor 'mocha'  # latte / frappe / macchiato / mocha

# Tokyo Night:
set -g @plugin 'janoamaral/tokyo-night-tmux'

# Dracula:
set -g @plugin 'dracula/tmux'
set -g @dracula-plugins "cpu-usage ram-usage time"
```

---

## Manual Plugin Installation (without TPM)

```bash
# Clone plugin into the plugins directory:
git clone https://github.com/tmux-plugins/tmux-sensible ~/.tmux/plugins/tmux-sensible

# Add to tmux.conf:
run-shell ~/.tmux/plugins/tmux-sensible/sensible.tmux

# Apply immediately without restarting:
tmux source-file ~/.tmux.conf
```

---

## Full tmux.conf with Plugins Example

```tmux
# ~/.tmux.conf

set -g prefix C-a
unbind C-b
bind C-a send-prefix

set -s escape-time 0
set -g history-limit 100000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g mouse on

setw -g mode-keys vi
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

bind r source-file ~/.tmux.conf \; display-message "Reloaded"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'; unbind %

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# ── Plugins ────────────────────────────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'catppuccin/tmux'

set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'
set -g @catppuccin_flavor 'mocha'

run '~/.tmux/plugins/tpm/tpm'
```
