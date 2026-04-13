#!/usr/bin/env bash
# session-layout.sh — create named multi-pane tmux session layouts.
#
# Usage: session-layout.sh [OPTIONS] LAYOUT_NAME
#
# Layouts:
#   dev        Left: main shell, Right-top: editor/build, Right-bottom: logs
#   monitor    Top: main, Bottom-left: log1, Bottom-right: log2
#   grid4      4-pane 2×2 grid
#   triple-h   3 horizontal panes (side by side)
#   triple-v   3 vertical panes (stacked)
#   custom     1 big left pane + 3 small right panes stacked
#
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: session-layout.sh [OPTIONS] LAYOUT_NAME

Create a tmux session with a pre-defined pane layout.

Options:
  -S, --socket-path   tmux socket path
  -L, --socket-name   tmux socket name
  -s, --session       session name (default: layout name)
  -d, --dir           starting directory (default: $PWD)
  -h, --help          show this help

Layout names:
  dev        2-column: main shell | (top: build, bottom: logs)
  monitor    large top pane + 2 bottom panes for tailing logs
  grid4      2×2 grid of equal panes
  triple-h   3 equal panes side by side
  triple-v   3 equal panes stacked
  custom     large left (60%) + 3 small right panes stacked
USAGE
}

socket_path=""
socket_name=""
session=""
dir="${PWD}"
layout=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -S|--socket-path) socket_path="${2-}"; shift 2 ;;
    -L|--socket-name) socket_name="${2-}"; shift 2 ;;
    -s|--session)     session="${2-}";     shift 2 ;;
    -d|--dir)         dir="${2-}";         shift 2 ;;
    -h|--help)        usage; exit 0        ;;
    -*)               echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *)                layout="$1";         shift   ;;
  esac
done

[[ -z "$layout" ]] && { echo "LAYOUT_NAME is required" >&2; usage; exit 1; }
[[ -z "$session" ]] && session="$layout"

command -v tmux >/dev/null 2>&1 || { echo "tmux not found in PATH" >&2; exit 1; }

# Build base tmux command
T=(tmux)
[[ -n "$socket_path" ]] && T+=(-S "$socket_path")
[[ -n "$socket_name" ]] && T+=(-L "$socket_name")

# Kill stale session if it exists
"${T[@]}" kill-session -t "$session" 2>/dev/null || true

case "$layout" in

  dev)
    # Window 'main': left shell (60%) | right column split top/bottom
    "${T[@]}" new-session  -d -s "$session" -n main -c "$dir"
    "${T[@]}" split-window -h -p 40 -t "$session":main -c "$dir"   # right pane (40%)
    "${T[@]}" split-window -v -t "$session":main.1 -c "$dir"       # split right top/bottom
    "${T[@]}" select-pane  -t "$session":main.0
    echo "Layout: dev — pane 0=shell (left), pane 1=build (top-right), pane 2=logs (bottom-right)"
    ;;

  monitor)
    # Large top pane + 2 log panes at the bottom
    "${T[@]}" new-session  -d -s "$session" -n dashboard -c "$dir"
    "${T[@]}" split-window -v -p 30 -t "$session":dashboard -c "$dir"  # bottom 30%
    "${T[@]}" split-window -h -t "$session":dashboard.1 -c "$dir"       # split bottom
    "${T[@]}" select-pane  -t "$session":dashboard.0
    echo "Layout: monitor — pane 0=main (top 70%), pane 1=log1 (bottom-left), pane 2=log2 (bottom-right)"
    ;;

  grid4)
    "${T[@]}" new-session  -d -s "$session" -n grid -c "$dir"
    "${T[@]}" split-window -h    -t "$session":grid -c "$dir"
    "${T[@]}" split-window -v    -t "$session":grid.0 -c "$dir"
    "${T[@]}" split-window -v    -t "$session":grid.1 -c "$dir"
    "${T[@]}" select-layout -t "$session":grid tiled
    "${T[@]}" select-pane  -t "$session":grid.0
    echo "Layout: grid4 — 4 equal panes in a 2×2 grid"
    ;;

  triple-h)
    "${T[@]}" new-session  -d -s "$session" -n main -c "$dir"
    "${T[@]}" split-window -h    -t "$session":main -c "$dir"
    "${T[@]}" split-window -h    -t "$session":main.0 -c "$dir"
    "${T[@]}" select-layout -t "$session":main even-horizontal
    "${T[@]}" select-pane  -t "$session":main.0
    echo "Layout: triple-h — 3 equal panes side by side"
    ;;

  triple-v)
    "${T[@]}" new-session  -d -s "$session" -n main -c "$dir"
    "${T[@]}" split-window -v    -t "$session":main -c "$dir"
    "${T[@]}" split-window -v    -t "$session":main.0 -c "$dir"
    "${T[@]}" select-layout -t "$session":main even-vertical
    "${T[@]}" select-pane  -t "$session":main.0
    echo "Layout: triple-v — 3 equal panes stacked"
    ;;

  custom)
    # Large left (60%) + 3 small right panes stacked
    "${T[@]}" new-session  -d -s "$session" -n main -c "$dir"
    "${T[@]}" split-window -h -p 40 -t "$session":main -c "$dir"
    "${T[@]}" split-window -v    -t "$session":main.1 -c "$dir"
    "${T[@]}" split-window -v    -t "$session":main.1 -c "$dir"
    "${T[@]}" select-pane  -t "$session":main.0
    echo "Layout: custom — pane 0=large left (60%), panes 1-3=small right column"
    ;;

  *)
    echo "Unknown layout: $layout" >&2
    echo "Available: dev, monitor, grid4, triple-h, triple-v, custom" >&2
    exit 1
    ;;
esac

echo ""
echo "Session '$session' created. Attach with:"
if [[ -n "$socket_path" ]]; then
  echo "  tmux -S '$socket_path' attach -t '$session'"
elif [[ -n "$socket_name" ]]; then
  echo "  tmux -L '$socket_name' attach -t '$session'"
else
  echo "  tmux attach -t '$session'"
fi
