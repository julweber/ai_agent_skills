---
name: claude-cli
description: Expert control of the `claude` CLI (Claude Code). Use when running Claude Code interactively or non-interactively, managing sessions, configuring MCP servers, managing plugins, handling authentication, or piping prompts through claude for scripting.
---

# Claude CLI

`claude` starts an interactive session by default. Use `-p/--print` for non-interactive/scripted usage.

## Key Runtime Flags

| Flag | Description |
|------|-------------|
| `-p, --print` | Non-interactive: print response and exit (pipe-friendly) |
| `-c, --continue` | Continue most recent conversation in current directory |
| `-r, --resume [id]` | Resume session by ID, or open interactive picker |
| `--fork-session` | Create new session ID when resuming (use with `-r`/`-c`) |
| `--model <model>` | Model alias (`sonnet`, `opus`) or full name (`claude-sonnet-4-6`) |
| `--effort <level>` | Effort level: `low`, `medium`, `high` |
| `--session-id <uuid>` | Use specific UUID for this conversation |
| `--system-prompt <prompt>` | Override system prompt |
| `--append-system-prompt <prompt>` | Append to default system prompt |
| `-w, --worktree [name]` | Create git worktree for this session |
| `--tmux` | Create tmux session for worktree (requires `--worktree`) |
| `--ide` | Auto-connect to IDE if exactly one is available |
| `--chrome` / `--no-chrome` | Enable/disable Chrome integration |

## Output & Format (with `--print`)

```bash
claude -p "prompt"                                    # text output
claude -p --output-format json "prompt"              # single JSON result
claude -p --output-format stream-json "prompt"       # streaming JSON
claude -p --input-format stream-json                 # streaming JSON input
claude -p --include-partial-messages "prompt"        # include partial chunks
claude -p --max-budget-usd 0.50 "prompt"            # cap spend
claude -p --fallback-model sonnet "prompt"           # fallback if overloaded
claude -p --no-session-persistence "prompt"          # don't save session
```

## Tool Control

```bash
--allowedTools "Bash(git:*) Edit Read"   # whitelist tools
--disallowedTools "Bash"                 # blacklist tools
--tools "Bash,Edit,Read"                 # exact set from built-ins
--tools ""                               # disable ALL tools
--permission-mode bypassPermissions      # skip all prompts
--dangerously-skip-permissions           # bypass all checks
--allow-dangerously-skip-permissions     # make bypass available as option
```

Permission modes: `acceptEdits`, `bypassPermissions`, `default`, `dontAsk`, `plan`

## MCP Configuration

```bash
--mcp-config server.json                 # load MCP servers from JSON file
--strict-mcp-config                      # only use --mcp-config servers
--mcp-debug                              # [DEPRECATED] use --debug instead
```

## Agents

```bash
--agent <name>                           # override agent for session
--agents '{"reviewer":{"description":"...","prompt":"..."}}'  # define inline agents
```

## Debug & Settings

```bash
-d, --debug [filter]                     # debug mode, optional category filter
--debug-file <path>                      # write debug logs to file
--verbose                                # verbose output
--setting-sources user,project,local    # which config sources to load
--settings <file-or-json>               # load additional settings
--disable-slash-commands                 # disable all skills
--plugin-dir <path>                      # load plugins from dir (session only)
--betas <betas...>                       # beta headers (API key users only)
--file file_id:relative_path             # download file resource at startup
--from-pr [number/url]                   # resume session linked to a PR
--add-dir <directories...>              # extra dirs for tool access
--json-schema <schema>                   # JSON schema for structured output
--replay-user-messages                   # re-emit user messages on stdout
```

## Subcommands

### `claude auth`
```bash
claude auth login [--email <email>] [--sso]   # sign in (SSO flag forces SSO flow)
claude auth logout                             # log out
claude auth status [--json|--text]             # show auth status
```

### `claude mcp` — MCP Server Management
```bash
# Add stdio server
claude mcp add my-server -- npx my-mcp-server
claude mcp add -e API_KEY=xxx my-server -- npx my-mcp-server

# Add HTTP server
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport http corridor https://app.corridor.dev/api/mcp \
  --header "Authorization: Bearer TOKEN"

# OAuth HTTP server
claude mcp add --transport http --client-id <id> --client-secret my-server <url>

# Scope: local (default), user, or project
claude mcp add -s project my-server -- my-command

# Other operations
claude mcp add-json my-server '{"command":"npx","args":["server"]}'
claude mcp add-from-claude-desktop [-s <scope>]  # import from Claude Desktop (Mac/WSL)
claude mcp list
claude mcp get <name>
claude mcp remove <name> [-s <scope>]
claude mcp reset-project-choices      # reset approved/rejected project MCP servers
claude mcp serve [-d] [--verbose]     # start Claude Code as an MCP server
```

### `claude plugin` — Plugin Management
```bash
claude plugin install <plugin>[@marketplace] [-s user|project|local]
claude plugin uninstall <plugin> [-s <scope>]
claude plugin list [--json] [--available]
claude plugin enable <plugin> [-s <scope>]
claude plugin disable [plugin] [-s <scope>] [-a]   # -a disables all
claude plugin update <plugin> [-s user|project|local|managed]
claude plugin validate <path>                       # validate plugin manifest

# Marketplace management
claude plugin marketplace add <url|path|github-repo>
claude plugin marketplace list [--json]
claude plugin marketplace remove <name>
claude plugin marketplace update [name]             # all if no name given
```

### `claude agents`
```bash
claude agents [--setting-sources <sources>]   # list configured agents
```

### System Commands
```bash
claude install [target] [--force]   # install native build (stable/latest/version)
claude update                       # check for updates and install
claude doctor                       # check auto-updater health
claude setup-token                  # set up long-lived auth token (requires subscription)
```

## Common Workflows

```bash
# Non-interactive one-shot
claude -p "Explain this file" < README.md

# Continue last session
claude -c

# Resume specific session
claude -r abc-123-uuid

# Fork a session (branch it)
claude -r abc-123-uuid --fork-session

# Use specific model
claude --model opus -p "Complex task"

# Add MCP server scoped to project
claude mcp add -s project github -- npx @modelcontextprotocol/server-github

# Pipe JSON output for scripting
claude -p --output-format json "list files" | jq '.result'

# Allow all tools, skip prompts (sandboxed CI use)
claude -p --dangerously-skip-permissions "run tests"

# Budget-capped automation
claude -p --max-budget-usd 1.00 --output-format json "analyze codebase"

# Stream output in real-time
claude -p --output-format stream-json --include-partial-messages "write code"
```

## Environment Variables

- `ANTHROPIC_API_KEY` — API key for authentication
- `MCP_CLIENT_SECRET` — OAuth client secret for MCP HTTP servers (alternative to `--client-secret` prompt)
