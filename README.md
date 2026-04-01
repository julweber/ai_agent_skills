# AI Agent Skills and Agents Repository

This repository contains various skills, agents, extensions, and tools for AI agents, organized in a structured manner to support different capabilities and functionalities.
These are implemented to be used exclusively by AI agents like opencode, Claude Code, pi, and other compatible agents.

## Overview

The repository is organized into:

- **Skills Directory** (`skills/`): 29+ specialized agent skills for various domains (CLI tooling, file organization, system monitoring, documentation generation, infrastructure, testing, Obsidian vault management, AI agents)
- **Agents Directory** (`agents/`): Agent configuration templates and implementations (summarizer, web-researcher)
- **Extensions Directory** (`extensions/`): Custom tool extensions for AI agents (fetch-tool for Pi coding agent)
- **Ralph Loop Implementation** (`ralph/`): Autonomous development loop for `opencode` with PRD generation and JSON conversion

It also contains an implementation of the ralph loop for `opencode`. For more information on using the ralph loop see [ralph/README.md](ralph/README.md).

## Quick Start with an AI Agent

This repository ships an [Agent Skills](https://agentskills.io)-compatible skill that gives any compatible AI agent (Claude Code, pi, etc.) full context about the available automations, how to configure them, and how to run them.

Point your agent at the skill file:
```
skills/ai-agent-skills-assistant/SKILL.md
```

The agent will read the README and discover available scripts on its own, then guide you interactively.

## Installation

### Quick Start (Recommended)

#### Installing Skills

Use the provided installation script for an easy, guided experience:

```bash
# Interactive installation wizard (recommended for first-time users)
./install-skill.sh --interactive

# show all installation options
./install-skill.sh --help
```

#### Installing Extensions

For coding agent extensions:

```bash
# Interactive installation wizard (recommended)
./install-extension.sh --interactive

# show all installation options
./install-extension.sh --help
```

#### Installing Agents

For agent configurations:

```bash
# Interactive installation wizard (recommended)
./install-agent.sh --interactive

# show all installation options
./install-agent.sh --help
```

### Manual Installation

#### opencode

```bash
# Clone this repository
git clone https://github.com/julweber/ai_agent_skills
cd ai_agent_skills

# Link skills to opencode config directory
mkdir -p ~/.config/opencode/skills
ln -sf "$(pwd)/skills" ~/.config/opencode/skills
```

The linked skills will automatically be available to your opencode agent.

#### pi

```bash
# Clone this repository
git clone https://github.com/julweber/ai_agent_skills
cd ai_agent_skills

# Link skills to pi project directory
mkdir -p .pi/agent/skills
ln -sf "$(pwd)/skills" .pi/agent/skills

# Link extensions (optional)
mkdir -p .pi/agent/extensions
ln -sf "$(pwd)/extensions/pi/fetch-tool" .pi/agent/extensions/fetch-tool

# Link agents (optional)
mkdir -p .pi/agents
ln -sf "$(pwd)/agents/pi" .pi/agents/pi
```

The linked skills, extensions, and agents will automatically be available to your pi when working within this project.

#### claude

```bash
# Clone this repository
git clone https://github.com/julweber/ai_agent_skills
cd ai_agent_skills

# Link skills to Claude config directory
mkdir -p ~/.claude/skills
ln -sf "$(pwd)/skills" ~/.claude/skills
```

The linked skills will automatically be available to your Claude agent.

## Supported Agents

| Agent        | Target Directory             | Installation Type         |
|--------------|------------------------------|---------------------------|
| **opencode** | `~/.config/opencode/skills`  | Symlink (default) or Copy |
| **pi**       | `<project>/.pi/agent/skills` | Symlink (default) or Copy |
| **claude**   | `~/.claude/skills`           | Symlink (default) or Copy |
| **codex**    | Config-dependent             | Manual configuration      |

---

## Skills Directory Structure

```
.
├── README.md                       # This file
├── AGENTS.md                       # Agent development guidelines
├── .gitignore                      # Git ignore rules (opencode, claude configs)
├── ralph/                          # Ralph loop implementation for opencode
│   ├── README.md                   # Ralph loop setup and usage guide
│   └── opencode-ralph.sh           # Main script to start autonomous development loop
├── skills/                         # AI agent skill implementations (29+ skills)
│   ├── ai-agent-skills-assistant/  # Assistant skill for navigating the AI Agent Skills repository
│   ├── ansible/                    # Ansible automation reference with Proxmox/Docker integration
│   ├── brainstorming/              # Architectural ideation and innovation strategy
│   ├── claude-cli/                 # Expert Claude Code CLI control: sessions, MCP servers, plugins, authentication
│   ├── code-summarizer/            # Codebase summarization from local directories or GitHub/GitLab URLs
│   ├── codex-cli/                  # Codex CLI expert: exec, review, login/logout, MCP server management
│   ├── file-organizer/             # Intelligent file/folder organization tool
│   ├── frontend-web-developer/     # Full-stack web development: React, Next.js, Tailwind CSS
│   ├── github-cli/                 # GitHub CLI (gh) expert: PRs, issues, repos, workflows, releases
│   ├── gtd-assistant/              # GTD-style productivity assistant with open loop collection and brainstorming
│   ├── list-large-files/           # Lists top N largest files in directory tree
│   ├── list-most-intensive-processes/  # System process monitoring by resource usage
│   ├── llama-cpp/                  # llama.cpp tooling: llama-server, llama-cli, local LLM inference with GPU acceleration
│   ├── morning-ritual/             # Structured morning work ritual: pulls open tasks from Obsidian, highlights focus items
│   ├── nextcloud-cli/              # Nextcloud CLI sync tool (nextcloudcmd) for file synchronization management
│   ├── obsidian-master/            # Obsidian vault control via CLI (read/edit/search/links/tasks)
│   ├── obsidian-open-loops-collector/  # Collects open loops from Obsidian vault: tasks, TODOs, stub notes
│   ├── opencode-agent-creator/     # Create/configure Opencode agents (primary/subagents)
│   ├── opencode-cli/               # Expert opencode CLI control: TUI, server, web UI, sessions, providers, models
│   ├── pi-cli/                     # Pi coding agent CLI expert: launch sessions, manage extensions/packages, switch models
│   ├── product-prd-brainstorming/  # Generate PRDs with Mermaid system diagrams
│   ├── python-api-developer/       # Python API development guidance and best practices
│   ├── ralph-prd-converter/        # Convert markdown PRDs to Ralph's JSON format
│   ├── ralph-prd-generator/        # Generate detailed PRDs with user stories and criteria
│   ├── rest-testssuite/            # REST API testsuites organization and generation
│   ├── skill-creator/              # Guide for creating new AI agent skills
│   ├── terraform/                  # Terraform/OpenTofu guidance, testing, CI/CD, security
│   ├── tmux/                       # Remote tmux session control: send keystrokes, scrape pane output
│   └── trello-cli/                 # Trello CLI expert: manage boards/cards/lists programmatically via JSON
├── agents/                         # Agent configuration templates
│   └── pi/                         # Pi agent configurations
│       ├── summarizer.md           # Research summarization and synthesis agent
│       └── web-researcher.md       # Comprehensive web research and analysis agent
├── extensions/                     # Custom tool extensions for AI agents
│   └── pi/                         # Extensions specifically for the Pi coding agent
│       ├── fetch-tool/             # Hybrid URL fetching with content detection and rendering
│       │   ├── index.ts            # Main extension entry point with multi-method content handling
│       │   ├── utils/helpers.ts    # Utility functions for content type detection
│       │   └── README.md           # Detailed documentation for fetch-tool
├── install-agent.sh                # Agent installer for Pi coding agent configurations
├── install-extension.sh            # Extension installer for Pi coding agent extensions
├── install-skill.sh                # Skill installer for all supported agents
└── docs/                           # Research and review documents (untracked)
    ├── llama-bench-research.md     # LLM benchmark research findings
    ├── review-march-26-qwen35.md   # Qwen 3.5 model review and analysis
    └── typescript-fetch-research.md # TypeScript URL fetching implementation research
```

## Available Skills

### CLI Tool Expertise
| Skill | Description |
|-------|-------------|
| **claude-cli** | Expert Claude Code CLI control: sessions, MCP servers, plugins, authentication, and all commands/flags/options |
| **codex-cli** | Codex CLI expert: exec, review, login/logout, MCP server management, sandbox modes, and usage patterns |
| **github-cli** | GitHub CLI (gh) expert: PRs, issues, repositories, workflows, releases, and programmatic JSON operations |
| **opencode-cli** | Expert opencode CLI control: TUI, headless server, web UI, sessions, providers, agents, models, stats, import/export, debugging |
| **pi-cli** | Pi coding agent CLI expert: launch sessions, manage extensions/packages, switch models, configure tools, export sessions |
| **trello-cli** | Trello CLI power user: execute commands, parse JSON output, manage boards/cards/lists programmatically |
| **nextcloud-cli** | Nextcloud sync tool (nextcloudcmd) control for file synchronization with remote servers |
| **tmux** | Remote tmux session control: send keystrokes to interactive CLIs, scrape pane output |
| **llama-cpp** | llama.cpp expert: llama-server, llama-cli, local LLM inference with GPU acceleration, model loading from Hugging Face/Docker Hub |

### File & System Organization
| Skill | Description |
|-------|-------------|
| **file-organizer** | Intelligently organizes files and folders by understanding context, finding duplicates, suggesting better structures, and automating cleanup tasks |
| **list-large-files** | Lists the top N largest files in a given directory using Python traversal |
| **list-most-intensive-processes** | Lists the top N most intensive processes based on CPU time and memory usage |

### Web Development
| Skill | Description |
|-------|-------------|
| **frontend-web-developer** | Full-stack web development expertise: React patterns, Next.js conventions, Tailwind CSS v4, and modern frontend best practices with comprehensive reference materials |
| **python-api-developer** | Python API development guidance: REST APIs, FastAPI/Flask frameworks, authentication, testing, deployment patterns |

### Obsidian Knowledge Management
| Skill | Description |
|-------|-------------|
| **obsidian-master** | Complete Obsidian vault control via CLI: file operations (read/create/edit/move/delete), searches, links/backlinks analysis, properties/metadata management, task handling, history versions, and plugin/theme administration. Includes extensive reference documentation for all capabilities |
| **obsidian-open-loops-collector** | Collects open loops from Obsidian vault: tasks from 00-Tasks/, dangling thoughts (TODO/idea/later/?), stub notes (<10 lines) for GTD-style reflection |

### Product & PRD Management
| Skill | Description |
|-------|-------------|
| **product-prd-brainstorming** | Guides users through structured brainstorming to create complete Product Requirements Documents with Mermaid system architecture diagrams |
| **ralph-prd-generator** | Generates detailed PRDs with clarifying questions, user stories, and acceptance criteria |
| **ralph-prd-converter** | Converts markdown PRDs to Ralph's JSON format (`tasks/prd.json`) for autonomous execution |

### Skill & Agent Creation
| Skill | Description |
|-------|-------------|
| **skill-creator** | Guide for creating effective skills that extend agent capabilities with specialized knowledge and workflows |
| **opencode-agent-creator** | Expert guide for creating, configuring, and managing Opencode Agents (primary/subagents) |

### Infrastructure & Testing
| Skill | Description |
|-------|-------------|
| **terraform** | Terraform & OpenTofu guidance: modules, testing, CI/CD, security scanning (trivy/checkov), production patterns |
| **ansible** | Ansible automation reference for playbooks, roles, inventory, variables; includes Proxmox VE and Docker integration |
| **rest-testssuite** | Organizes REST API testsuites, generates CRUD test files |

### Strategic Development & Productivity
| Skill | Description |
|-------|-------------|
| **brainstorming** | Principal Engineer and Product Strategist: architectural ideas, feature extensions, refactoring strategies, innovation roadmaps |
| **code-summarizer** | Codebase summarization from local directories or GitHub/GitLab URLs: architecture, core concepts, key features, problems & solutions |
| **gtd-assistant** | GTD-style productivity assistant combining open loop collection with intelligent brainstorming for actionable next steps and priorities |
| **morning-ritual** | Structured morning work ritual: pulls open tasks from Obsidian, surfaces due items, highlights urgent tasks, identifies 1-3 MITs (Most Important Tasks) |

### Repository Assistant
| Skill | Description |
|-------|-------------|
| **ai-agent-skills-assistant** | Expert assistant for navigating the AI Agent Skills repository. Helps install skills/agents/extensions and provides guidance on available capabilities by gathering information from installed directories |

---

## Agent Implementations

The `agents/pi/` directory contains specialized agent configurations for the Pi coding agent:

### Research & Analysis Agents
| Agent              | Description                                                                                                                                                                              |
| --------------------| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **summarizer**     | Research summarization and synthesis agent that processes complex documents, identifies key insights, and creates concise summaries while maintaining context and actionable takeaways   |
| **web-researcher** | Comprehensive web research and analysis agent with systematic approach to information gathering, source verification, cross-referencing, and synthesizing findings from multiple sources |

## Coding Agent Extensions

#### Available Extensions
| Extension | Description |
|-----------|-------------|
| **fetch-tool** | Hybrid URL fetching extension with automatic content detection (JSON, HTML, RSS, binary), markdown rendering, and truncation for the Pi coding agent |

## Ralph Loop Integration

The repository includes the **ralph loop** - an autonomous development system for opencode:

1. Generate PRD using `/ralph-prd-generator`
2. Convert to JSON format using `/ralph-prd-converter`
3. Run autonomous loop with `./scripts/ralph/opencode-ralph.sh`

See [ralph/README.md](ralph/README.md) for setup and usage details.

## Testing

The `tests/` directory contains a self-contained bash test suite for the three install scripts. No external dependencies are required.

```bash
# Run all suites
bash tests/run_tests.sh

# Run a single suite
bash tests/run_tests.sh skill     # install-skill.sh
bash tests/run_tests.sh agent     # install-agent.sh
bash tests/run_tests.sh ext       # install-extension.sh

# Run two suites
bash tests/run_tests.sh agent ext
```

Each suite can also be executed directly:

```bash
bash tests/test_install_skill.sh
bash tests/test_install_agent.sh
bash tests/test_install_extension.sh
```

The runner exits with code `0` when all suites pass and `1` if any suite fails.

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature
3. Make your changes (ensure SKILL.md follows YAML frontmatter format)
4. Run `python3 -m py_compile scripts/*.py` to verify Python syntax if adding scripts
5. Submit a pull request with a clear description of your changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

# Interesting external skills
- [superpowers](https://github.com/obra/superpowers)
- [agent-skill-creator](https://github.com/FrancyJGLisboa/agent-skill-creator)
- [obsidian-skills](https://github.com/kepano/obsidian-skills)
