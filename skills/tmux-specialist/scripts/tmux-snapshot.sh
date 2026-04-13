#!/usr/bin/env bash
# tmux-snapshot.sh — dump all pane contents from a session to files or stdout.
#
# Usage: tmux-snapshot.sh [OPTIONS] SESSION
#
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: tmux-snapshot.sh [OPTIONS] SESSION

Dump the scrollback content of every pane in a session to files or stdout.

Options:
  -S, --socket-path   tmux socket path
  -L, --socket-name   tmux socket name
  -o, --output-dir    directory to write pane files into (default: stdout)
  -l, --lines         scrollback lines to capture (default: 500)
  -J, --join          join wrapped lines (default: on)
  -h, --help          show this help

Output files (when --output-dir is set):
  SESSION-WINDOW-PANE.txt   for each pane found
USAGE
}

socket_path=""
socket_name=""
output_dir=""
lines=500
join_flag="-J"
session=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -S|--socket-path) socket_path="${2-}"; shift 2 ;;
    -L|--socket-name) socket_name="${2-}"; shift 2 ;;
    -o|--output-dir)  output_dir="${2-}";  shift 2 ;;
    -l|--lines)       lines="${2-}";       shift 2 ;;
    --no-join)        join_flag="";        shift   ;;
    -h|--help)        usage; exit 0        ;;
    -*)               echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *)                session="$1";        shift   ;;
  esac
done

[[ -z "$session" ]] && { echo "SESSION is required" >&2; usage; exit 1; }
[[ "$lines" =~ ^[0-9]+$ ]] || { echo "lines must be an integer" >&2; exit 1; }
command -v tmux >/dev/null 2>&1 || { echo "tmux not found in PATH" >&2; exit 1; }

T=(tmux)
[[ -n "$socket_path" ]] && T+=(-S "$socket_path")
[[ -n "$socket_name" ]] && T+=(-L "$socket_name")

# Verify session exists
"${T[@]}" has-session -t "$session" 2>/dev/null \
  || { echo "Session '$session' not found" >&2; exit 1; }

[[ -n "$output_dir" ]] && mkdir -p "$output_dir"

# Iterate over all panes in the session
while IFS=$'\t' read -r win_idx win_name pane_idx pane_id; do
  target="${session}:${win_idx}.${pane_idx}"
  content=$("${T[@]}" capture-pane -p $join_flag -t "$target" -S "-${lines}" 2>/dev/null || true)

  if [[ -n "$output_dir" ]]; then
    # Sanitize window name for filename
    safe_name="${win_name//[^a-zA-Z0-9_-]/_}"
    outfile="${output_dir}/${session}-${safe_name}-pane${pane_idx}.txt"
    printf '%s\n' "$content" > "$outfile"
    echo "Wrote: $outfile"
  else
    echo "=== ${session}:${win_name}(${win_idx}).${pane_idx} ==="
    printf '%s\n' "$content"
    echo ""
  fi
done < <("${T[@]}" list-panes -s -t "$session" \
            -F '#{window_index}\t#{window_name}\t#{pane_index}\t#{pane_id}')
