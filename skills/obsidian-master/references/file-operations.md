# File Operations Reference

Complete documentation for file management operations in Obsidian.

## Reading Files

### Read File Contents
```bash
obsidian read file="<name>"
obsidian read path="<folder>/<file>.md"
```
- Returns full markdown content of the specified file
- Works with note name (wikilink) or exact path
- Defaults to active file if neither specified

### File Information
```bash
obsidian file file="<name>"
obsidian file path="<folder>/<file>.md"
```
Returns metadata about the file including:
- Path and name
- Last modified timestamp
- Link count information

## Creating Files

### Create New Note
```bash
obsidian create \
  name="<note-name>" \
  content="# Title\n\nContent here."
```

**Parameters:**
- `name`: File name (required for new files)
- `path`: Alternative to name using full path
- `content`: Initial markdown content
- `template`: Use existing template by name
- `overwrite`: Allow overwriting if file exists (default: false)
- `open`: Open the file after creating (default: false)
- `newtab`: Open in new tab instead of current pane

**Examples:**
```bash
# Create with inline content
obsidian create name="Project Alpha" content="# Project Alpha\n\nStarting point."

# Create using template
obsidian create name="Meeting Notes" template="meeting-template" open=true

# Create in specific folder
obsidian create path="Projects/Alpha/spec.md" content="# Specification"
```

## Editing Files

### Append to File
Add content to the end of a file.
```bash
obsidian append \
  file="<name>" \
  content="Additional content here."
```

**Parameters:**
- `file` or `path`: Target file (required)
- `content`: Content to append (required)
- `inline`: Append without preceding newline (default: false)

**Examples:**
```bash
# Add entry to daily note
obsidian append path="2026-03-01.md" content="- Completed task review\n"

# Add bullet point without newline
obsidian append file="Meeting Notes" content="* Discussion item" inline=true
```

### Prepend to File
Add content to the beginning of a file.
```bash
obsidian prepend \
  file="<name>" \
  content="# Header\n\nInitial section."
```

**Parameters:** Same as append, plus:
- `open`: Open file after prepending (default: false)
- `paneType`: tab|split|window for how to open (default: current pane)

## Renaming & Moving Files

### Rename File
Change the filename while keeping it in the same location.
```bash
obsidian rename \
  file="<current-name>" \
  name="<new-name>"
```

**Parameters:**
- `file` or `path`: Current file identifier (required)
- `name`: New filename without extension (required)

**Examples:**
```bash
# Rename by note name
obsidian rename file="Old Note Name" name="New Note Name"

# Rename using path
obsidian rename path="Projects/Old/spec.md" name="updated-spec"
```

### Move File
Move file to different folder or change location.
```bash
obsidian move \
  file="<name>" \
  to="<destination-folder-or-path>"
```

**Parameters:**
- `file` or `path`: Current file identifier (required)
- `to`: Destination folder path or full new path (required)

**Examples:**
```bash
# Move to different folder
obsidian move file="Document.md" to="Archive/2026/"

# Rename and move simultaneously
obsidian move path="Notes/temp.md" to="Projects/Alpha/final-spec.md"
```

## Deleting Files

### Delete File (Trash)
Move file to system trash.
```bash
obsidian delete file="<name>"
obsidian delete path="<folder>/<file>.md"
```

**Parameters:**
- `file` or `path`: File to delete (required)
- `permanent`: Skip trash, delete permanently (default: false)

**Examples:**
```bash
# Move to trash
obsidian delete file="Old Draft.md"

# Permanent deletion (irreversible)
obsidian delete path="Temp/scratch.md" permanent=true
```

## Common Patterns & Best Practices

### Safe File Operations
1. **Always verify before deleting**: Check if file exists and is the correct one
2. **Confirm overwrites**: Use `overwrite=true` only when intentional
3. **Track changes**: Consider reading file first to understand current state
4. **Use paths for precision**: Names can be ambiguous; full paths are clearer

### Path Resolution Rules
- `file=` parameter: Uses note name (wikilink style, like "My Note")
- `path=` parameter: Uses exact filesystem path ("Folder/Note.md")
- Most commands default to active file if neither specified

### Content Formatting
- Use `\n` for newlines in content strings
- Escape special characters as needed for shell
- YAML frontmatter should be included in content if desired
- Markdown headers start with `#` symbols

## Edge Cases & Error Handling

### File Already Exists
- Create command will fail unless `overwrite=true` specified
- Check file existence first or use overwrite flag intentionally

### Permission Issues
- Ensure Obsidian has write permissions for target folder
- Some system folders may be read-only

### Circular References
- Moving files with many interlinks may create broken references
- Consider using rename instead of move when possible

### Empty Content
- Creating files without content is allowed (useful for templates)
- Append/prepend require non-empty content
