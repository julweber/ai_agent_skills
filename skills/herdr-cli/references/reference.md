# herdr-cli — Reference

Detailed reference for herdr CLI commands moved here to keep SKILL.md under 500 lines.

## AI Agent Integration

### Installing Integrations

herdr supports built-in integrations for 20+ AI coding agents. Install the integration for agent detection and lifecycle tracking:

```bash
# List available integrations and their status
# Note: 6 --kind values lack integrations: gemini, agy, cline, kiro, amp, maki
herdr integration status

# Show only outdated integrations
herdr integration status --outdated-only

# Install integrations
herdr integration install pi
herdr integration install claude
herdr integration install codex
herdr integration install gemini
herdr integration install cursor
herdr integration install devin
herdr integration install agy
herdr integration install cline
herdr integration install omp
herdr integration install mastracode
herdr integration install opencode
herdr integration install copilot
herdr integration install kimi
herdr integration install kiro
herdr integration install droid
herdr integration install amp
herdr integration install grok
herdr integration install hermes
herdr integration install kilo
herdr integration install qodercli
herdr integration install maki

# Uninstall an integration
herdr integration uninstall pi
```

### Agent Manifest Management

Agent detection manifests define how herdr recognizes and tracks agents:

```bash
# Show active agent detection manifests
herdr server agent-manifests

# Show as JSON
herdr server agent-manifests --json

# Fetch and reload agent detection manifests from upstream
herdr server update-agent-manifests

# Reload local agent detection manifest overrides
herdr server reload-agent-manifests
```

## Custom Agent Integration

For building integrations with agents not yet supported by herdr, use the pane-level lifecycle reporting API. This lets a custom agent signal its state to herdr.

### Agent Lifecycle Reporting

```bash
# Report agent lifecycle state (idle, working, blocked, unknown)
herdr pane report-agent <pane_id> \
  --source <source_id> \
  --agent <label> \
  --state idle

# With optional message and sequence number
herdr pane report-agent <pane_id> \
  --source my-agent \
  --agent my-agent-label \
  --state working \
  --message "Processing request" \
  --seq 1

# With session tracking
herdr pane report-agent <pane_id> \
  --source my-agent \
  --agent my-agent-label \
  --state working \
  --agent-session-id session-123 \
  --agent-session-path /path/to/session
```

### Agent Session Identity

```bash
# Report agent session identity (establishes session tracking)
herdr pane report-agent-session <pane_id> \
  --source my-agent \
  --agent my-agent-label \
  --agent-session-id session-123 \
  --agent-session-path /path/to/session

# With sequence number and session start source
herdr pane report-agent-session <pane_id> \
  --source my-agent \
  --agent my-agent-label \
  --seq 1 \
  --session-start-source config
```

### Releasing Agent Authority

```bash
# Release pane agent lifecycle authority (when agent exits)
herdr pane release-agent <pane_id> \
  --source my-agent \
  --agent my-agent-label

# With sequence number
herdr pane release-agent <pane_id> \
  --source my-agent \
  --agent my-agent-label \
  --seq 10
```

### Custom Agent Display Metadata

```bash
# Report display-only metadata for a pane
herdr pane report-metadata <pane_id> \
  --source my-agent \
  --title "My Custom Agent" \
  --display-agent "my-agent" \
  --state-label idle="Ready" \
  --state-label working="Processing" \
  --token progress="50%" \
  --ttl-ms 60000

# Clear specific metadata
herdr pane report-metadata <pane_id> \
  --source my-agent \
  --clear-title \
  --clear-display-agent \
  --clear-state-labels \
  --clear-token progress

# Apply metadata to a different source
herdr pane report-metadata <pane_id> \
  --source my-agent \
  --applies-to-source other-source \
  --title "Cross-Source Info"
```

### Custom Integration Pattern

A complete custom agent integration follows this lifecycle:

```bash
# 1. Start agent in pane
herdr agent start "my-agent" --kind pi --pane <pane_id>

# 2. Agent signals session identity
herdr pane report-agent-session <pane_id> \
  --source my-agent --agent my-agent \
  --agent-session-id sess-001

# 3. Agent reports display metadata
herdr pane report-metadata <pane_id> \
  --source my-agent --title "My Agent" \
  --display-agent "my-agent" \
  --state-label idle="Ready" --state-label working="Working"

# 4. Agent reports state transitions
herdr pane report-agent <pane_id> \
  --source my-agent --agent my-agent --state working \
  --message "Processing task"

# 5. On completion, report idle
herdr pane report-agent <pane_id> \
  --source my-agent --agent my-agent --state idle

# 6. When done, release authority
herdr pane release-agent <pane_id> \
  --source my-agent --agent my-agent
```

## Configuration and Updates

### Configuration

Config file: `~/.config/herdr/config.toml`

```bash
# Show default config
herdr --default-config

# Validate config and print diagnostics
herdr config check

# Reload config in running server
herdr server reload-config

# Reset custom keybindings (backups existing config)
herdr config reset-keys
```

### Updates

```bash
# Update herdr
herdr update

# Update with live handoff
herdr update --handoff

# Manage update channel
herdr channel show
herdr channel set stable
herdr channel set preview
```

### Shell Completions

```bash
# Generate completions for your shell
herdr completion bash
herdr completion zsh
herdr completion fish
herdr completion powershell
herdr completion elvish
```

### API Schema

```bash
# Print the bundled API schema
herdr api schema

# Print as JSON
herdr api schema --json

# Write to file (--json and --output are mutually exclusive)
herdr api schema --output /path/to/schema.json

# Get live runtime snapshot
herdr api snapshot
```
