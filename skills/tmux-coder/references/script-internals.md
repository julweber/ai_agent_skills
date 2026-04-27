# tmux-coder Script Internals

Technical details about how the tmux-coder scripts work.

## Architecture

```
tmux-coder/
├── SKILL.md                    # Skill definition for agent invocation
├── scripts/
│   ├── tmux-coder-lib.sh      # Shared library (sourced by all scripts)
│   ├── tmux-spawn-agent       # Spawn agent in new window
│   ├── tmux-list-sessions     # List managed sessions
│   ├── tmux-agent-status      # Show pane status information
│   ├── tmux-ensure-progress   # Background watcher
│   └── tmux-kill-session      # Terminate session
└── references/
    ├── usage-guide.md         # User-facing documentation
    └── script-internals.md    # This file
```

## Socket Convention

Each tmux-coder session uses its own socket to avoid conflicts:

```
${TMUX_CODER_SOCKET_DIR}/${SESSION}.sock
```

Default: `/tmp/tmux-coder-sockets/{session}.sock`

This allows multiple tmux-coder sessions to run independently.

## Session Tracking

Sessions are tracked in `~/.tmux-coder/sessions.json`:

```json
{
  "sessions": {
    "myproject": {
      "socket": "/tmp/tmux-coder-sockets/myproject.sock",
      "created": "2026-04-17T14:30:52+00:00"
    }
  }
}
```

The tracking file is updated when:
- A session is first created (`tmux-spawn-agent`)
- A session is killed (`tmux-kill-session`)

## Window Label Generation

Labels are auto-generated to avoid collisions:

1. Scan existing window labels in the session
2. Count existing `worker-N` and `reviewer-N` labels
3. Create a new unique label based on which type is fewer

Example: If `worker-1`, `worker-2` exist, the next will be `worker-3`.

## State Detection Algorithm

The status and watcher scripts use a state machine for each pane:

```
UNKNOWN ──first capture──> RUNNING
   │                         │
   │                    output changes
   │                         │
   │                         ▼
   │                      RUNNING
   │                         │
   │               ┌────────┴────────┐
   │          output         output
   │          changes         same
   │               │              │
   │               ▼              ▼
   │            RUNNING    ┌──────┴──────┐
   │               │      │stable >= N   │
   │               │      │              │
   │               │      ▼              ▼
   │               │     STUCK ──same──> STUCK
   │               │       (sends prompt)
   │               ▼              │
   │            RUNNING <─────────┘
   │               │
   │          finish string
   │               │
   │               ▼
   │              DONE (terminal)
```

## Finish String Detection

The finish string is checked in two places:

1. **During monitoring**: `tail -20` of pane capture to find the string
2. **On final verification**: Same check, but also re-prompts if not found

This prevents false positives from the initial prompt containing the finish-string instruction.

## Inter-Agent Communication

Currently, inter-agent communication is handled via tmux send-keys:

1. Orchestrator sends a message to a specific pane
2. The worker agent processes it and responds
3. Orchestrator captures the response via `capture-pane`

Future enhancements could include:
- Named pipes for faster communication
- JSON-based structured messages
- Acknowledgment protocols

## Error Handling

Current error handling:

- Missing session: Exit with error message
- Invalid agent: Exit with supported agent list
- Socket not found: Exit with error
- Tmux not running: Exit with error

Not yet implemented (deferred):
- Agent crash detection and restart
- Socket conflict resolution
- Session recovery after tmux restart
- Persistent state in JSON for crash recovery