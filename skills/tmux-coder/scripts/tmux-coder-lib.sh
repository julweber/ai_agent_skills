#!/bin/bash

# Shared library for tmux-coder scripts
# Provides common functions for session management, agent commands, etc.

set -uo pipefail

# Default configuration
TMUX_CODER_STATE_DIR="${TMUX_CODER_STATE_DIR:-$HOME/.tmux-coder}"
TMUX_CODER_SOCKET_DIR="${TMUX_CODER_SOCKET_DIR:-${TMPDIR:-/tmp}/tmux-coder-sockets}"

# Ensure directories exist
ensure_dirs() {
    mkdir -p "$TMUX_CODER_STATE_DIR"
    mkdir -p "$TMUX_CODER_SOCKET_DIR"
}

# Generate a unique session name
generate_session_name() {
    local prefix="${1:-orchestration}"
    local timestamp
    timestamp=$(date '+%Y%m%d-%H%M%S')
    echo "${prefix}-${timestamp}"
}

# Generate a unique window label
generate_window_label() {
    local session="$1"
    local socket="$2"
    
    # Find existing labels to avoid collisions
    local existing_labels
    existing_labels=$(tmux -S "$socket" list-windows -t "$session" -F '#{window_name}' 2>/dev/null || true)
    
    # Count workers and reviewers
    local worker_count=0
    local reviewer_count=0
    
    while IFS= read -r label; do
        [[ "$label" =~ ^worker-[0-9]+$ ]] && ((worker_count++))
        [[ "$label" =~ ^reviewer-[0-9]+$ ]] && ((reviewer_count++))
    done <<< "$existing_labels"
    
    # Determine the best label prefix based on task content (if provided)
    local prefix="worker"
    
    # Auto-detect label type based on context
    if [[ ${#existing_labels} -gt 0 ]]; then
        if [[ "$worker_count" -le "$reviewer_count" ]]; then
            prefix="worker"
        else
            prefix="reviewer"
        fi
    fi
    
    # Generate unique label
    local counter=1
    while IFS= read -r label; do
        if [[ "$label" == "${prefix}-${counter}" ]]; then
            ((counter++))
        fi
    done <<< "$existing_labels"
    
    echo "${prefix}-${counter}"
}

# Get socket path for a session
get_socket_path() {
    local session="$1"
    echo "${TMUX_CODER_SOCKET_DIR}/${session}.sock"
}

# Validate agent name
validate_agent() {
    local agent="$1"
    case "$agent" in
        pi|claude|codex|opencode)
            return 0
            ;;
        *)
            echo "Error: unsupported agent '$agent'. Supported: pi, claude, codex, opencode" >&2
            return 1
            ;;
    esac
}

# Get agent command
agent_cmd() {
    local agent="$1"
    case "$agent" in
        pi)       echo "pi" ;;
        claude)   echo "claude" ;;
        codex)    echo "codex" ;;
        opencode) echo "opencode" ;;
    esac
}

# Get current pane state by examining output
get_pane_state() {
    local _pane="$1"  # pane parameter kept for interface compatibility
    local current="$2"
    local finish_string="${3:-TASK_COMPLETE}"
    
    # Check for finish string in last 20 lines
    if echo "$current" | tail -20 | grep -qF "$finish_string"; then
        echo "done"
        return
    fi
    
    echo "running"
}

# Format output for status display (truncate to N chars)
format_status_line() {
    local content="$1"
    local max_len="${2:-50}"
    
    # Get last non-empty line
    local last_line
    last_line=$(echo "$content" | grep -v '^$' | tail -1 || echo "")
    
    # Truncate if too long
    if [[ ${#last_line} -gt $max_len ]]; then
        echo "${last_line:0:$((max_len - 3))}..."
    else
        echo "$last_line"
    fi
}

# Session metadata management
get_session_metadata() {
    local session="$1"
    local key="$2"
    
    if [[ -f "$TMUX_CODER_STATE_DIR/sessions.json" ]]; then
        # Simple JSON parsing for known keys
        local value
        value=$(grep -o "\"${session}\"[[:space:]]*:[[:space:]]*{[^}]*\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
            "$TMUX_CODER_STATE_DIR/sessions.json" 2>/dev/null | \
            sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1)
        echo "$value"
    fi
}

add_session() {
    local session="$1"
    local socket="$2"
    local timestamp
    
    timestamp=$(date -Iseconds)
    ensure_dirs
    
    local sessions_file="$TMUX_CODER_STATE_DIR/sessions.json"
    
    # Create file if not exists
    if [[ ! -f "$sessions_file" ]]; then
        echo '{"sessions":{}}' > "$sessions_file"
    fi
    
    # Check if session already exists, if so update, otherwise add
    if grep -q "\"$session\"" "$sessions_file" 2>/dev/null; then
        # Update existing entry (would need jq for proper JSON manipulation)
        :
    else
        # Add new session entry (append to file)
        local tmpfile
        tmpfile=$(mktemp)
        sed "s/\(\"sessions\":{\)/\1\"$session\":{\"socket\":\"$socket\",\"created\":\"$timestamp\"},/" < "$sessions_file" > "$tmpfile"
        mv "$tmpfile" "$sessions_file"
    fi
}

remove_session() {
    local session="$1"
    
    if [[ -f "$TMUX_CODER_STATE_DIR/sessions.json" ]]; then
        local tmpfile
        tmpfile=$(mktemp)
        
        # Use jq if available for safe JSON manipulation
        if command -v jq &>/dev/null; then
            jq --arg s "$session" 'del(.sessions[$s])' "$TMUX_CODER_STATE_DIR/sessions.json" > "$tmpfile" 2>/dev/null && mv "$tmpfile" "$TMUX_CODER_STATE_DIR/sessions.json" || rm -f "$tmpfile"
        else
            # Fallback: single-line JSON manipulation
            local content
            content=$(cat "$TMUX_CODER_STATE_DIR/sessions.json")
            # Match and remove the session entry
            local pattern='"'$session'":\{[^}]*"socket":"[^"]*","created":"[^"]*"\}'
            content=$(echo "$content" | sed "s/$pattern//" | sed 's/,,/,/g' | sed 's/{"sessions":{}}/{"sessions":{}}/')
            echo "$content" > "$TMUX_CODER_STATE_DIR/sessions.json"
        fi
    fi
}

# Export functions
export -f ensure_dirs
export -f generate_session_name
export -f generate_window_label
export -f get_socket_path
export -f validate_agent
export -f agent_cmd
export -f get_pane_state
export -f format_status_line
export -f get_session_metadata
export -f add_session
export -f remove_session