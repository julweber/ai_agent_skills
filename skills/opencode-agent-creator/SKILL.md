---
name: agent-creator
description: Expert guide for creating, configuring, and managing Opencode Agents. Use this skill when the user wants to create a new agent or modify an existing one.
---

## Overview
This skill provides the knowledge and procedures to create Opencode Agents. Agents are defined using Markdown files with YAML frontmatter for configuration and the file body for the system prompt.

## Capabilities
- Create new Primary or Subagents.
- Configure agent permissions (tools, bash, tasks).
- Set model parameters (temperature, specific models).
- Save agent definitions to Project (`.opencode/agent/`) or Global (`~/.config/opencode/agent/`) scopes.

## Usage

### 1. Gather Requirements
If the user hasn't provided all details, ask for:
- **Scope**: Assume **Global** (`~/.config/opencode/agent/`) unless the user explicitly requests "Project" scope.
- **Name**: What should the agent be called? (e.g., `security-auditor`, `react-expert`)
- **Role/Goal**: What is the agent's primary purpose?
- **Mode**: `primary` (full interaction) or `subagent` (specialized task)?
- **Tools**: What tools should be enabled/disabled? (e.g., `bash: false`, `write: false`)

### 2. Construct the Agent File
Create a Markdown file (e.g., `agent-name.md`).

#### File Location
- **Global**: `~/.config/opencode/agent/<agent-name>.md` (Default)
- **Project**: `.opencode/agent/<agent-name>.md` (Only if requested)

#### File Format
The file MUST start with YAML frontmatter followed by the system prompt.

```markdown
---
description: <Short description for the UI/autocomplete>
mode: <primary|subagent>
model: <optional: specific-model-id>
temperature: <optional: 0.0-1.0>
hidden: <optional: true|false> (Only for subagents)
tools:
  <tool_name>: <true|false>
  # Examples:
  # bash: false
  # write: true
permission:
  <tool_name>: <allow|ask|deny>
  # bash permissions can be granular:
  # bash:
  #   "git status": allow
  #   "*": ask
---
<System Prompt Body>
You are the <Agent Name>. Your goal is...
Instructions:
- ...
- ...
```

### 3. Execution
1.  **Check Directory**: Ensure the target directory exists (`mkdir -p`).
2.  **Write File**: Use the `write` tool to save the file.
3.  **Confirm**: Inform the user the agent has been created and how to use it (e.g., "Switch using Tab" or "Invoke via @name").

## Configuration Reference

### Permissions
- **Tools**: `edit`, `bash`, `webfetch` can be set to `ask`, `allow`, or `deny`.
- **Task**: Control which subagents can be called.
  ```yaml
  permission:
    task:
      "*": deny
      "specific-agent": allow
  ```

### Models
Common overrides:
- Planning: Lower temperature (0.1)
- Creative: Higher temperature (0.7)
