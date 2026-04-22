---
name: obsidian-master
description: Controls Obsidian vault via CLI. Performs file operations (read/create/edit/move/delete), searches vault content, analyzes links/backlinks, manages properties and metadata, queries bases, handles tasks, retrieves history versions, and manages plugins/themes. Use when working with Obsidian notes, managing your vault, searching for content, tracking connections between notes, or administering vault settings.
---

# Obsidian Master

A skill to control and interact with your Obsidian vault through the Obsidian CLI.

## Vault Structure Primer

**Before performing any vault operations, understand how Obsidian organizes information.**

See [Vault Structure Guide](references/vault-structure-guide.md) for the complete reference. Key concepts:

- A vault is a **folder of `.md` files** — no database, just files
- Each note has three layers: **properties** (YAML frontmatter), **content** (markdown body), **connections** (wikilinks `[[]]`)
- Notes connect via `[[wikilinks]]` creating a **bidirectional knowledge graph** (outgoing links + backlinks)
- Organization uses **folders** (broad categories), **tags** (`#label`), **properties** (structured metadata), and **links** (relationships) — often all four simultaneously
- **MOCs** (Maps of Content) are curated index notes — the best entry points for a topic
- Always discover vault structure first: check tags, properties, and hub notes before diving in
- Always count results with `total=true` before pulling full lists

## When to Use This Skill

Use this skill when you need to:
- Read, create, edit, move, or delete notes in your Obsidian vault
- Search for content across your entire vault
- Analyze connections between notes (backlinks, outgoing links)
- Manage note properties and metadata
- Query structured bases and databases
- Handle tasks and task lists
- Access file history and recovery versions
- Administer vault settings, plugins, or themes

## Skill general usage

- This skill ALWAYS uses the bash tool for executing the obsidian cli command directly within a shell.
- When searching for information within the vault:
  - always also query the number of found results
  - the default search limit is 50
  - if there are more than 50 findings, notify the user about it

## Core Operations

### Vault Structure & Navigation
Understand how the vault organizes information before performing operations. Learn about note anatomy (properties, content, links), the knowledge graph, organizational patterns (PARA, Zettelkasten, MOCs), and how to find information effectively.

**Reference**: See [Vault Structure Guide](references/vault-structure-guide.md) for the complete structural reference and navigation decision trees.

### File Management
Read content, create new notes, edit existing files, rename/move files, or delete notes.

**Reference**: See [File Operations](references/file-operations.md) for complete command details.

### Search & Discovery
Search vault text, find tags, explore recently opened files, access daily notes, or open random notes.

**Reference**: See [Search & Discovery](references/search-discovery.md) for search patterns and options.

### Link Analysis
Discover backlinks to notes, outgoing links from notes, dead ends (no outgoing), orphans (no incoming), or unresolved links.

**Reference**: See [Link Analysis](references/link-analysis.md) for connection analysis commands.

### Properties & Metadata
Set, read, remove, or list YAML frontmatter properties including text, lists, numbers, checkboxes, dates, and datetimes.

**Reference**: See [Properties & Metadata](references/properties-metadata.md) for property operations.

### Task Management
List tasks with filters (done/todo/status), update task status, toggle completion, or query by file/daily note.

**Reference**: See [Task Management](references/task-management.md) for task operations.

### Vault Administration
Manage vault info, switch between vaults, handle plugins/themes, access templates, and perform maintenance tasks.

**Reference**: See [Vault Administration](references/vault-admin.md) for admin commands.

## Quick Start Examples

```bash
# Read a note by name or path
obsidian read file="My Note"

# Create a new note with content
obsidian create name="New Project" content="# New Project\n\nStarted today."

# Find all backlinks to a specific note
obsidian backlinks file="Research" counts=true format=json

# Search vault for text
obsidian search query="machine learning" limit=50

# Set a property on a file
obsidian property:set name="status" value="in-progress" type=text file="Note.md"

# List tasks marked as todo
obsidian tasks done=false verbose=true format=json

# Find files with no outgoing links (dead ends)
obsidian deadends total=true
```

## Important Notes

- Most commands default to the active file when path is omitted
- Use JSON output format (`format=json`) for programmatic parsing
- Quote values with spaces: `name="My Note"`
- Use `\n` for newlines in content strings

## Error Handling

Common failure modes and responses:
- **File not found**: The CLI will return an error; consider suggesting alternatives or offering to create the file
- **Permission errors**: Clear error messages about access restrictions
- **Invalid paths**: Verify path format (relative vs absolute)

For detailed command syntax, parameter options, and edge cases, consult the reference documentation linked above.
