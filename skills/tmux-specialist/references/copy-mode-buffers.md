# Copy Mode & Buffers

## Entering and Exiting Copy Mode

```bash
Ctrl+b [            # Enter copy mode (scrollback navigation)
Ctrl+b PgUp         # Enter copy mode and scroll up one page
Ctrl+b ]            # Paste from top paste buffer
q / Ctrl+c          # Exit copy mode
```

---

## Navigation in Copy Mode (vi keys — recommended)

Enable vi keys in `~/.tmux.conf`:
```
setw -g mode-keys vi
```

### Movement
| Key | Action |
|-----|--------|
| `h j k l` | Left / Down / Up / Right (vi-style) |
| `w` | Next word |
| `b` | Previous word |
| `e` | End of word |
| `0` | Start of line |
| `$` | End of line |
| `g` | Go to top of scrollback |
| `G` | Go to bottom |
| `Ctrl+u` | Scroll up half page |
| `Ctrl+d` | Scroll down half page |
| `Ctrl+b` | Scroll up full page |
| `Ctrl+f` | Scroll down full page |

### Searching
| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next search match |
| `N` | Previous search match |

### Selection and Copying
| Key | Action |
|-----|--------|
| `Space` | Begin selection |
| `v` | Begin selection (alternative) |
| `V` | Select whole line |
| `Ctrl+v` | Toggle rectangle (block) selection |
| `Enter` | Copy selection and exit copy mode |
| `y` | Copy selection (with vi keys) |
| `Esc` | Cancel selection |

---

## Navigation in Copy Mode (emacs keys — default)

| Key | Action |
|-----|--------|
| `Ctrl+a` | Start of line |
| `Ctrl+e` | End of line |
| `Ctrl+f` | Forward one character |
| `Ctrl+b` | Backward one character |
| `Alt+f` | Forward one word |
| `Alt+b` | Backward one word |
| `Ctrl+r` | Search backward |
| `Ctrl+s` | Search forward |
| `Ctrl+Space` | Begin selection |
| `Alt+w` | Copy selection |
| `Ctrl+w` | Cut selection |

---

## Paste Buffers

tmux maintains a stack of paste buffers (like a clipboard history).

```bash
# List all buffers:
tmux list-buffers
tmux list-buffers -F '#{buffer_name}: #{buffer_sample}'

# Show buffer contents:
tmux show-buffer               # Buffer 0 (most recent)
tmux show-buffer -b buffer-1  # Named buffer

# Save buffer to file:
tmux save-buffer /tmp/tmux-buf.txt
tmux save-buffer -b buffer-1 /tmp/other.txt

# Load file into buffer:
tmux load-buffer /tmp/myfile.txt
tmux load-buffer -b mybuf /tmp/myfile.txt

# Set buffer content directly (from CLI):
tmux set-buffer "text to paste"
tmux set-buffer -b mybuf "named buffer content"

# Paste buffer into pane:
tmux paste-buffer -t TARGET              # Paste most recent buffer
tmux paste-buffer -b buffer-1 -t TARGET # Paste named buffer

# Delete a buffer:
tmux delete-buffer -b buffer-1

# Interactive buffer chooser (inside tmux):
Ctrl+b =                                 # Choose and paste from buffer list
```

---

## Capturing Pane Content

```bash
# Capture visible area:
tmux capture-pane -t TARGET -p

# Capture with scrollback (last 500 lines):
tmux capture-pane -t TARGET -p -S -500

# Join wrapped lines (prevents line-wrapping artefacts):
tmux capture-pane -t TARGET -p -J -S -200

# Capture to paste buffer (not stdout):
tmux capture-pane -t TARGET
tmux show-buffer    # Then inspect the buffer

# Capture with timestamps:
tmux capture-pane -t TARGET -p -e     # Include escape sequences
```

---

## Clipboard Integration

### Linux (X11) — xclip or xsel

Add to `~/.tmux.conf`:
```tmux
# Copy to X clipboard on selection:
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'
```

### Linux (Wayland) — wl-copy

```tmux
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'wl-copy'
```

### macOS — pbcopy

```tmux
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
```

### OSC 52 (works over SSH, in most terminals)

```tmux
set -g set-clipboard on   # Let tmux use terminal's clipboard (OSC 52)
```

---

## Mouse Selection (copy mode)

Enable mouse support in `~/.tmux.conf`:
```tmux
set -g mouse on
```

- Click and drag selects text.
- Right-click pastes from the clipboard (terminal-dependent).
- Scroll wheel enters copy mode automatically when scrollback is available.

Bind drag-end to copy to system clipboard:
```tmux
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe 'xclip -in -selection clipboard'
```

---

## Pipe Pane Output to a File

Stream everything a pane produces to a file (like `script`):

```bash
# Start piping:
tmux pipe-pane -t TARGET -o 'cat >> /tmp/pane.log'

# Stop piping:
tmux pipe-pane -t TARGET     # toggle off

# Or from inside tmux:
Ctrl+b :pipe-pane -o 'cat >> ~/tmux-pane.log'
```
