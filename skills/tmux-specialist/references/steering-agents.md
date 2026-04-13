# Steering Agents via TUIs

When interacting with agents running in TUIs (like `pi`, `vim`, `less`, or `gdb`), standard `send-keys` commands must be used carefully to simulate real user input.

## Core Principles

1.  **Literal Input (`-l`)**: Always use the `-l` flag with `tmux send-keys` to prevent the shell from interpreting special characters (like `*`, `[`, `*`, `&`, etc.) in the command string.
2.  **Simulating "Enter"**: Sending a command string is not enough; you must explicitly send the `Enter` keypress to execute the command in the TUI.
3.  **Control Keys**: Use `C-<key>` notation to send control sequences (e.g., `C-c` for interrupt, `C-d` for EOF).
4.  **Wait for Prompts**: After sending a command, do not assume it has finished. Use `wait-for-text.sh` or a polling loop to verify the TUI has reached a stable state (e.g., the shell prompt returned or a specific "Done" message appeared).
5.  **Avoid "Ghost" Commands**: Ensure you aren't appending commands to a previous unfinished line. Use `tmux capture-pane` to verify the current state of the buffer before sending new input.
6.  **Stability-Based Monitoring**: To determine if a long-running agent task is truly "Done" (rather than just paused or displaying a spinner), use a stability algorithm that compares consecutive sanitized snapshots of the pane.

## Common Patterns

### Executing a Command
```bash
# Send the command text
tmux send-keys -t TARGET -l -- "ls -la"
# Send the Enter key
tmux send-keys -t TARGET Enter
```

### Interacting with REPLs (Python, Node, etc.)
When using REPLs, the agent might be in a "thinking" or "processing" state.
1.  **Send Code**: `tmux send-keys -t TARGET -l -- "print('hello')" Enter`
2.  **Wait for Prompt**: Use a regex that matches the REPL prompt (e.g., `^>>>` for Python).
3.  **Handle Multi-line**: Send each line followed by an `Enter` or use `\n` within the string.

### Interrupting a Hanging Process
If an agent or process is stuck:
```bash
tmux send-keys -t TARGET C-c
# Followed by a wait for the prompt to ensure it recovered
./scripts/wait-for-text.sh -S "$SOCKET" -t "$SESSION":0.0 -p '\$\s*$' -T 10
```

### Clearing the Buffer
If the TUI is cluttered:
```bash
tmux send-keys -t TARGET C-l
```

### Monitoring for Completion (Stability Check)
Use this pattern to detect when an agent has finished a task by checking if the terminal output has stopped changing for a specific number of rounds.

**Implementation Logic:**
1.  **Capture**: `tmux capture-pane -t <target> -p`
2.  **Sanitize**: 
    - Remove ANSI colors: `sed 's/\x1b\[[0-9;]*m//g'`
    - Remove dynamic lines (timestamps, spinners): `grep -vE 'pattern'`
3.  **Compare**: Compare current sanitized text against the previous snapshot.
4.  **Threshold**: Only declare "Done" if `STABLE_ROUNDS` (e.g., 3) consecutive snapshots are identical.

**Example Monitoring Script:**
```bash
#!/bin/bash
# monitor_agent.sh
SESSION_NAME="coding-agent"
TARGET=${1:-"$SESSION_NAME:0.0"}
INTERVAL=2
STABLE_ROUNDS=3

prev=""
stable=0

echo "Monitoring pane: $TARGET..."

while true; do
  # Capture and sanitize: remove ANSI colors and dynamic lines (timestamps)
  current=$(tmux capture-pane -t "$TARGET" -p | sed 's/\x1b\[[0-9;]*m//g' | grep -vE '([0-9]{2}:[0-9]{2}:[0-9]{2})')
  
  if [ "$current" = "$prev" ]; then
    ((stable++))
    printf "[%s] Stability: %d/%d\n" "$(date +%T)" "$stable" "$STABLE_ROUNDS"
    if [ "$stable" -ge "$STABLE_ROUNDS" ]; then
      echo "---------------------------------------"
      echo "STOPPED: Output has stabilized."
      echo "---------------------------------------"
      exit 100
    fi
  else
    stable=0
    printf "[%s] Change detected. Running...\n" "$(date +%T)"
    prev="$current"
  fi
  sleep "$INTERVAL"
done
```

## Summary Table

| Goal | Command | Notes |
|------|---------|------|
| Send command | `tmux send-keys -t T -l -- "cmd"` | Use `-l` for safety |
| Execute command | `tmux send-keys -t T Enter` | Crucial step |
| Interrupt | `tmux send-keys -t T C-c` | Stops current process |
| Exit/EOF | `tmux send-keys -t T C-d` | Closes REPL/shell |
| Clear screen | `tmux send-keys -t T C-l` | Cleans up clutter |
| Monitor stability | `monitor_agent.sh <target>` | Detects true completion |
