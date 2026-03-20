---
name: opencode-cli
description: Expert control of opencode via the command line. Use when running opencode TUI, headless server, web UI, or the `run` non-interactive mode; managing sessions, providers, agents, MCP servers, models, stats, import/export, GitHub integration, debugging, database tools, upgrades, or shell completions.
---

# opencode CLI

`opencode` is an AI coding agent. This skill covers every CLI command and flag.

## Global Options (apply to every command)

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--print-logs` | bool | false | Print logs to stderr |
| `--log-level` | string | — | DEBUG / INFO / WARN / ERROR |
| `--port` | number | 0 (random) | Port to listen on |
| `--hostname` | string | `127.0.0.1` | Hostname to listen on |
| `--mdns` | bool | false | Enable mDNS (sets hostname → 0.0.0.0) |
| `--mdns-domain` | string | `opencode.local` | Custom mDNS domain |
| `--cors` | array | `[]` | Extra CORS domains |
| `-m, --model` | string | — | `provider/model` |
| `-c, --continue` | bool | — | Continue last session |
| `-s, --session` | string | — | Session ID to continue |
| `--fork` | bool | — | Fork session (with `-c`/`-s`) |
| `--prompt` | string | — | Prompt to use |
| `--agent` | string | — | Agent to use |

---

## Commands

### TUI / Default
```bash
opencode [project]          # start TUI in current or given directory
```

### `run` — Non-interactive execution
```bash
opencode run [message..] [flags]
```
| Flag | Default | Notes |
|------|---------|-------|
| `--command` | — | Command to run (message = args) |
| `--share` | false | Share the session |
| `--format` | `default` | `default` or `json` (raw events) |
| `-f, --file` | — | Attach file(s) |
| `--title` | — | Session title |
| `--attach` | — | Attach to running server (URL) |
| `-p, --password` | — | Basic auth password (`OPENCODE_SERVER_PASSWORD`) |
| `--dir` | — | Directory (local or remote) |
| `--port` | random | Local server port |
| `--variant` | — | Model reasoning effort: high/max/minimal |
| `--thinking` | false | Show thinking blocks |

### `serve` — Headless server
```bash
opencode serve [server-flags]
# Server flags: --port, --hostname, --mdns, --mdns-domain, --cors
```

### `web` — Server + browser UI
```bash
opencode web [server-flags]
```

### `attach` — Attach to running server
```bash
opencode attach <url>           # e.g. http://localhost:4096
  --dir        # directory on remote
  -c/--continue / -s/--session / --fork
  -p, --password
```

### `acp` — ACP server
```bash
opencode acp [server-flags]
  --cwd        # working directory (default: cwd)
```

---

## Session Management

```bash
opencode session list [-n <N>] [--format table|json]
opencode session delete <sessionID>
opencode export [sessionID]               # → stdout JSON
opencode import <file|url>                # import JSON
```

---

## Providers / Auth

```bash
opencode providers list                   # (alias: auth list)
opencode providers login [url] [-p <id>] [-m <method>]
opencode providers logout
```

---

## Models

```bash
opencode models [provider]
  --verbose    # include cost metadata
  --refresh    # refresh cache from models.dev
```

---

## Agents

```bash
opencode agent list
opencode agent create \
  [--path <dir>] \
  [--description "..."] \
  [--mode all|primary|subagent] \
  [--tools "bash,read,write,edit,list,glob,grep,webfetch,task,todowrite,todoread"] \
  [-m provider/model]
opencode debug agent <name> [--tool <id>] [--params <json>]
```

---

## MCP Servers

```bash
opencode mcp list                         # list + status
opencode mcp add                          # interactive add
opencode mcp auth [name]                  # OAuth authenticate
opencode mcp auth list                    # list OAuth status
opencode mcp logout [name]                # remove OAuth credentials
opencode mcp debug <name>                 # debug OAuth connection
```

---

## Stats

```bash
opencode stats
  --days <N>       # last N days (default: all time)
  --tools <N>      # top N tools
  --models [N]     # model stats (show all, or top N)
  --project <str>  # filter by project (empty string = current)
```

---

## GitHub Integration

```bash
opencode github install
opencode github run [--event <mock-event>] [--token <github_pat_...>]
opencode pr <number>          # checkout PR branch then launch opencode
```

---

## Database Tools

```bash
opencode db [query]           # sqlite3 shell or run query [--format json|tsv (default: tsv)]
opencode db path              # print db path
opencode db migrate           # migrate JSON → SQLite
```

---

## Debug / Diagnostics

```bash
opencode debug config                            # show resolved config
opencode debug paths                             # data/config/cache/state dirs
opencode debug scrap                             # list all known projects
opencode debug skill                             # list available skills
opencode debug agent <name>                      # agent config details

# LSP
opencode debug lsp diagnostics <file>
opencode debug lsp symbols <query>
opencode debug lsp document-symbols <uri>

# Ripgrep
opencode debug rg tree
opencode debug rg files
opencode debug rg search <pattern>

# Filesystem
opencode debug file read <path>
opencode debug file status
opencode debug file list <path>
opencode debug file search <query>
opencode debug file tree [dir]

# Snapshots
opencode debug snapshot track
opencode debug snapshot patch <hash>
opencode debug snapshot diff <hash>
```

---

## Lifecycle

```bash
opencode upgrade [target]           # e.g. 0.1.48 or v0.1.48
  -m, --method  curl|npm|pnpm|bun|brew|choco|scoop

opencode uninstall
  -c, --keep-config   # keep config files (default: false)
  -d, --keep-data     # keep sessions/snapshots (default: false)
      --dry-run       # preview only (default: false)
  -f, --force         # skip confirmations (default: false)
```

---

## Shell Completion

```bash
opencode completion >> ~/.bashrc    # bash
opencode completion >> ~/.bash_profile  # macOS
```

---

## Common Workflows

**Run a one-shot task non-interactively:**
```bash
opencode run "fix the failing tests" -m anthropic/claude-opus-4-5
```

**Continue last session non-interactively:**
```bash
opencode run "add docs" --continue
```

**Start a headless server on a fixed port:**
```bash
opencode serve --port 4096
```

**Attach a TUI client to a remote server:**
```bash
opencode attach http://192.168.1.10:4096 -p mypassword
```

**Export/import sessions:**
```bash
opencode export > backup.json
opencode import backup.json
```

**List sessions, delete one:**
```bash
opencode session list -n 10 --format json
opencode session delete <sessionID>
```

**Add a provider and list models:**
```bash
opencode providers login -p anthropic
opencode models anthropic --verbose
```

**Create a custom subagent:**
```bash
opencode agent create --description "security reviewer" --mode subagent --tools "read,grep,glob"
```

**Check cost stats for this week:**
```bash
opencode stats --days 7 --models 5
```
