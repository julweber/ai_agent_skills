#!/bin/bash
SOCKET="/tmp/pi-tmux-sockets/pi.sock"
SESSION="pi-multiagent"
INTERVAL=60

echo "👁️  Watching session: ${SESSION} (updates every ${INTERVAL}s)"
echo ""

while true; do
    timestamp=$(date '+%H:%M:%S')
    
    # Get active text from each pane (last meaningful line)
    p0=$(tmux -S "$SOCKET" capture-pane -p -J -t "${SESSION}:0.0" -S -5 | grep -v "^\s*$" | tail -1 | cut -c1-40)
    p1=$(tmux -S "$SOCKET" capture-pane -p -J -t "${SESSION}:0.1" -S -5 | grep -v "^\s*$" | tail -1 | cut -c1-40)
    p2=$(tmux -S "$SOCKET" capture-pane -p -J -t "${SESSION}:0.2" -S -5 | grep -v "^\s*$" | tail -1 | cut -c1-40)
    
    # Context usage from footer
    ctx=$(tmux -S "$SOCKET" display-message -t "${SESSION}" -p '#E' 2>/dev/null || echo "?")
    
    printf "\n\33[1m[%s]\33[0m\n" "$timestamp"
    printf "┌────────┬──────────────────────────────────────────────────────┐\n"
    printf "│ Pane   │ Status                                               │\n"
    printf "├────────┼──────────────────────────────────────────────────────┤\n"
    printf "│ 0 (Dev)│ %-40s │\n" "$p0"
    printf "│ 1 (QA) │ %-40s │\n" "$p1"
    printf "│ 2 (QA) │ %-40s │\n" "$p2"
    printf "└────────┴──────────────────────────────────────────────────────┘\n"
    
    sleep $INTERVAL
done
