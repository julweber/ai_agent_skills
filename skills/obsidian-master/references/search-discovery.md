# Search & Discovery Reference

Complete documentation for searching and discovering content in Obsidian.

## Text Search

### Basic Search
```bash
obsidian search \
  query="<search-text>" \
  [options]
```

**Parameters:**
- `query`: Search text (required)
- `path`: Limit search to specific folder
- `limit`: Maximum results to return
- `case`: Enable case-sensitive matching
- `total`: Return match count instead of results
- `format`: text|json (default: text)

**Examples:**
```bash
# Simple search
obsidian search query="machine learning"

# Limit results and use JSON format
obsidian search query="API design" limit=5 format=json

# Case-sensitive search in specific folder
obsidian search query="React" case=true path="Projects/"
```

### Search with Context
Get matching lines with surrounding context.
```bash
obsidian search:context \
  query="<search-text>" \
  [options]
```

**Parameters:** Same as basic search, plus:
- Returns matching line with preceding and following context lines
- Useful for understanding how terms are used in context

**Example:**
```bash
# Find "authentication" with surrounding context
obsidian search:context query="authentication" format=json limit=3
```

## Tag Operations

### List All Tags
```bash
obsidian tags \
  [options]
```

**Parameters:**
- `file` or `path`: Limit to specific file's tags
- `total`: Return count instead of list
- `counts`: Include occurrence counts per tag
- `sort=count`: Sort by frequency (default: name)
- `format`: json|tsv|csv (default: tsv)
- `active`: Show tags for currently active file

**Examples:**
```bash
# List all tags with counts, sorted by frequency
obsidian tags counts=true sort=count format=json

# Get tag count only
obsidian tags total=true

# Tags from specific file
obsidian tags file="Project Alpha"
```

### Specific Tag Information
Get details about a particular tag.
```bash
obsidian tag \
  name="<tag-name>" \
  [options]
```

**Parameters:**
- `name`: Tag name without # (required)
- `total`: Return occurrence count only
- `verbose`: Include list of files using this tag and total count

**Example:**
```bash
# Get all information about #project tag
obsidian tag name="project" verbose=true
```

## Daily Notes

### Open Daily Note
```bash
obsidian daily \
  [options]
```

**Parameters:**
- `paneType`: tab|split|window (default: current pane)

### Read Daily Note Content
```bash
obsidian daily:read
```
Returns full content of today's daily note. Creates if it doesn't exist.

### Append to Daily Note
Add entry to today's daily note.
```bash
obsidian daily:append \
  content="<entry-text>" \
  [options]
```

**Parameters:**
- `content`: Entry text (required)
- `inline`: No preceding newline (default: false)
- `open`: Open daily note after adding (default: false)
- `paneType`: tab|split|window for opening

### Prepend to Daily Note
Add entry at the beginning of today's daily note.
```bash
obsidian daily:prepend \
  content="<entry-text>" \
  [options]
```

**Parameters:** Same as append.

### Get Daily Note Path
Find where your daily notes are stored.
```bash
obsidian daily:path
```

## File Discovery

### List Recently Opened Files
```bash
obsidian recents \
  [options]
```

**Parameters:**
- `total`: Return count instead of list

### Random Note Operations
Open or read a random note.
```bash
# Open random note
obsidian random \
  folder="<folder>" \
  newtab=true

# Read random note content
obsidian random:read \
  folder="<folder>"
```

**Parameters:**
- `folder`: Limit selection to specific folder (optional)
- `newtab`: Open in new tab instead of current pane

### Search View
Open the search interface with pre-filled query.
```bash
obsidian search:open \
  query="<initial-query>"
```

## Outline & Structure

### Show File Headings
Get outline/structure of a file.
```bash
obsidian outline \
  file="<name>" \
  [options]
```

**Parameters:**
- `file` or `path`: Target file
- `format`: tree|md|json (default: tree)
- `total`: Return heading count instead of list

**Examples:**
```bash
# Get outline as JSON for parsing
obsidian outline file="Document.md" format=json

# Count headings in file
obsidian outline path="Guide/intro.md" total=true
```

## File & Folder Info

### List Files with Filters
```bash
obsidian files \
  [options]
```

**Parameters:**
- `folder`: Filter by folder path
- `ext`: Filter by extension (e.g., ".md")
- `total`: Return file count only

### Folder Information
Get stats about a specific folder.
```bash
obsidian folder \
  path="<folder-path>" \
  info=files|folders|size
```

**Parameters:**
- `path`: Folder path (required)
- `info`: Return specific metric only (optional): files, folders, or size

## Common Search Patterns

### Find All Notes Mentioning X
```bash
obsidian search query="X" format=json limit=100
```

### Discover Tag Ecosystem
```bash
obsidian tags counts=true sort=count format=json total=false
```

### Daily Note Routine
```bash
# Get today's daily note content first
obsidian daily:read

# Add new entry
obsidian daily:append content="- Task for $(date)"
```

### Explore Folder Structure
```bash
# List all markdown files in Projects folder
obsidian files path="Projects/" ext=".md" format=json
```

## Edge Cases & Best Practices

### Search Limitations
- Very large vaults may need `limit` parameter to avoid excessive results
- Case-insensitive by default; use `case=true` for exact matching
- Search doesn't include PDF attachments or images (text-only)

### Path Ambiguity
- Multiple files can share the same name in different folders
- Use full paths (`path=`) when name ambiguity exists
- Search results include file paths to help disambiguate

### Daily Note Creation
- If daily note doesn't exist, `daily:read` creates it automatically
- Path is configurable in Obsidian settings (use `daily:path` to check)

### Performance Considerations
- Use `total=true` when you only need counts
- JSON format (`format=json`) is better for programmatic use
- Limit results with large vaults using the `limit` parameter
