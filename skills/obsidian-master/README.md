# Obsidian Master Skill

A comprehensive agent skill for controlling and interacting with your Obsidian knowledge base through the Obsidian CLI.

## Quick Start

Read a note:
```bash
obsidian read file="My Note"
```

Create a new note:
```bash
obsidian create name="New Project" content="# New Project\n\nStarted today."
```

Search vault:
```bash
obsidian search query="machine learning" limit=10
```

## Documentation Structure

- **[SKILL.md](SKILL.md)** - Main skill documentation with overview and quick start examples
- **references/** - Detailed command reference for specific feature categories:
  - [Vault Structure Guide](references/vault-structure-guide.md) - **Read this first.** How Obsidian organizes information, note anatomy, knowledge graph navigation, and decision trees for finding content
  - [File Operations](references/file-operations.md) - Read, create, edit, move, delete files
  - [Search & Discovery](references/search-discovery.md) - Search vault, tags, daily notes, discovery tools
  - [Link Analysis](references/link-analysis.md) - Backlinks, dead ends, orphans, unresolved links
  - [Properties & Metadata](references/properties-metadata.md) - Set/read/manage YAML frontmatter properties
  - [Task Management](references/task-management.md) - List and update checklist tasks
  - [Vault Administration](references/vault-admin.md) - Plugins, themes, templates, vault info

## Key Features

### File Operations
- Read file contents by name or path
- Create new notes with content or templates
- Append/prepend to existing files
- Rename and move files safely
- Delete files (trash or permanent)

### Search & Discovery
- Full-text search across vault
- Tag browsing and filtering
- Daily note operations (read, append, prepend)
- Random note discovery
- Recently opened files

### Link Analysis
- Find backlinks to any note
- Outgoing links from notes
- Dead ends (no outgoing links)
- Orphans (no incoming links)
- Unresolved/broken link detection

### Properties & Metadata
- Set/read/remove YAML frontmatter properties
- Support for text, list, number, checkbox, date, datetime types
- Property discovery across vault
- Query by property values

### Task Management
- List tasks with filters (done/todo/status)
- Update task completion status
- Toggle between todo/done
- Custom status characters
- Daily note task integration

### Vault Administration
- Plugin management (enable/disable/install/uninstall)
- Theme switching and installation
- Template operations
- Base/database queries
- Command execution

## Important Notes

- Most commands default to the active file when path is omitted
- Use `format=json` for programmatic parsing of results
- Quote values with spaces: `name="My Note"`
- Use `\n` for newlines in content strings

## Error Handling

Common scenarios and responses:
- **File not found**: CLI returns error; agent should suggest alternatives or offer creation
- **Permission errors**: Clear messages about access restrictions
- **Invalid operations**: Helpful guidance on correct usage patterns

## Requirements

- Obsidian installed with CLI support (version 1.5+)
- Node.js environment for running CLI commands

## Contributing

To extend this skill:
1. Add new command examples to relevant reference files
2. Document edge cases and best practices as discovered
3. Keep individual reference files focused (under 500 lines recommended)
4. Use JSON format in examples for clarity
