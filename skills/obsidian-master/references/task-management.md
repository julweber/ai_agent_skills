# Task Management Reference

Complete documentation for working with tasks in Obsidian.

## Overview

Obsidian tracks tasks as checklist items (marked with `- [ ]`, `- [x]`, etc.) within markdown files. This skill provides commands to list, filter, and update these tasks programmatically.

## Listing Tasks

### List All Tasks in Vault
Get comprehensive task overview across your entire knowledge base.
```bash
obsidian --no-sandbox tasks \
  [options]
```

**Parameters:**
- `file` or `path`: Filter by specific file name or path
- `total`: Return task count only
- `done`: Show only completed tasks (status = x)
- `todo`: Show only incomplete tasks (default behavior)
- `status="<char>"`: Filter by specific status character (e.g., "!", "?", "-")
- `verbose`: Group results by file with line numbers
- `format`: json|tsv|csv (default: text)
- `active`: Show tasks from currently active file only
- `daily`: Show tasks from today's daily note only

**Examples:**
```bash
# List all incomplete tasks in vault
obsidian --no-sandbox tasks format=json

# Get count of completed tasks
obsidian --no-sandbox tasks done=true total=true

# Tasks with custom status (e.g., "!" for important)
obsidian --no-sandbox tasks status="!" verbose=true format=json

# Only from specific file
obsidian --no-sandbox tasks path="Projects/Alpha/tasks.md" format=json

# From today's daily note only
obsidian --no-sandbox tasks daily format=json
```

### Tasks by File
Filter task list to a single note.
```bash
obsidian --no-sandbox tasks \
  file="<name>" \
  [options]
```

**Example:**
```bash
# All tasks in specific project file
obsidian --no-sandbox tasks file="Project Alpha" verbose=true format=json
```

## Task Operations

### Show or Update Specific Task
Get details about a task and optionally modify it.
```bash
obsidian --no-sandbox task \
  ref="<path:line>" \
  [options]
```

**Parameters:**
- `ref`: Task reference as "path:line_number" (required)
- OR use `file` + `line` parameters instead
- `toggle`: Toggle task status (todo ↔ done)
- `done`: Mark task as completed
- `todo`: Mark task as todo/incomplete
- `status="<char>"`: Set custom status character
- `daily`: Use daily note for new tasks

**Alternative Reference Methods:**
```bash
# Using file and line separately
obsidian --no-sandbox task \
  file="Note.md" \
  line=15 \
  done

# Using path reference (preferred)
obsidian --no-sandbox task ref="Projects/Alpha/tasks.md:23" toggle
```

**Examples:**
```bash
# Toggle a specific task's completion status
obsidian --no-sandbox task ref="Tasks/inbox.md:5" toggle

# Mark task as done
obsidian --no-sandbox task ref="Projects/Sprint/tasks.md:12" done

# Set custom status (e.g., "!" for high priority)
obsidian --no-sandbox task ref="Important/task.md:3" status="!"

# Mark as todo again
obsidian --no-sandbox task ref="Completed/item.md:7" todo
```

## Common Task Workflows

### Daily Review Routine
Start each day by reviewing pending tasks.
```bash
# Get all incomplete tasks from daily note
obsidian --no-sandbox tasks daily todo format=json

# Or get all todo tasks across vault for morning review
obsidian --no-sandbox tasks todo verbose=true format=json
```

### Complete a Task
Mark task as finished.
```bash
# By line reference (most precise)
obsidian --no-sandbox task ref="Tasks/daily.md:8" done

# Toggle if status unknown
obsidian --no-sandbox task ref="Inbox/quick-tasks.md:15" toggle
```

### Create New Task via Daily Note
Add new task to today's daily note.
```bash
# Append entry to daily note (creates task line)
obsidian --no-sandbox daily:append \
  content="- [ ] New task description\n"
```

### Filter by Custom Status
Work with non-standard task statuses.
```bash
# Find all tasks marked as important (!)
obsidian --no-sandbox tasks status="!" format=json

# Get count of blocked tasks (?)
obsidian --no-sandbox tasks status="?" total=true
```

## Task Status System

### Default Statuses
- `- [ ]` : Todo (incomplete, default)
- `- [x]` : Done (completed)

### Custom Status Characters
Obsidian supports any single character for custom statuses:
- `!` : Important/high priority
- `?` : Blocked/waiting
- `-` : Deferred/someday
- `*` : Starred/favorite
- Any other character you define in Obsidian settings

**Filtering by Status:**
```bash
# Get all "important" tasks (!)
obsidian --no-sandbox tasks status="!" format=json

# Count blocked items (?)
obsidian --no-sandbox tasks status="?" total=true
```

## Output Formats

### Text Format (Default)
Human-readable list with file paths and line numbers.
```bash
- [x] Complete report (Projects/Alpha/report.md:15)
- [ ] Review PR #123 (Tasks/inbox.md:8)
```

### JSON Format
Structured data for programmatic processing.
```bash
obsidian --no-sandbox tasks format=json
# Returns: [{"file": "Projects/Alpha/report.md", "line": 15, "status": "x", "text": "Complete report"}, ...]
```

### TSV/CSV Format
Tab or comma-separated values for spreadsheet import.
```bash
obsidian --no-sandbox tasks format=tsv
# Returns: file\tline\tstatus\ttext (header row included)
```

## Edge Cases & Best Practices

### Task Reference Precision
- Use `ref="path:line"` for exact task targeting
- File names with spaces need proper quoting: `ref="My Tasks/task.md:5"`
- Line numbers are 1-indexed

### Daily Note Limitations
- `daily` filter only works if daily note exists today
- Creates daily note automatically if needed (when using append/prepend)

### Status Character Consistency
- Custom status characters must be defined in Obsidian settings to work properly
- Stick to single-character statuses for reliable filtering

### Task vs Property Confusion
- Tasks are checklist items within file content (`- [ ]`)
- Properties are YAML frontmatter metadata (see Properties reference)
- Use properties for structured metadata, tasks for actionable items

### Large Vault Performance
- `verbose=true` with large vaults can be slow
- Use `total=true` when only counts needed
- Filter by specific file to reduce scope

### Line Number Changes
- When editing files, line numbers may shift
- Best practice: use task reference immediately after creation
- For persistent references, consider using Obsidian's native task plugins

## Integration with Other Operations

### Create Note with Tasks
```bash
obsidian --no-sandbox create name="Sprint Plan" \
  content='# Sprint Planning\n\n## Tasks\n\n- [ ] Review requirements\n- [ ] Estimate story points\n- [ ] Assign tasks'
```

### Update After File Edit
After modifying a file, verify task state:
```bash
# Read file to see current task status
obsidian --no-sandbox read path="Tasks/inbox.md"

# Mark remaining todos as done
obsidian --no-sandbox tasks path="Tasks/inbox.md" todo format=json
```

### Cross-Reference with Properties
Combine task and property queries:
```bash
# Find tasks in notes with specific property
# (requires combining multiple commands)
properties=$(obsidian --no-sandbox properties name="priority" total=true)
tasks=$(obsidian --no-sandbox tasks status="!" format=json)
# Process both to find high-priority tasks
```
