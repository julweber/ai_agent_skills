# Vault Administration Reference

Complete documentation for vault administration, plugins, themes, and advanced operations.

## Vault Information & Management

### Get Vault Info
Retrieve statistics and details about your current vault.
```bash
obsidian vault \
  info=name|path|files|folders|size
```

**Parameters:**
- `info`: Return specific metric only:
  - `name`: Vault name
  - `path`: Filesystem path to vault
  - `files`: Total file count
  - `folders`: Total folder count
  - `size`: Storage size used

**Examples:**
```bash
# Get full vault information
obsidian vault

# Just get file count
obsidian vault info=files

# Check storage usage
obsidian vault info=size
```

### List Known Vaults
See all vaults configured in Obsidian.
```bash
obsidian vaults \
  [options]
```

**Parameters:**
- `total`: Return count only
- `verbose`: Include full paths to each vault

**Example:**
```bash
# List all known vaults with paths
obsidian vaults verbose=true format=json
```

### Switch Between Vaults
Target a specific vault for operations.
```bash
obsidian <command> vault=<vault-name> [other-options]
```

**Example:**
```bash
# Get file count from "Personal" vault
obsidian files vault="Personal" total=true

# Search in "Work" vault only
obsidian search query="meeting notes" vault="Work" limit=10
```

### Reload Vault
Refresh the vault without restarting Obsidian.
```bash
obsidian reload
```

### Restart Obsidian
Completely restart the application.
```bash
obsidian restart
```

## Plugin Management

### List Installed Plugins
Get overview of all plugins in your vault.
```bash
obsidian plugins \
  [options]
```

**Parameters:**
- `filter`: core|community (default: both)
- `versions`: Include version numbers
- `format`: json|tsv|csv (default: tsv)

**Examples:**
```bash
# List all community plugins with versions
obsidian plugins filter=community versions=true format=json

# Get only core plugins
obsidian plugins filter=core format=json
```

### List Enabled Plugins
See which plugins are currently active.
```bash
obsidian plugins:enabled \
  [options]
```

**Parameters:** Same as plugins command (filter, versions, format)

### Enable/Disable Plugins

#### Enable Plugin
Activate a plugin.
```bash
obsidian plugin:enable \
  id="<plugin-id>" \
  filter=core|community
```

#### Disable Plugin
Deactivate a plugin.
```bash
obsidian plugin:disable \
  id="<plugin-id>" \
  filter=core|community
```

**Parameters:**
- `id`: Plugin identifier (required)
- `filter`: Plugin type: core or community

**Examples:**
```bash
# Enable Dataview community plugin
obsidian plugin:enable id="dataview" filter=community

# Disable a specific core plugin
obsidian plugin:disable id="canvas" filter=core
```

### Install Community Plugin
Add new community plugin to your vault.
```bash
obsidian plugin:install \
  id="<plugin-id>" \
  enable              # Optional: enable immediately after install
```

**Parameters:**
- `id`: Plugin identifier (required)
- `enable`: Enable right after installation (default: false)

**Example:**
```bash
# Install and enable Calendar plugin
obsidian plugin:install id="calendar" enable=true
```

### Uninstall Community Plugin
Remove a community plugin.
```bash
obsidian plugin:uninstall \
  id="<plugin-id>"
```

**Parameters:**
- `id`: Plugin identifier (required)

**Example:**
```bash
# Remove unused plugin
obsidian plugin:uninstall id="unused-plugin-id"
```

### Reload Plugin (Developer Mode)
Force reload a plugin without restarting Obsidian.
```bash
obsidian plugin:reload \
  id="<plugin-id>"
```

**Parameters:**
- `id`: Plugin identifier (required)

### Get Plugin Info
Retrieve details about specific plugin.
```bash
obsidian plugin \
  id="<plugin-id>"
```

## Theme Management

### List Installed Themes
See available themes in your vault.
```bash
obsidian themes \
  versions              # Optional: include version numbers
```

**Example:**
```bash
# List all installed themes with versions
obsidian themes versions=true format=json
```

### Get Theme Information
View details about a specific theme.
```bash
obsidian theme \
  name="<theme-name>"
```

**Parameters:**
- `name`: Theme name (optional: omit for current active theme)

**Examples:**
```bash
# See info about "Minimal" theme
obsidian theme name="Minimal"

# Check currently active theme
obsidian theme
```

### Set Active Theme
Switch to a different theme.
```bash
obsidian theme:set \
  name="<theme-name>"
```

**Parameters:**
- `name`: Theme name (empty string for default theme)

**Examples:**
```bash
# Switch to Minimal theme
obsidian theme:set name="Minimal"

# Revert to default Obsidian theme
obsidian theme:set name=""
```

### Install Community Theme
Add new theme from community.
```bash
obsidian theme:install \
  name="<theme-name>" \
  enable              # Optional: activate immediately
```

**Parameters:**
- `name`: Theme name (required)
- `enable`: Activate after installation (default: false)

**Example:**
```bash
# Install and activate One Dark theme
obsidian theme:install name="One Dark" enable=true
```

### Uninstall Theme
Remove a theme from your vault.
```bash
obsidian theme:uninstall \
  name="<theme-name>"
```

**Parameters:**
- `name`: Theme name (required)

**Example:**
```bash
# Remove unused theme
obsidian theme:uninstall name="Old Theme"
```

## CSS Snippets

### List Installed Snippets
See available custom CSS snippets.
```bash
obsidian snippets
```

### List Enabled Snippets
Check which snippets are currently active.
```bash
obsidian snippets:enabled
```

### Enable/Disable Snippet

#### Enable CSS Snippet
Activate a snippet.
```bash
obsidian snippet:enable \
  name="<snippet-name>"
```

#### Disable CSS Snippet
Deactivate a snippet.
```bash
obsidian snippet:disable \
  name="<snippet-name>"
```

## Template Operations

### List Available Templates
See templates configured in your vault.
```bash
obsidian templates \
  total               # Optional: return count only
```

### Read Template Content
Get template content without inserting it.
```bash
obsidian template:read \
  name="<template-name>" \
  resolve             # Optional: resolve variables
  title="<title>"     # Optional: for variable resolution context
```

**Parameters:**
- `name`: Template name (required)
- `resolve`: Expand template variables if present
- `title`: Title for resolving relative references

### Insert Template into Active File
Apply a template to current note.
```bash
obsidian template:insert \
  name="<template-name>"
```

**Example:**
```bash
# Apply meeting notes template
obsidian template:insert name="meeting-notes"
```

## Bases & Queries

### List Base Files
Find files configured as bases (structured databases).
```bash
obsidian bases
```

### Create Item in Base
Add new entry to a base database.
```bash
obsidian base:create \
  file="<base-file>" \
  view="<view-name>" \
  name="<item-name>" \
  content="<initial-content>" \
  open              # Optional: open after creation
  newtab            # Optional: open in new tab
```

**Parameters:**
- `file` or `path`: Base file identifier (required)
- `view`: View name within base (optional)
- `name`: Name for new item (required)
- `content`: Initial content for the item
- `open`: Open after creating
- `newtab`: Open in new tab

### Query Base Database
Extract data from a base using its views.
```bash
obsidian base:query \
  file="<base-file>" \
  view="<view-name>" \
  format=json|csv|tsv|md|paths
```

**Parameters:**
- `file` or `path`: Base file identifier (required)
- `view`: View name to query (optional)
- `format`: Output format (default: json)

### List Views in Base
See available views for a base file.
```bash
obsidian base:views \
  file="<base-file>"
```

## Advanced Operations

### Execute Obsidian Command
Run any Obsidian command by its ID.
```bash
obsidian command \
  id="<command-id>"
```

**Parameters:**
- `id`: Command identifier (required)
  - Use `commands` or `commands filter=` to discover available IDs

**Example:**
```bash
# Open command palette
obsidian command id="app:open-command-palette"

# Toggle sidebar
obsidian command id="editor:toggle-left-sidebar"
```

### List Available Commands
Discover command IDs for execution.
```bash
obsidian commands \
  filter="<prefix>"     # Optional: filter by ID prefix
```

**Example:**
```bash
# List all editor commands
obsidian commands filter="editor:"
```

### Get Hotkey Information
Find keyboard shortcut for a command.
```bash
obsidian hotkey \
  id="<command-id>" \
  verbose             # Optional: show if custom or default
```

**Parameters:**
- `id`: Command ID (required)
- `verbose`: Show whether hotkey is user-defined or default

### List All Hotkeys
Get overview of keyboard shortcuts.
```bash
obsidian hotkeys \
  total               # Optional: return count only
  verbose             # Optional: show custom status
  format=json|tsv|csv
  all                 # Include commands without hotkeys
```

## Common Administration Workflows

### Vault Health Check
Assess vault condition and connectivity.
```bash
# Get basic stats
obsidian vault info=files
obsidian vault info=folders

# Check for broken links
obsidian unresolved total=true

# Find isolated content
obsidian deadends total=true
obsidian orphans total=true
```

### Plugin Management Routine
Maintain plugin ecosystem.
```bash
# List community plugins
obsidian plugins filter=community format=json

# Enable specific plugin
obsidian plugin:enable id="dataview" filter=community

# Install new plugin with auto-enable
obsidian plugin:install id="calendar" enable=true
```

### Theme Switching Workflow
Change appearance systematically.
```bash
# See available themes
obsidian themes versions=true format=json

# Apply new theme
obsidian theme:set name="Minimal"

# Verify current theme
obsidian theme
```

## Edge Cases & Best Practices

### Plugin/Theme Identifiers
- Use exact plugin/theme identifiers (case-sensitive)
- Check `plugins` or `themes` command output for correct IDs
- Community plugins often have unique IDs different from display names

### Vault Switching Context
- `vault=` parameter affects all subsequent commands until changed
- Default vault is the currently active one in Obsidian GUI
- Always specify vault explicitly when working with multiple vaults

### Permission Requirements
- Plugin/theme installation requires internet access
- Some operations may fail if Obsidian is locked or in restricted mode
- Check `plugins:restrict` status before bulk operations

### Performance Considerations
- Large vaults with many plugins/themes take longer to enumerate
- Use JSON format for programmatic processing of large lists
- Filter results where possible to reduce output size

### Template Variables
- Templates can contain variables like `<% title %>`
- Use `resolve=true` in `template:read` to expand them
- Provide `title` context when resolving relative references
