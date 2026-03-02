# AI Agent Skills and Agents Repository

This repository contains various skills and tools for AI agents, organized in a structured manner to support different capabilities and functionalities.
These skills are implemented to be used exclusively by AI agents like opencode, Claude Code, pi, and other compatible agents.

## Overview

The repository is organized into:

- **Skills Directory** (`skills/`): 12+ specialized agent skills for various domains (file organization, system monitoring, documentation generation, infrastructure, testing)
- **Ralph Loop Implementation** (`ralph/`): Autonomous development loop for `opencode`
- **Agents Directory** (`agents/`): Agent configuration templates (currently empty)

It also contains an implementation of the ralph loop for `opencode`. For more information on using the ralph loop see [ralph/README.md](ralph/README.md).

## Installation

### Quick Start (Recommended)

Use the provided installation script for an easy, guided experience:

```bash
# Interactive installation wizard (recommended for first-time users)
./install-skill.sh --interactive

# Or install all skills for a specific agent
./install-skill.sh --agent opencode --all
./install-skill.sh --agent pi --all
./install-skill.sh --agent claude --all
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
```

The linked skills will automatically be available to your pi when working within this project. The skills are accessible at `<project_root>/.pi/agent/skills`.

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

### Installation Script Reference

The `install-skill.sh` script provides multiple ways to install skills:

#### Basic Usage

```bash
# Show help and usage information
./install-skill.sh --help

# List all available skills without installing
./install-skill.sh --list

# Interactive installation wizard (recommended)
./install-skill.sh --interactive
```

#### Installing Specific Skills

```bash
# Install specific skill(s) for an agent
./install-skill.sh --agent opencode --skill file-organizer
./install-skill.sh --agent pi --skill list-large-files list-most-intensive-processes

# Install multiple skills at once
./install-skill.sh --agent claude --skill terraform ansible brainstorming
```

#### Installation Modes

```bash
# Install all available skills (default)
./install-skill.sh --agent opencode --all

# Use file copy instead of symlinks (for isolated environments or ralph loop)
./install-skill.sh --agent opencode --all --copy

# Skip confirmation prompts (useful for automation)
./install-skill.sh --agent pi --skill terraform --force

# Preview installation without executing
./install-skill.sh --agent opencode --skill file-organizer --dry-run
```

#### Checking Installation Status

```bash
# Show which skills are currently installed for an agent
./install-skill.sh --status --agent opencode
./install-skill.sh --status --agent pi
```

#### Supported Agents

| Agent        | Target Directory             | Installation Type         |
| --------------| ------------------------------| ---------------------------|
| **opencode** | `~/.config/opencode/skills`  | Symlink (default) or Copy |
| **pi**       | `<project>/.pi/agent/skills` | Symlink (default) or Copy |
| **claude**   | `~/.claude/skills`           | Symlink (default) or Copy |

#### Installation Types

- **Symlink (recommended for development)**: Creates symbolic links to the skills repository. Updates are automatically reflected when you update the repository.
- **Copy installation**: Copies skill files to the target directory. Useful for isolated environments, ralph loop, or when you want to preserve a specific version of skills.

## Skills Directory Structure

```
.
├── README.md                 # This file
├── AGENTS.md                 # Agent development guidelines
├── .gitignore                # Git ignore rules (opencode, claude configs)
├── ralph/                    # Ralph loop implementation for opencode
│   ├── README.md             # Ralph loop setup and usage guide
│   └── opencode-ralph.sh     # Main script to start autonomous development loop
├── skills/                   # AI agent skill implementations (12+ skills)
│   ├── ansible/              # Ansible automation reference with Proxmox/Docker integration
│   ├── brainstorming/        # Architectural ideation and innovation strategy
│   ├── file-organizer/       # Intelligent file/folder organization tool
│   ├── list-large-files/     # Lists top N largest files in directory tree
│   ├── list-most-intensive-processes/  # System process monitoring by resource usage
│   ├── opencode-agent-creator/  # Create/configure Opencode agents (primary/subagents)
│   ├── product-prd-brainstorming/  # Generate PRDs with Mermaid system diagrams
│   ├── ralph-prd-converter/  # Convert markdown PRDs to Ralph's JSON format
│   ├── ralph-prd-generator/  # Generate detailed PRDs with user stories and criteria
│   ├── rest-testssuite/      # REST API testsuites organization and generation
│   ├── skill-creator/        # Guide for creating new AI agent skills
│   └── terraform/            # Terraform/OpenTofu guidance, testing, CI/CD, security
└── AGENTS.md                 # Agent development guidelines
```

## Available Skills

### File & System Organization
| Skill | Description |
|-------|-------------|
| **file-organizer** | Intelligently organizes files and folders by understanding context, finding duplicates, suggesting better structures, and automating cleanup tasks |

### System Monitoring
| Skill | Description |
|-------|-------------|
| **list-large-files** | Lists the top N largest files in a given directory using Python traversal |
| **list-most-intensive-processes** | Lists the top N most intensive processes based on CPU time and memory usage |

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

### Strategic Development
| Skill | Description |
|-------|-------------|
| **brainstorming** | Principal Engineer and Product Strategist: architectural ideas, feature extensions, refactoring strategies, innovation roadmaps |

## Usage

Each skill is a directory containing `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: Clear description of what this skill does
---
```

To use a skill:
1. Ensure the skills directory is linked to your agent's config (see Installation)
2. The skill activates automatically when its domain is relevant
3. Follow instructions in each `SKILL.md` file for specific usage patterns

## Ralph Loop Integration

The repository includes the **ralph loop** - an autonomous development system for opencode:

1. Generate PRD using `/ralph-prd-generator`
2. Convert to JSON format using `/ralph-prd-converter`
3. Run autonomous loop with `./scripts/ralph/opencode-ralph.sh`

See [ralph/README.md](ralph/README.md) for setup and usage details.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a new branch for your feature
3. Make your changes (ensure SKILL.md follows YAML frontmatter format)
4. Run `python3 -m py_compile scripts/*.py` to verify Python syntax if adding scripts
5. Submit a pull request with a clear description of your changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.
