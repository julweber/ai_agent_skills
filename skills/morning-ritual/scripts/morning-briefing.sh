#!/usr/bin/env bash
# morning-briefing.sh — Main orchestration script for the morning ritual.
#
# Queries local vault calendars (with obsidian CLI or grep fallback),
# external ICS calendars via Python script, and collects tasks.
#
# Usage:
#   ./morning-briefing.sh [vault_path] [days_ahead]
#
# Defaults:
#   vault_path: $HOME/main_vault
#   days_ahead: 5

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
VAULT_PATH="${1:-$HOME/main_vault}"
DAYS_AHEAD="${2:-5}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TODAY=$(date +%Y-%m-%d)

# ── Obsidian CLI Detection ───────────────────────────────────────────────────
USE_OBSIDIAN=false
if command -v obsidian &>/dev/null; then
    USE_OBSIDIAN=true
else
    echo "[⚠️ Obsidian CLI not found — using file-based fallback]" >&2
fi

# ── Step 1: Query Local Vault Calendars ──────────────────────────────────────
query_local_calendars() {
    local calendar_dir="$VAULT_PATH/01-Calendars"
    
    if [ ! -d "$calendar_dir" ]; then
        echo "Warning: Calendar directory not found: $calendar_dir" >&2
        return
    fi

    if [ "$USE_OBSIDIAN" = true ]; then
        # Use obsidian CLI search for each date
        local d="$TODAY"
        for i in $(seq 0 $DAYS_AHEAD); do
            local search_date
            if [ "$i" -eq 0 ]; then
                search_date="$TODAY"
            else
                search_date=$(date -d "+$i day" +%Y-%m-%d)
            fi
            obsidian search "query=$search_date" "path=01-Calendars" format=json 2>/dev/null || true
        done
    else
        # Fallback: grep for date-tagged files
        local d="$TODAY"
        for i in $(seq 0 $DAYS_AHEAD); do
            local search_date
            if [ "$i" -eq 0 ]; then
                search_date="$TODAY"
            else
                search_date=$(date -d "+$i day" +%Y-%m-%d)
            fi
            # Find files containing the date in their content
            grep -rl "$search_date" "$calendar_dir" 2>/dev/null | head -20 || true
        done
    fi
}

# ── Step 2: Query External ICS Calendars ─────────────────────────────────────
query_external_calendars() {
    python3 "$SCRIPT_DIR/query_calendars.py" --days "$DAYS_AHEAD" 2>/dev/null || \
        echo "Warning: Could not query external calendars" >&2
}

# ── Step 3: Collect Tasks ────────────────────────────────────────────────────
collect_tasks() {
    if [ "$USE_OBSIDIAN" = true ]; then
        obsidian tasks todo verbose=false format=json 2>/dev/null || true
    else
        # Fallback: grep for unchecked tasks in task files
        find "$VAULT_PATH/00-Tasks" -name "*.md" -exec grep -l "^\- \[ \]" {} \; 2>/dev/null || true
    fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
echo "=== Morning Briefing Script ==="
echo "Vault: $VAULT_PATH"
echo "Today: $TODAY"
echo "Obsidian CLI: $USE_OBSIDIAN"
echo ""

echo "--- Local Calendar Events ---"
query_local_calendars

echo ""
echo "--- External Calendar Events ---"
query_external_calendars

echo ""
echo "--- Tasks ---"
collect_tasks
