#!/usr/bin/env bash
# run-pi-herdr.sh — Launch a pi agent inside a herdr terminal workspace.
#
# Usage:
#   run-pi-herdr.sh -m <model> -p "<prompt>" [options]
#
# Options:
#   -m, --model <model>              Model to use (required)
#   -p, --prompt <prompt>            Task prompt for the agent (required)
#   -sp, --system-prompt <text>      Replace pi's system prompt entirely
#   -asp, --append-system-prompt <txt> Append to system prompt (repeatable, or use @file)
#   -w, --timeout <ms>               Wait timeout in milliseconds (default: 120000)
#   -n, --name <name>                Agent name (default: auto-generated)
#   -c, --cwd <path>                 Working directory for the workspace (default: current dir)
#   -l, --label <label>              Workspace label (default: based on model name)
#   -nk, --no-keep                   Close workspace after completion (default: kept open)
#   -nw, --no-wait                   Don't wait for agent to finish; exit after prompting
#   -h, --help                       Show this help message
#
# Example:
#   run-pi-herdr.sh -m "evo/ornith-1.0-35b-Q6" -p "Explain the code in src/main.ts"
#   run-pi-herdr.sh --model "anthropic/claude-sonnet-4" --prompt "Write a hello world" --timeout 180000
#   run-pi-herdr.sh -m "qwen3.6-35b" -p "Refactor auth module" -c /path/to/project --no-keep
#   run-pi-herdr.sh -m "claude-sonnet-4" -p "Code review" --system-prompt "You are a security auditor"
#   run-pi-herdr.sh -m "gpt-4o" -p "Build a REST API" --append-system-prompt "Always add tests" --append-system-prompt @extra-rules.md

set -euo pipefail

# ── Defaults ───────────────────────────────────────────────────────────────
MODEL=""
PROMPT=""
SYSTEM_PROMPT=""
APPEND_SYSTEM_PROMPTS=()
TIMEOUT=120000
AGENT_NAME=""
CWD=""
LABEL=""
KEEP=true
WAIT=true
UNIQUE_SUFFIX="$(printf '%04d' $((RANDOM % 10000)))"  # 4-digit unique suffix for agent names

# ── Usage ──────────────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
Usage: run-pi-herdr.sh -m <model> -p "<prompt>" [options]

Launch a pi coding agent inside a herdr terminal workspace, submit a task,
wait for completion, and print the output.

Options:
  -m, --model <model>              Model to use (required)
                                    Examples: evo/ornith-1.0-35b-Q6, anthropic/claude-sonnet-4,
                                              qwen3.6-35b, openai/gpt-4o
  -p, --prompt <prompt>            Task prompt for the agent (required)
  -sp, --system-prompt <text>      Replace pi's entire system prompt
  -asp, --append-system-prompt <txt> Append to system prompt (repeatable; use @file for file contents)
  -w, --timeout <ms>               Wait timeout in milliseconds (default: 120000)
  -n, --name <name>                Agent name (default: auto-generated from model)
  -c, --cwd <path>                 Working directory for the workspace (default: current dir)
  -l, --label <label>              Workspace label (default: based on model name)
  -nk, --no-keep                   Close workspace after completion (default: kept open)
  -nw, --no-wait                   Don't wait for agent to finish; exit after prompting
  -h, --help                       Show this help message

Examples:
  # Simple task with a specific model
  run-pi-herdr.sh -m "evo/ornith-1.0-35b-Q6" -p "say hello"

  # Task with custom timeout and working directory
  run-pi-herdr.sh -m "anthropic/claude-sonnet-4" \
      -p "Refactor the auth module" \
      -c /path/to/project \
      -w 180000

  # Close workspace after completion (default is kept open)
  run-pi-herdr.sh -m "qwen3.6-35b" -p "List all .ts files" --no-keep

  # Custom agent name (workspace kept open by default)
  run-pi-herdr.sh -m "evo/ornith-1.0-35b-Q6" -n "my-coder" -p "Build a REST API"

  # Replace system prompt entirely
  run-pi-herdr.sh -m "claude-sonnet-4" -p "Code review" \
      --system-prompt "You are a senior security auditor focused on finding vulnerabilities."

  # Append extra instructions (repeatable, supports @file syntax)
  run-pi-herdr.sh -m "gpt-4o" -p "Build a REST API" \
      --append-system-prompt "Always write tests alongside code" \
      --append-system-prompt "@coding-standards.md"

  # Fire-and-forget: start agent, submit task, exit immediately
  run-pi-herdr.sh -m "qwen3.6-35b" -p "Run the full test suite" --no-wait
EOF
}

# ── Parse arguments ───────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
    usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model)
            MODEL="$2"; shift 2 ;;
        -p|--prompt)
            PROMPT="$2"; shift 2 ;;
        -sp|--system-prompt)
            SYSTEM_PROMPT="$2"; shift 2 ;;
        -asp|--append-system-prompt)
            APPEND_SYSTEM_PROMPTS+=("$2"); shift 2 ;;
        -w|--timeout)
            TIMEOUT="$2"; shift 2 ;;
        -n|--name)
            AGENT_NAME="$2"; shift 2 ;;
        -c|--cwd)
            CWD="$2"; shift 2 ;;
        -l|--label)
            LABEL="$2"; shift 2 ;;
        -nk|--no-keep)
            KEEP=false; shift ;;
        -nw|--no-wait)
            WAIT=false; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            echo "Use --help for usage information." >&2
            exit 1 ;;
    esac
done

# ── Validate ──────────────────────────────────────────────────────────────
if [[ -z "$MODEL" ]]; then
    echo "ERROR: Model is required. Use -m or --model." >&2
    exit 1
fi

if [[ -z "$PROMPT" ]]; then
    echo "ERROR: Prompt is required. Use -p or --prompt." >&2
    exit 1
fi

# ── Defaults from model ───────────────────────────────────────────────────
MODEL_SHORT="${MODEL##*/}"  # strip provider prefix
# Sanitize agent name: lowercase, replace dots with underscores, truncate to 28 chars
# (leaves room for "pi-" prefix = 32 char max)
SAFE_MODEL="${MODEL_SHORT//./_}"
SAFE_MODEL="${SAFE_MODEL,,}"  # lowercase
SAFE_MODEL="${SAFE_MODEL:0:28}"
if [[ -z "$AGENT_NAME" ]]; then
    AGENT_NAME="pi-${SAFE_MODEL}-${UNIQUE_SUFFIX}"
fi
if [[ -z "$LABEL" ]]; then
    LABEL="pi-${MODEL_SHORT}-${UNIQUE_SUFFIX}"
fi
if [[ -z "$CWD" ]]; then
    CWD="$(pwd)"
fi

# ── Remove stale agent with same base name ────────────────────────────────
BASE_AGENT="pi-${SAFE_MODEL}"
STALE=$(herdr agent list 2>/dev/null | jq -r --arg base "$BASE_AGENT-" '.result.agents[] | select((.name // "") | startswith($base)) | .name' | head -1)
if [[ -n "$STALE" ]]; then
    echo "Removing stale agent: $STALE"
    herdr agent remove "$STALE" >/dev/null 2>&1 || true
fi

# ── Ensure herdr server is running ────────────────────────────────────────
if ! herdr status >/dev/null 2>&1; then
    echo "Starting herdr server..."
    nohup herdr server > /tmp/herdr-server.log 2>&1 &
    sleep 2
    if ! herdr status >/dev/null 2>&1; then
        echo "ERROR: herdr server failed to start. Check /tmp/herdr-server.log" >&2
        exit 1
    fi
fi

# ── Create workspace ──────────────────────────────────────────────────────
echo "Creating workspace: $LABEL (cwd: $CWD)"
WS_OUTPUT=$(herdr workspace create --label "$LABEL" --cwd "$CWD")
WS=$(echo "$WS_OUTPUT" | jq -r '.result.workspace.workspace_id')
echo "  Workspace ID: $WS"

# ── Get default tab & pane (workspace creates one automatically) ────────
TAB=$(herdr tab list --workspace "$WS" | jq -r '.result.tabs[0].tab_id')
echo "  Tab ID: $TAB"

PANE=$(herdr pane list --workspace "$WS" | jq -r '.result.panes[0].pane_id')
echo "  Pane ID: $PANE"

# ── Build pi CLI arguments ────────────────────────────────────────────────
PI_ARGS=("--model" "$MODEL")

if [[ -n "$SYSTEM_PROMPT" ]]; then
    PI_ARGS+=("--system-prompt" "$SYSTEM_PROMPT")
fi

for extra in "${APPEND_SYSTEM_PROMPTS[@]+"${APPEND_SYSTEM_PROMPTS[@]}"}"; do
    PI_ARGS+=("--append-system-prompt" "$extra")
done

# ── Start pi agent ───────────────────────────────────────────────────────
echo "Starting pi agent: $AGENT_NAME (model: $MODEL)"
herdr agent start "$AGENT_NAME" --kind pi --pane "$PANE" -- "${PI_ARGS[@]}"
sleep 3

# Verify agent started
AGENT_STATUS=$(herdr agent list | jq -r ".result.agents[] | select(.name == \"$AGENT_NAME\") | .agent_status")
if [[ -z "$AGENT_STATUS" ]]; then
    echo "ERROR: Agent '$AGENT_NAME' not found after start." >&2
    echo "Cleaning up workspace..."
    herdr workspace close "$WS" >/dev/null 2>&1
    exit 1
fi
echo "  Agent status: $AGENT_STATUS"

# ── Submit task ───────────────────────────────────────────────────────────
echo "Submitting task: $PROMPT"
if [[ "$WAIT" != true ]]; then
    echo "  Mode: fire-and-forget (not waiting for completion)"
else
    echo "  Timeout: ${TIMEOUT}ms"
fi
echo "---"

if [[ "$WAIT" == true ]]; then
    herdr agent prompt "$AGENT_NAME" "$PROMPT" --wait --timeout "$TIMEOUT"

    # ── Read output ───────────────────────────────────────────────────────
    echo ""
    echo "=== Agent Output ==="
    herdr agent read "$AGENT_NAME" --source recent --lines 200
else
    herdr agent prompt "$AGENT_NAME" "$PROMPT"
fi

# ── Cleanup ───────────────────────────────────────────────────────────────
if [[ "$KEEP" != true ]]; then
    echo ""
    echo "Closing workspace $WS..."
    herdr workspace close "$WS" >/dev/null 2>&1
else
    echo ""
    echo "Workspace kept open (ID: $WS). Close with: herdr workspace close $WS"
    echo "Attach with: herdr agent attach $AGENT_NAME"
fi
