# AI Agent Skills and Agents Repository

This repository contains various skills and tools for AI agents, organized in a structured manner to support different capabilities and functionalities.
These skills are implemented to be used exclusively by AI agents like opencode, Claude code, Codex, ...

## Overview

The AI Agent Skills Repository is designed to house modular skill implementations that can be used to extend the capabilities of AI agents. Each skill represents a specific functionality or domain expertise that an agent can leverage.

## Installation

### opencode
- checkout the repo
- then symlink the skills sub-directory to the ~/.config/opencode/skills directory

```bash
ln -s THIS_REPO_ROOT/skills ~/.config/opencode/skills
```

## Links 

- Repository with skill implementations - https://github.com/skillcreatorai/Ai-Agent-Skills/tree/main/skills

## Directory Structure

```
.
├── README.md                 # This file
├── file-organizer            # Tool for organizing files and folders
├── list-large-files          # Tool for identifying large files in directories
├── list-most-intensive-processes  # Tool for monitoring system processes
├── skill-creator             # Tool for creating new skills
└── opencode-agent-creator    # Tool for creating AI agents
```

## Available Skills

### File Organization Tools
- **file-organizer**: Intelligently organizes files and folders by understanding context, finding duplicates, suggesting better structures, and automating cleanup tasks.

### System Monitoring Tools
- **list-large-files**: Lists the top N largest files in a given directory and its subdirectories.
- **list-most-intensive-processes**: Lists the top N most intensive processes running on the system based on CPU time and memory usage.

### Skill Development
- **skill-creator**: Guide for creating effective skills that extend agent capabilities with specialized knowledge, workflows, or tool integrations.

### Agent Creation
- **opencode-agent-creator**: Expert guide for creating, configuring, and managing Opencode Agents.

## Usage

Each directory contains specific tools and their respective documentation. To use a particular skill:

1. Navigate to the relevant directory
2. Follow the instructions provided in that directory's README or documentation
3. Integrate the skill into your AI agent as needed

## Contributing

Contributions are welcome! Please follow these steps:
1. Fork the repository
2. Create a new branch for your feature
3. Make your changes
4. Submit a pull request with a clear description of your changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.