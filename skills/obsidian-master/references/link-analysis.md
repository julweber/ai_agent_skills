# Link Analysis Reference

Complete documentation for analyzing connections between notes in Obsidian.

## Outgoing Links

### List Links from File
Find all files that this note links to.
```bash
obsidian --no-sandbox links \
  file="<name>" \
  [options]
```

**Parameters:**
- `file` or `path`: Source file (required)
- `total`: Return link count instead of list

**Example:**
```bash
# Get all outgoing links from a note
obsidian --no-sandbox links file="Project Alpha"

# Count links without listing them
obsidian --no-sandbox links path="Guide/index.md" total=true
```

## Backlinks

### List Backlinks to File
Find all files that link TO the specified note.
```bash
obsidian --no-sandbox backlinks \
  file="<name>" \
  [options]
```

**Parameters:**
- `file` or `path`: Target file (required)
- `counts`: Include number of links per source file
- `total`: Return backlink count only
- `format`: json|tsv|csv (default: tsv)

**Example:**
```bash
# Get all files linking to "Research" note with counts
obsidian --no-sandbox backlinks file="Research" counts=true format=json
```

## Dead Ends & Orphans

### Dead Ends (No Outgoing Links)
Find notes that don't link to anything else.
```bash
obsidian --no-sandbox deadends \
  [options]
```

**Parameters:**
- `total`: Return count only
- `all`: Include non-markdown files in search

**Use Case**: Identify isolated notes that should have more connections, or clean up truly standalone reference documents.

**Example:**
```bash
# Get dead-end file list with counts
obsidian --no-sandbox deadends all=true format=json
```

### Orphans (No Incoming Links)
Find notes that nothing links to.
```bash
obsidian --no-sandbox orphans \
  [options]
```

**Parameters:** Same as deadends:
- `total`: Return count only
- `all`: Include non-markdown files

**Use Case**: Identify content that may be hard to discover, or notes that should have more incoming references.

**Example:**
```bash
# List orphaned notes
obsidian --no-sandbox orphans format=json
```

## Unresolved Links

### Find Broken References
Identify links pointing to non-existent files.
```bash
obsidian --no-sandbox unresolved \
  [options]
```

**Parameters:**
- `total`: Return count only
- `counts`: Include link counts per target
- `verbose`: List source files for each broken link
- `format`: json|tsv|csv (default: tsv)

**Example:**
```bash
# Get all unresolved links with source file details
obsidian --no-sandbox unresolved verbose=true format=json
```

## Alias Information

### List Aliases in Vault
Find note aliases used throughout the vault.
```bash
obsidian --no-sandbox aliases \
  [options]
```

**Parameters:**
- `file` or `path`: Limit to specific file's aliases
- `total`: Return alias count only
- `verbose`: Include file paths for each alias

**Example:**
```bash
# List all aliases with their source files
obsidian --no-sandbox aliases verbose=true format=json
```

## Link Analysis Patterns & Workflows

### Find Well-Connected Notes
Identify notes that serve as hubs in your knowledge graph.
```bash
# High outgoing link count
obsidian --no-sandbox links file="Hub Note" total=true
# Compare across multiple files to find most connected

# High backlink count (popular target)
obsidian --no-sandbox backlinks file="Core Concept" counts=true format=json
```

### Discovery Workflow: Build Connections
1. Find dead ends that need more linking:
   ```bash
   obsidian --no-sandbox deadends all=false format=json
   ```
2. For each dead end, check if it should link to other notes
3. Add links using file edit operations

### Cleanup Workflow: Fix Broken Links
1. Identify unresolved links:
   ```bash
   obsidian --no-sandbox unresolved verbose=true format=json
   ```
2. Review which files have broken references
3. Either create missing target files or remove/update the broken links

### Relationship Mapping
Understand how two notes are connected:
```bash
# Check if Note A links to Note B
obsidian --no-sandbox links file="Note A" | grep "Note B"

# Check if anything links back from Note B to Note A
obsidian --no-sandbox backlinks file="Note B" | grep "Note A"
```

## Edge Cases & Considerations

### Self-References
- Notes can link to themselves (e.g., for navigation)
- These count as both outgoing and incoming links

### Internal vs External Links
- Obsidian wiki-links (`[[Note Name]]`) are tracked
- Markdown external links (`[text](url)`) are NOT included in analysis

### Alias Behavior
- Multiple aliases can point to the same file
- Aliases appear in alias listings but not as regular links

### Link Counting
- `total` parameter returns raw count, may include duplicates
- `counts` parameter shows per-source breakdown when available

### Performance with Large Vaults
- Analyzing entire vault for dead ends/orphans can be slow
- Use `format=json` for easier parsing of large result sets
- Consider limiting analysis to specific folders where possible

## Integration with Other Operations

### Link After Creating File
```bash
# Create new note that links to existing content
obsidian --no-sandbox create name="New Topic" \
  content="# New Topic\n\nRelated: [[Core Concept]]\n\nSee also: [[Supporting Material]]"
```

### Update Links When Renaming
```bash
# Rename file (automatically updates all incoming links in Obsidian)
obsidian --no-sandbox rename file="Old Name" name="New Name"

# Verify link integrity afterward
obsidian --no-sandbox unresolved format=json
```
