---
name: pi-subagents-master
description: Expert guide for creating, running, and managing pi subagent configurations and multi-agent pipelines. Provides templates, examples, and step-by-step instructions for defining agent specifications and workflows using the pi-subagents extension.
---

# Pi-SubAgents Master

Expert instructions for creating, running, and managing pi subagent configurations and multi-agent pipelines.

## When to Use This Skill

Activate when the user wants to:
- Create new agent definitions or chains
- Run subagents to perform tasks
- Design multi-step agent pipelines
- Edit existing agent configurations
- Execute parallel or sequential workflows

---

## Quick Start: Running a Subagent

The simplest way to run a subagent task:

```typescript
subagent({
  agent: "agent-name",
  task: "Your task description here"
})
```

### Single Agent Execution

```typescript
// Basic usage
subagent({
  agent: "scout",
  task: "Analyze the codebase for authentication patterns"
})

// With output file
subagent({
  agent: "scout",
  task: "Analyze auth patterns",
  output: "auth-analysis.md"
})

// With model override
subagent({
  agent: "scout",
  task: "Deep analysis of security",
  model: "anthropic/claude-sonnet-4",
  skill: "safe-bash"
})

// Forked context (branched session)
subagent({
  agent: "reviewer",
  task: "Review this diff",
  context: "fork"
})
```

### Parallel Execution (Multiple Agents at Once)

```typescript
subagent({
  tasks: [
    { agent: "scout", task: "Audit frontend code" },
    { agent: "scout", task: "Audit backend code" },
    { agent: "reviewer", task: "Check security patterns" }
  ]
})
```

### Chain Execution (Sequential Pipeline)

```typescript
subagent({
  chain: [
    { agent: "scout", task: "Gather context for {task}" },
    { agent: "planner", task: "Create plan based on {previous}" },
    { agent: "worker", task: "Implement based on {previous}" }
  ]
})
```

### Async/Background Execution

```typescript
// Non-blocking background execution
subagent({
  agent: "scout",
  task: "Full security audit",
  async: true,
  clarify: false
})

// Check status later
subagent_status({ id: "<runId>" })
```

---

## Agent Discovery

### Agent Locations (Priority: Highest to Lowest)

| Scope   | Path                                         | Notes |
|---------|----------------------------------------------|-------|
| Project | `.pi/agents/{name}.md` (searches up)         | Highest priority |
| User    | `~/.agents/{name}.md` or `~/.pi/agent/agents/{name}.md` | Medium |
| Builtin | `~/.pi/agent/extensions/subagent/agents/`    | Lowest (can be overridden) |

### List Available Agents

```typescript
subagent({ action: "list" })
subagent({ action: "list", agentScope: "project" })  // Project scope only
subagent({ action: "list", agentScope: "user" })     // User scope only
```

### Inspect an Agent

```typescript
subagent({ action: "get", agent: "scout" })
```

### Builtin Agents

The extension ships with these ready-to-use agents:
- **scout**: Fast codebase reconnaissance
- **planner**: Creates implementation plans
- **worker**: Executes tasks
- **reviewer**: Code review and analysis
- **context-builder**: Gathers context
- **researcher**: Web research (requires pi-web-access)
- **delegate**: General delegation

---

## Creating New Agents

### Method 1: Using Management Action (Recommended)

```typescript
subagent({
  action: "create",
  config: {
    name: "code-analyzer",
    description: "Analyzes code for patterns, bugs, and improvement opportunities",
    scope: "user",                    // or "project"
    systemPrompt: `You are a code analyst specialized in...
    
    Your role is to:
    1. Read and understand the code
    2. Identify patterns and anti-patterns
    3. Find potential bugs or issues
    4. Suggest improvements
    
    Be thorough but concise in your analysis.`,
    model: "anthropic/claude-sonnet-4",
    tools: "read, bash",
    skills: "safe-bash",
    thinking: "high"
  }
})
```

### Method 2: Create Agent File Directly

Create a file at `~/.agents/code-analyzer.md`:

```markdown
---
name: code-analyzer
description: Analyzes code for patterns, bugs, and improvements
tools: read, bash
model: anthropic/claude-sonnet-4
skill: safe-bash
thinking: high
---

You are a code analyst specialized in...

Your role is to:
1. Read and understand the code
2. Identify patterns and anti-patterns
3. Find potential bugs or issues
4. Suggest improvements

Be thorough but concise in your analysis.
```

### Agent Frontmatter Reference

```yaml
---
name: agent-name              # Required: unique identifier
description: What it does     # Required: clear description
tools: read, bash             # Optional: comma-separated tools
                               #   Use mcp:server/tool for MCP tools
extensions: /path/to/ext.ts   # Optional: absent=all, empty=none
model: provider/model         # Optional: override default model
thinking: high                # Optional: off, minimal, low, medium, high, xhigh
skill: skill-name             # Optional: skills to inject
output: results.md            # Optional: write results to file
defaultReads: context.md      # Optional: files to read before execution
defaultProgress: true         # Optional: enable progress.md tracking
maxSubagentDepth: 1           # Optional: limit nested subagents
---

Your system prompt goes here.
```

---

## Creating Agent Chains (Workflows)

### Method 1: Using Management Action (Recommended)

```typescript
subagent({
  action: "create",
  config: {
    name: "research-analyze-plan",
    description: "Research topic, analyze findings, create action plan",
    scope: "user",
    steps: [
      { agent: "researcher", task: "Research {task}" },
      { agent: "planner", task: "Analyze {previous} and create plan" },
      { agent: "worker", task: "Execute first step from {previous}" }
    ]
  }
})
```

### Method 2: Create Chain File Directly

Create a file at `~/.agents/research-analyze-plan.chain.md`:

```markdown
---
name: research-analyze-plan
description: Research topic, analyze findings, create action plan
---

## researcher
model: anthropic/claude-haiku-4-5

Research {task} thoroughly. Look for:
- Key concepts and definitions
- Best practices and common approaches
- Potential challenges and solutions

## planner
output: plan.md
progress: true

Based on the research ({previous}), create an actionable plan.
Format the plan with clear steps and priorities.

## worker
reads: plan.md

Execute the first step from the plan.
```

### Chain Variables

| Variable | Description |
|----------|-------------|
| `{task}` | Original task passed to the chain |
| `{previous}` | Output from the previous step |
| `{chain_dir}` | Path to chain artifacts directory |

### Chain Step Configuration

Each `## agent-name` section supports:

```markdown
## agent-name
output: output-file.md    # Write results to file
reads: input1.md,input2.md # Read files before executing
model: anthropic/claude-sonnet-4  # Override model
skills: skill1,skill2     # Add/override skills
progress: true            # Enable progress tracking
```

---

## Running Custom Workflows

### Running a Custom Chain by Name

```typescript
subagent({
  chainName: "research-analyze-plan",
  task: "How to implement authentication in React"
})
```

### Inline Custom Workflow

```typescript
subagent({
  chain: [
    { agent: "researcher", task: "Research {task}" },
    { agent: "planner", task: "Create plan based on {previous}" }
  ],
  task: "Implementing JWT auth in Node.js"
})
```

### Parallel Fan-Out with Aggregation

```typescript
subagent({
  chain: [
    { agent: "scout", task: "Gather context" },
    {
      parallel: [
        { agent: "worker", task: "Implement feature A from {previous}" },
        { agent: "worker", task: "Implement feature B from {previous}" },
        { agent: "worker", task: "Implement feature C from {previous}" }
      ],
      concurrency: 2,  // Run 2 at a time
      failFast: true   // Stop if any fails
    },
    { agent: "reviewer", task: "Review all changes" }
  ]
})
```

### Forked Context for Branch Analysis

```typescript
subagent({
  chain: [
    { agent: "scout", task: "Analyze main branch" },
    { agent: "scout", task: "Analyze feature branch" },
    { agent: "diff-analyzer", task: "Compare {previous}" }
  ],
  context: "fork"
})
```

---

## Managing Agents and Chains

### List All Agents and Chains

```typescript
subagent({ action: "list" })
```

### Get Agent/Chain Details

```typescript
subagent({ action: "get", agent: "scout" })
subagent({ action: "get", chainName: "research-pipeline" })
```

### Update an Agent

```typescript
subagent({
  action: "update",
  agent: "scout",
  config: {
    model: "anthropic/claude-sonnet-4",
    thinking: "high"
  }
})
```

### Update a Chain

```typescript
subagent({
  action: "update",
  chainName: "research-pipeline",
  config: {
    description: "Updated description",
    steps: [
      { agent: "researcher", task: "New task for researcher" },
      { agent: "planner", task: "Updated planner task" }
    ]
  }
})
```

### Delete an Agent or Chain

```typescript
subagent({ action: "delete", agent: "my-agent" })
subagent({ action: "delete", chainName: "my-chain" })
```

---

## Practical Examples

### Example 1: Code Review Pipeline

```typescript
// Run a code review workflow
subagent({
  chain: [
    { agent: "scout", task: "Scan codebase for {task}", output: "issues.md" },
    { agent: "reviewer", reads: ["issues.md"], task: "Review and prioritize issues from {previous}" },
    { agent: "worker", reads: ["issues.md"], task: "Fix the top 3 issues identified in {previous}" }
  ],
  task: "authentication module"
})
```

### Example 2: Parallel Security Audit

```typescript
// Run multiple security checks in parallel
subagent({
  tasks: [
    { agent: "scout", task: "Check for SQL injection vulnerabilities", output: "sql-audit.md" },
    { agent: "scout", task: "Check for XSS vulnerabilities", output: "xss-audit.md" },
    { agent: "scout", task: "Check for authentication issues", output: "auth-audit.md" },
    { agent: "scout", task: "Check for authorization issues", output: "authz-audit.md" }
  ]
})
```

### Example 3: Research and Document

```typescript
// Research a topic and create documentation
subagent({
  action: "create",
  config: {
    name: "research-doc",
    description: "Research a topic and create documentation",
    scope: "user",
    steps: [
      { agent: "researcher", task: "Research {task} comprehensively" },
      { agent: "worker", task: "Create documentation from {previous}", output: "docs.md" }
    ]
  }
})

// Run it
subagent({
  chainName: "research-doc",
  task: "microservices architecture patterns"
})
```

### Example 4: Background Long-Running Task

```typescript
// Start a long audit in background
subagent({
  agent: "scout",
  task: "Complete security audit of entire codebase",
  async: true,
  clarify: false
})

// Later check status
subagent_status({ id: "abc123" })
```

---

## Execution Modes Reference

### Mode Selection

| Mode | Trigger | Description |
|------|---------|-------------|
| **single** | `agent` + `task` | Run one agent with task |
| **parallel** | `tasks` array | Run multiple agents concurrently |
| **chain** | `chain` array | Sequential pipeline with {previous} |
| **chainName** | Name reference | Run saved chain definition |

### Key Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `agent` | string | Agent name to execute |
| `task` | string | Task description |
| `tasks` | array | Parallel task configurations |
| `chain` | array | Chain step configurations |
| `chainName` | string | Name of saved chain to run |
| `output` | string/false | Output file path |
| `model` | string | Model override |
| `skill` | string/array | Skills to inject |
| `context` | "fork"/"fresh" | Execution context mode |
| `async` | boolean | Background execution |
| `clarify` | boolean | Show TUI before execution |
| `share` | boolean | Share session via Gist |
| `sessionDir` | string | Custom session directory |
| `maxOutput` | object | `{bytes, lines}` limits |
| `artifacts` | boolean | Enable artifact capture |

---

## MCP Tools Integration

```yaml
# All tools from an MCP server
tools: read, bash, mcp:chrome-devtools

# Specific tools from an MCP server
tools: read, bash, mcp:github/search_repositories, mcp:github/get_file_contents
```

> **Note:** MCP integration requires [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) extension. Restart pi after first connection to cache tool metadata.

---

## Extension Sandboxing

```yaml
# Absent: all extensions load (default behavior)
extensions:

# Empty string: no extensions load
extensions:

# Explicit list: only these extensions
extensions: /abs/path/to/ext-a.ts, /path/to/ext-b.ts
```

---

## Best Practices

### 1. Keep Agent Prompts Focused
Include only context the agent doesn't already have.

### 2. Use Output Files for Chain Steps
Enable {previous} chaining by writing outputs:
```typescript
{ agent: "scout", output: "context.md" }
{ agent: "planner", reads: ["context.md"] }
```

### 3. Design Reusable Chains
Identify common patterns and extract them into `.chain.md` files.

### 4. Use Thinking Levels Appropriately
```yaml
thinking: low    # Quick analysis
thinking: high   # Deep exploration
thinking: xhigh  # Maximum deliberation
```

### 5. Leverage Parallel Execution
Use `tasks` for independent work:
```typescript
tasks: [
  { agent: "scout", task: "Audit frontend" },
  { agent: "scout", task: "Audit backend" }
]
```

### 6. Use Async for Long Tasks
```typescript
{ agent: "scout", task: "Full audit", async: true, clarify: false }
```

---

## Troubleshooting

### Agent Not Found
- Check agent name matches exactly (case-sensitive)
- Verify file is in correct location
- Confirm YAML frontmatter has `name` field
- Restart pi if newly created agent doesn't appear

### Chain Execution Issues
- First step must have explicit task (no {previous} reference)
- Use `clarify: false` to skip TUI confirmation
- Check chain artifacts at `<tmpdir>/pi-chain-runs/`

### Output File Not Written
- Verify `output` field is set (not `false`)
- For chains, ensure step has explicit `output:` config
- Check `{sessionDir}/subagent-artifacts/` for debug files

---

## Quick Reference

**Run Single Agent:**
```typescript
subagent({ agent: "scout", task: "Your task" })
```

**Run Parallel Tasks:**
```typescript
subagent({ tasks: [{ agent: "a", task: "t1" }, { agent: "b", task: "t2" }] })
```

**Run Chain:**
```typescript
subagent({ chain: [{ agent: "a", task: "t1" }, { agent: "b" }] })
```

**Create Agent:**
```typescript
subagent({ action: "create", config: { name: "...", description: "...", scope: "user", systemPrompt: "..." } })
```

**Create Chain:**
```typescript
subagent({ action: "create", config: { name: "...", description: "...", scope: "user", steps: [{ agent: "a", task: "t1" }] } })
```

**List Agents:**
```typescript
subagent({ action: "list" })
```

**Get Agent Details:**
```typescript
subagent({ action: "get", agent: "agent-name" })
```

**Update Agent:**
```typescript
subagent({ action: "update", agent: "agent-name", config: { model: "new-model" } })
```

**Delete Agent:**
```typescript
subagent({ action: "delete", agent: "agent-name" })
```