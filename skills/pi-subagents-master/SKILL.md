---
name: pi-subagents-master
description: Expert guide for creating, editing, and improving pi agents and agent chains. Covers agent frontmatter, chain files, execution modes, management actions, and best practices from the pi-subagents extension.
---

# Pi-SubAgents Master

Specialized instructions for designing, implementing, and optimizing pi subagent configurations and multi-agent pipelines.

## When to Use This Skill

Activate when:
- Creating new agent definitions or chains
- Editing existing agent frontmatter or system prompts
- Designing multi-step agent pipelines
- Troubleshooting agent execution issues
- Optimizing agent performance and extension access

---

## Agent Definition Format

### Agent file locations

| Scope   | Path                                                | Priority |
| ---------| -----------------------------------------------------| ----------|
| Builtin | `~/.pi/agent/extensions/subagent/agents/`           | Lowest   |
| User    | `~/.pi/agent/agents/{name}.md`                      | Medium   |
| Project | `.pi/agents/{name}.md` (searches up directory tree) | Highest  |

### Basic Structure

```markdown
---
name: agent-name
description: Clear description of what this agent does
tools: read, bash, mcp:server-name  # Optional
extensions: /path/to/ext.ts         # Optional (absent=all, empty=none)
model: claude-sonnet-4              # Optional
thinking: high                      # off, minimal, low, medium, high, xhigh
skill: safe-bash, planning          # Comma-separated skills to inject
output: context.md                  # Write results to file (relative or false)
defaultReads: context.md            # Files to read before execution
defaultProgress: true               # Enable progress tracking
interactive: true                   # For TUI clarification
---

Your system prompt goes here (markdown body after frontmatter).
```

### Frontmatter Fields Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Agent identifier (lowercase-hyphenated) |
| `description` | string | required | Clear usage description |
| `tools` | string | all builtins | Comma-separated tool list, supports `mcp:` prefix |
| `extensions` | absent/empty/csv | absent=all | Control extension sandboxing |
| `model` | string | agent default | Override model (supports thinking suffix) |
| `thinking` | enum | none | Extended thinking level (appended as `:level`) |
| `skill` | string | none | Skills to inject into system prompt |
| `output` | string/false | none | Write results to file |
| `defaultReads` | string | none | Comma-separated files to read before execution |
| `defaultProgress` | boolean | false | Enable progress.md tracking |

### Extension Sandboxing

```yaml
# Absent: all extensions load (default)
extensions:

# Empty: no extensions
extensions:

# Allowlist specific extensions
extensions: /abs/path/to/ext-a.ts, /path/to/ext-b.ts
```

**MCP Tools Integration:**
```yaml
# All tools from a server
tools: read, bash, mcp:chrome-devtools

# Specific tools from a server  
tools: read, bash, mcp:github/search_repositories, mcp:github/get_file_contents
```

> **Note:** MCP integration requires [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) extension. First-run may need restart for tool discovery.

---

## Chain Definition Format

Chains define reusable multi-step pipelines in `.chain.md` files:

```markdown
---
name: scout-planner-pipeline
description: Gather context then plan implementation
scope: project  # user or project
---

## scout
output: context.md
model: claude-haiku-4-5

Analyze the codebase for {task} and extract relevant patterns.

## planner
reads: context.md
progress: true

Create an implementation plan based on {previous}. Prioritize tasks and identify dependencies.
```


### Chain file locations

| Scope   | Path                                 |
| ---------| --------------------------------------|
| User    | `~/.pi/agent/agents/{name}.chain.md` |
| Project | `.pi/agents/{name}.chain.md`         |

### Chain Step Configuration

Each `## agent-name` section supports these config lines immediately after the header:

| Config | Description |
|--------|-------------|
| `output: file.md` | Write step results to file |
| `output: false` | Disable file output, text-only |
| `reads: file1.md+file2.md` | Read files before executing (use `+` as separator) |
| `model: provider/name` | Override model for this step |
| `skills: skill1+skill2` | Override skills for this step |
| `progress: true/false` | Enable/disable progress tracking |

### Chain Variables

| Variable      | Description                                             |
| ---------------| ---------------------------------------------------------|
| `{task}`      | Original task from first step                           |
| `{previous}`  | Output from prior step (or aggregated parallel outputs) |
| `{chain_dir}` | Path to chain artifacts directory                       |

---

## Execution Modes

### Single Agent Mode

```typescript
// Basic execution
{ agent: "scout", task: "Analyze the codebase" }

// With overrides
{ agent: "scout", 
  task: "Find security issues",
  output: "scan.md",
  model: "anthropic/claude-sonnet-4",
  skill: "safe-bash" }

// Forked context (branched session from parent's current leaf)
{ agent: "reviewer", task: "Review this diff", context: "fork" }
```

### Chain Mode

```typescript
// Sequential pipeline
{ chain: [
  { agent: "scout", task: "Gather context for auth refactor" },
  { agent: "planner" },  // task defaults to {previous}
  { agent: "worker", progress: true }
]}

// Chain with inline overrides
{ chain: [
  { agent: "scout", output: "context.md", task: "Scan for auth patterns" },
  { agent: "planner", reads: ["context.md"], model: "claude-sonnet-4:high" }
]}

// Chain with parallel step (fan-out/fan-in)
{ chain: [
  { agent: "scout", task: "Gather context" },
  { parallel: [
    { agent: "worker", task: "Implement feature A based on {previous}" },
    { agent: "worker", task: "Implement feature B based on {previous}" }
  ], concurrency: 2, failFast: true },
  { agent: "reviewer", task: "Review all changes from {previous}" }
]}

// Async chain execution
{ chain: [...], clarify: false, async: true }
```

### Parallel Mode

```typescript
{ tasks: [
  { agent: "scout", task: "Audit frontend" },
  { agent: "reviewer", task: "Audit backend" }
]}

// With forked context (each task gets isolated branched session)
{ tasks: [...], context: "fork" }
```

---

## Management Actions

The LLM can discover, inspect, create, update, and delete agent/chain definitions:

### List All Agents and Chains

```typescript
{ action: "list" }              // Both scopes (default)
{ action: "list", agentScope: "project" }  // Project scope only
{ action: "list", agentScope: "user" }     // User scope only
```

### Inspect Agent or Chain

```typescript
{ action: "get", agent: "scout" }
{ action: "get", chainName: "review-pipeline" }
```

### Create New Agent

```typescript
{ action: "create", config: {
  name: "Code Scout",
  description: "Scans codebases for patterns and issues",
  scope: "user",                // user or project
  systemPrompt: "You are a code scout...",
  model: "anthropic/claude-sonnet-4",
  tools: "read, bash, mcp:github/search_repositories",
  extensions: "",               // empty = no extensions
  skills: "safe-bash",
  thinking: "high",
  output: "context.md",
  defaultReads: "shared-context.md",
  defaultProgress: true
}}
```

### Update Existing Agent/Chain

```typescript
// Update agent fields (merge semantics)
{ action: "update", agent: "scout", config: { 
  model: "openai/gpt-4o" 
}}

// Clear optional fields
{ action: "update", agent: "scout", config: { 
  output: false, 
  skills: "" 
}}

// Update chain steps
{ action: "update", chainName: "review-pipeline", config: {
  steps: [
    { agent: "scout", task: "Scan {task}", output: "context.md" },
    { agent: "reviewer", task: "Improved review of {previous}", reads: ["context.md"] }
  ]
}}
```

### Delete Definitions

```typescript
{ action: "delete", agent: "scout" }
{ action: "delete", chainName: "review-pipeline" }
```

---

## Builtin Agents

The extension ships with ready-to-use agents:
- **scout**: Fast codebase reconnaissance
- **planner**: Creates implementation plans
- **worker**: Executes tasks
- **reviewer**: Code review and analysis  
- **context-builder**: Gathers context
- **researcher**: Web research (requires pi-web-access)
- **delegate**: General delegation

Builtin agents have `[builtin]` badge and can be overridden by creating user/project agents with same name.

---

## Best Practices

### 1. Keep Agent Prompts Concise

Only add context Claude doesn't already have. Challenge each piece: *"Does the agent really need this?"*

### 2. Use Progressive Disclosure

Keep SKILL.md under 500 lines. Split large content into referenced files:

```markdown
# PDF Processing

## Quick start
[code example]

## Advanced features  
- **Form filling**: See [FORMS.md](FORMS.md)
- **API reference**: See [REFERENCE.md](REFERENCE.md)
```

### 3. Design for Reusability

Chain files allow defining reusable pipelines:
- Identify repetitive agent sequences
- Extract common patterns into `.chain.md` files
- Use `{task}`, `{previous}`, `{chain_dir}` variables effectively

### 4. Leverage Extension Sandboxing

Control extension access per agent:
```yaml
# Restrict to specific extensions
extensions: /abs/path/to/ext-a.ts, /path/to/ext-b.ts

# Disable all extensions for lean execution
extensions:
```

### 5. Use Thinking Levels Appropriately

The `thinking` field sets extended thinking level (appended as `:level` suffix):
- **low**: Quick analysis
- **medium**: Balanced reasoning  
- **high**: Deep exploration
- **xhigh**: Maximum deliberation

### 6. Optimize Output Strategy

```typescript
// Agent writes to file for later reference
{ agent: "scout", output: "context.md" }

// Text-only for quick iteration
{ agent: "scout", output: false }

// Chain step passes output to next step
{ chain: [
  { agent: "scout", output: "scan.md" },
  { agent: "reviewer", reads: ["scan.md"] }
]}
```

### 7. Background Execution for Long Tasks

```typescript
// Async execution (non-blocking)
{ agent: "scout", task: "Full security audit", clarify: false, async: true }

// Check status later
subagent_status({ id: "<runId>" })
```

---

## Common Patterns

### Pattern 1: Scout-Plan-Implement Pipeline

```typescript
{ chain: [
  { agent: "scout", task: "Analyze codebase for {task}", output: "context.md" },
  { agent: "planner", reads: ["context.md"], progress: true },
  { agent: "worker", reads: ["context.md", "plan.md"] }
]}
```

### Pattern 2: Parallel Audit with Review

```typescript
{ chain: [
  { agent: "scout", task: "Gather context" },
  { parallel: [
    { agent: "scout", task: "Audit frontend from {previous}" },
    { agent: "scout", task: "Audit backend from {previous}" }
  ]},
  { agent: "reviewer", reads: ["context.md"], task: "Review all findings" }
]}
```

### Pattern 3: Forked Context for Branch Analysis

```typescript
{ chain: [
  { agent: "scout", task: "Analyze current branch changes" },
  { agent: "planner", task: "Plan next steps from {previous}" }
], context: "fork"}
```

---

## Troubleshooting

### MCP Tools Not Available on First Run

**Symptom:** `mcp:` tools fail or return empty results

**Solution:** Restart pi after first connection to cache tool metadata. After restart, direct tools become available.

### Agent Discovery Fails

**Symptom:** "Agent not found" error

**Checklist:**
- Verify agent name matches exactly (case-sensitive)
- Confirm file is in correct location (`~/.pi/agent/agents/` or `.pi/agents/`)
- Check YAML frontmatter has `name` field defined
- Restart pi if newly created agent doesn't appear

### Chain Execution Hangs

**Symptom:** Foreground execution waits indefinitely

**Solution:** 
- Add `clarify: false, async: true` for background execution
- Use `--bg` flag with slash commands
- Check for infinite loops in `{previous}` chain logic

### Output File Not Written

**Symptom:** Expected output file doesn't exist

**Checklist:**
- Verify `output` field is set (not `false`)
- Check relative vs absolute path behavior
- For chains, ensure step has explicit `output:` config
- Look in `{sessionDir}/subagent-artifacts/` for debug artifacts

---

## Slash Commands Reference

| Command | Description |
|---------|-------------|
| `/run <agent> <task>` | Run single agent with task |
| `/chain agent1 "t1" -> agent2 "t2"` | Sequential chain with per-step tasks |
| `/parallel agent1 "t1" -> agent2 "t2"` | Parallel execution with per-step tasks |
| `/agents` | Open Agents Manager TUI (Ctrl+Shift+A) |

**Inline Config Overrides:**
```
/run scout[model=claude-sonnet-4] "analyze this"
/chain scout[output=context.md] "scan" -> planner[reads=context.md] "plan"
```

---

## Artifacts and Observability

### Debug Artifacts Location
`{sessionDir}/subagent-artifacts/` or `<tmpdir>/pi-subagent-artifacts/`

Per-task files:
- `{runId}_{agent}_input.md` - Task prompt
- `{runId}_{agent}_output.md` - Full output (untruncated)  
- `{runId}_{agent}.jsonl` - Event stream (sync only)
- `{runId}_{agent}_meta.json` - Timing, usage, exit code

### Chain Artifacts
`<tmpdir>/pi-chain-runs/{runId}/` containing:
- `context.md`, `plan.md`, `progress.md` as written by agents
- `parallel-{stepIndex}/` subdirectories for parallel outputs
- Auto-cleaned after 24 hours

---

## Session Management

### Session Logs
JSONL session files stored under per-run directory. Path shown in output.

When `context: "fork"` is used, each child run starts with a real branched session from parent's current leaf (not injected summary text).

### Session Sharing
```typescript
{ agent: "scout", task: "...", share: true }
```
Exports full session to HTML and uploads to GitHub Gist. Returns shareable URL.

**Requirements:** `gh` CLI installed and authenticated (`gh auth login`).

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `index.ts` | Main extension, tool registration |
| `agents.ts` | Agent + chain discovery, frontmatter parsing |
| `skills.ts` | Skill resolution and caching |
| `settings.ts` | Chain behavior resolution, templates |
| `chain-clarify.ts` | TUI for preview/editing before execution |
| `chain-execution.ts` | Sequential + parallel orchestration |
| `async-execution.ts` | Background execution support |
| `agent-manager.ts` | Overlay orchestrator and CRUD operations |

---

## Quick Reference Card

**Agent Frontmatter Keys:** name, description, tools, extensions, model, thinking, skill, output, defaultReads, defaultProgress

**Chain Variables:** `{task}`, `{previous}`, `{chain_dir}`

**Execution Context Modes:** `fresh` (default, clean session), `fork` (branched from parent's current leaf)

**Thinking Levels:** off, minimal, low, medium, high, xhigh

**Management Actions:** list, get, create, update, delete

**Background Execution:** Add `clarify: false, async: true` or use `--bg` flag