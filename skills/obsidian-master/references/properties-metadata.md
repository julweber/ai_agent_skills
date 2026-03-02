# Properties & Metadata Reference

Complete documentation for managing YAML frontmatter properties in Obsidian notes.

## Overview

Obsidian uses YAML frontmatter at the top of markdown files to store structured metadata called "properties". These enable powerful querying, filtering, and organization capabilities.

### Supported Property Types
- `text`: Plain text strings
- `list`: Arrays of values (e.g., tags, keywords)
- `number`: Numeric values
- `checkbox`: Boolean true/false toggles
- `date`: Date-only values (YYYY-MM-DD)
- `datetime`: Full timestamp values

## Listing Properties

### List All Properties in Vault
Discover what properties exist across your entire knowledge base.
```bash
obsidian --no-sandbox properties \
  [options]
```

**Parameters:**
- `file` or `path`: Show properties for specific file only
- `name`: Get count of specific property type
- `total`: Return total property count
- `sort=count`: Sort by frequency (default: name)
- `counts`: Include occurrence counts per property
- `format`: yaml|json|tsv (default: yaml)
- `active`: Show properties for currently active file

**Examples:**
```bash
# List all properties in vault with counts, sorted alphabetically
obsidian --no-sandbox properties counts=true format=json

# Get count of "status" property usage across vault
obsidian --no-sandbox properties name="status" total=true

# Properties for specific note
obsidian --no-sandbox properties file="Project Alpha" format=json
```

### List Properties for Specific File
Get all properties defined in a particular note.
```bash
obsidian --no-sandbox properties \
  file="<name>" \
  path="<folder>/<file>.md"
```

**Example:**
```bash
# View all properties on this specific note
obsidian --no-sandbox properties path="Projects/Alpha/spec.md" format=json
```

## Reading Property Values

### Read Single Property
Extract value of a specific property from a file.
```bash
obsidian --no-sandbox property:read \
  name="<property-name>" \
  file="<file>" \
  [options]
```

**Parameters:**
- `name`: Property name (required)
- `file` or `path`: Target file identifier (required)

**Example:**
```bash
# Get status value from a note
obsidian --no-sandbox property:read name="status" file="Project Alpha"

# Read due date from specific path
obsidian --no-sandbox property:read name="due-date" path="Tasks/important.md"
```

**Output Format:** Returns just the property value (or empty if not found).

## Setting Property Values

### Set or Update Property
Create or modify a property on a file.
```bash
obsidian --no-sandbox property:set \
  name="<property-name>" \
  value="<value>" \
  type=<type> \
  file="<file>" \
  [options]
```

**Parameters:**
- `name`: Property name (required)
- `value`: Property value (required, format depends on type)
- `type`: Property type: text|list|number|checkbox|date|datetime
- `file` or `path`: Target file identifier (required)

**Value Format by Type:**
- `text`: Simple string (e.g., "in-progress")
- `list`: JSON array format (e.g., `["tag1", "tag2"]`)
- `number`: Numeric value without quotes (e.g., 42)
- `checkbox`: true or false (boolean, no quotes)
- `date`: Date string YYYY-MM-DD (e.g., "2026-03-15")
- `datetime`: Full timestamp (e.g., "2026-03-15T14:30:00")

**Examples:**
```bash
# Set text property
obsidian --no-sandbox property:set name="status" value="completed" type=text file="Note.md"

# Set list of tags
obsidian --no-sandbox property:set name="tags" value='["project", "urgent"]' type=list file="Task.md"

# Set numeric priority
obsidian --no-sandbox property:set name="priority" value=5 type=number file="Item.md"

# Set checkbox status
obsidian --no-sandbox property:set name="reviewed" value=true type=checkbox file="Document.md"

# Set date field
obsidian --no-sandbox property:set name="due-date" value="2026-03-15" type=date file="Task.md"

# Set datetime for deadline
obsidian --no-sandbox property:set name="deadline" value="2026-03-15T14:30:00" type=datetime file="Meeting.md"
```

## Removing Properties

### Delete Property from File
Remove a specific property definition.
```bash
obsidian --no-sandbox property:remove \
  name="<property-name>" \
  file="<file>" \
  [options]
```

**Parameters:**
- `name`: Property name to remove (required)
- `file` or `path`: Target file identifier (required)

**Example:**
```bash
# Remove temporary property
obsidian --no-sandbox property:remove name="draft-flag" file="Document.md"
```

## Common Patterns & Workflows

### Property-Based Querying
Find notes with specific property values by combining operations:
```bash
# 1. List all properties to discover available types
obsidian --no-sandbox properties format=json

# 2. Check value on specific note
obsidian --no-sandbox property:read name="status" file="Project Alpha"

# 3. Update based on current state
obsidian --no-sandbox property:set name="status" value="in-progress" type=text file="Project Alpha"
```

### Bulk Property Updates (Multiple Files)
Apply same property across multiple notes:
```bash
# For each target file, set the property
obsidian --no-sandbox property:set name="project" value="Alpha" type=text file="Doc1.md"
obsidian --no-sandbox property:set name="project" value="Alpha" type=text file="Doc2.md"
obsidian --no-sandbox property-set name="project" value="Alpha" type=text file="Doc3.md"
```

### Template Property Setup
Create notes with predefined properties:
```bash
# Create note with content including YAML frontmatter
obsidian --no-sandbox create name="New Task" \
  content='---\nstatus: todo\npriority: medium\ndue-date: 2026-03-20\n---\n\n# New Task\n\nDescription here.'
```

### Property Validation Workflow
Ensure required properties exist before proceeding:
```bash
# Check if property exists and has expected value
value=$(obsidian --no-sandbox property:read name="status" file="Note.md")
if [ "$value" != "reviewed" ]; then
  echo "Property not set correctly, updating..."
  obsidian --no-sandbox property:set name="status" value="reviewed" type=text file="Note.md"
fi
```

## Edge Cases & Best Practices

### Property Type Mismatches
- Setting a string as `number` type will fail or be converted unexpectedly
- Always specify correct `type` parameter for intended behavior
- Lists require JSON array format with proper escaping in shell

### Empty Values
- Setting property to empty string creates property with no value
- Use `property:remove` to completely delete property definition

### Property Name Case Sensitivity
- Property names are case-sensitive (`Status` ≠ `status`)
- Use consistent lowercase naming for reliability

### YAML Frontmatter Format
- Obsidian automatically manages YAML frontmatter structure
- Don't manually edit frontmatter in content when using property commands
- Property commands handle escaping and formatting correctly

### Special Characters in Values
- Strings with spaces need proper shell quoting: `value="my value"`
- JSON arrays require single quotes to prevent shell interpretation: `value='["a", "b"]'`
- Escape special characters within strings as needed

### Date Format Requirements
- `date` type: Must be YYYY-MM-DD format (e.g., "2026-03-15")
- `datetime` type: Full ISO 8601 timestamp (e.g., "2026-03-15T14:30:00")

### Property Defaults
- If property doesn't exist on file, `property:set` creates it
- `property:read` returns empty output if property not found (not an error)
