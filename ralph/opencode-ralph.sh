#!/bin/bash
# OpenCode Ralph Loop - Autonomous AI coding agent loop
# Usage: ./opencode-ralph.sh [max_iterations]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../.."
PRD_FILE="$PROJECT_ROOT_DIR/tasks/prd.json"
PROGRESS_FILE="$PROJECT_ROOT_DIR/tasks/progress.txt"
ARCHIVE_DIR="$PROJECT_ROOT_DIR/tasks/archive"
LAST_BRANCH_FILE="$PROJECT_ROOT_DIR/tasks/.last-branch"
LOG_FILE="$PROJECT_ROOT_DIR/tasks/agent_output.log"

PROMPT_FILE="$SCRIPT_DIR/prompt.md"

echo "###### CONFIGURATION ######"
echo 
echo "Ralph script dir: $SCRIPT_DIR"
echo "PROJECT_ROOT_DIR: $PROJECT_ROOT_DIR"
echo "PRD_FILE: $PRD_FILE"
echo "PROGRESS_FILE: $PROGRESS_FILE"
echo "ARCHIVE_DIR: $ARCHIVE_DIR"
echo "LAST_BRANCH_FILE: $LAST_BRANCH_FILE"
echo "LOG_FILE: $LOG_FILE"
echo
echo "opencode executable: $(which opencode)"
echo "###########################"

# Parse arguments
MAX_ITERATIONS=${1:-10}
: 0

# Archive previous run if branch changed (from tasks/prd.json)
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=${CURRENT_BRANCH#ralph/}
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"

    echo "# OpenCode Ralph Progress Log" > "$PROGRESS_FILE"
  fi
fi

# Track current branch from prd.json
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# OpenCode Ralph Progress Log" > "$PROGRESS_FILE"
fi

echo "Starting OpenCode Ralph Loop - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 "$MAX_ITERATIONS"); do
  : "$i"

  if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: prompt.md not found at $PROMPT_FILE"
    exit 1
  fi

  echo ""
  echo "==============================================================="
  echo "  Iteration $i of $MAX_ITERATIONS"
  echo "==============================================================="
  echo ""

  set +e
  # Run OpenCode with the task from prompt.md (which reads tasks/prd.json internally)
  OUTPUT=$(opencode run --dir "$PROJECT_ROOT_DIR" --format default --title "Ralph Loop Task $i" < "$PROMPT_FILE" 2>&1)
  OPENCODE_STATUS="$?"
  set -e

  if [[ "$OPENCODE_STATUS" != "0" ]]; then
    echo "ATTENTION: !!! Opencode failed with status: $OPENCODE_STATUS !!!"
    echo "See $LOG_FILE for details"
    echo 
  fi


  echo "Appending agent output to log file ..."

  {
    echo "----------- AGENT OUTPUT  for iteration $i ---------------" 
    echo ""
    echo "$OUTPUT"
    echo ""
    echo "----------- AGENT OUTPUT END for iteration $i -----------"
  } >> "$LOG_FILE"
  
  # Check for completion signal
  if echo "$OUTPUT" | grep -qi "<promise>COMPLETE</promise>"; then
    {
      echo "$(date): Ralph completed all tasks at iteration $i"
      echo "---"
    } >> "$PROGRESS_FILE"

    echo ""
    echo "=========================================="
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    echo "=========================================="
    exit 0
  fi

  {
    echo "$(date): Iteration $i complete"
    echo "---"
  } >> "$PROGRESS_FILE"

  echo ""
  echo "Iteration $i complete. Continuing..."
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
exit 1