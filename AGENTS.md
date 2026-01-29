# AI Agent Development Guidelines

## Build/Lint/Test Commands

This repository contains various AI agent skills that are primarily markdown-based with supporting scripts. 

### General Commands
- **Run all tests**: `npm test` (if applicable)
- **Run single test**: `npm run test -- --testNamePattern="test-name"` or similar pattern based on testing framework
- **Lint code**: `npm run lint`
- **Format code**: `npm run format`

### For this specific repository structure:
Since the repository primarily contains skill definitions in markdown files and supporting Python scripts, there are no traditional build processes. 

However, for running individual skills:
- Use `bash` command to execute Python scripts directly: 
  - For list-large-files: `python3 /list-large-files/scripts/list_files.py <path> <count>`
  - For list-most-intensive-processes: `python3 /list-most-intensive-processes/scripts/list_most_intensive_processes.py <count>`

## Code Style Guidelines

### Imports and Module Structure
- All skills are defined as individual markdown files with YAML frontmatter
- Python scripts use standard imports (psutil, os, sys)
- Scripts should be placed in `/scripts/` directories within each skill folder
- No external dependencies required beyond what's specified in the SKILL.md

### Formatting
- Use 2-space indentation for all code blocks and markdown content  
- Keep markdown files under 500 lines to ensure effective context window usage
- Follow YAML frontmatter format with consistent spacing:
```yaml
---
name: skill-name
description: Clear description of what this skill does
---
```

### Naming Conventions
- Skill directories should use lowercase hyphenated names (e.g., `file-organizer`)
- Markdown files should be named `SKILL.md` for main documentation 
- Python scripts in `/scripts/` folders should be descriptive and lowercase with underscores (e.g., `list_files.py`, `list_most_intensive_processes.py`)
- Variables use snake_case
- Constants use UPPER_CASE

### Error Handling
- All Python scripts should handle file system errors gracefully
- Use try/catch blocks for operations that might fail
- Return meaningful error messages to users when operations are unsuccessful
- Handle edge cases such as empty directories or permission issues

### Documentation Standards  
- Each skill must have a `SKILL.md` file with:
  - YAML frontmatter (name, description)
  - Clear system prompt/usage instructions
  - Examples of usage patterns
  - Guidelines for implementation
- Follow the structure defined in existing skills
- Keep documentation concise and focused on agent use cases

### Security Considerations
- All bash commands should be carefully validated before execution 
- Avoid executing untrusted input directly as shell commands
- When using file operations, ensure proper permissions are checked
- Python scripts should not modify system files without explicit user confirmation