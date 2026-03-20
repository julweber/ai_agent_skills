---
name: trello-cli
description: Power shell user for Trello via CLI. Execute trello commands, parse JSON output, manage boards/cards/lists programmatically.
---

# Trello CLI Skill

This skill enables you to use the `trello` CLI tool as a power shell user for Trello operations. It provides a structured way to interact with your Trello workspace through command-line operations.

## Overview

The trello-cli is a Node.js-based command-line interface that allows you to:
- Manage boards, cards, lists, and labels
- Handle authentication securely
- Search across your workspace
- Export data in multiple formats (JSON, CSV)

## Authentication Setup

Before using any commands, ensure you're authenticated:

```bash
trello auth --help
trello interactive  # Launches a browser-based OAuth flow
```

Or set environment variables:
```bash
export TRELLO_KEY="your-api-key"
export TRELLO_TOKEN="your-api-token"
```

## Core Operations

### Board Management

#### List all boards
```bash
trello board:list --format json
trello board:list --format csv  # For spreadsheet export
```

#### Show board details
```bash
trello board:show -i <board-id> --format json
```

#### Create a new board
```bash
trello board:create -n "Project Name" \
    -d "Board description" \
    --prefs.permissionLevel public \
    --defaultLists
```

#### Update board settings
```bash
trello board:update -i <board-id> \
    -n "Updated Board Name" \
    --prefs.cardAging pirate
```

#### Delete a board
```bash
trello board:delete -i <board-id>
```

### Card Management

#### List cards in a list
```bash
trello card:list -l <list-id> --format json
```

#### Show card details
```bash
trello card:show -i <card-id> --format json
```

#### Create a new card
```bash
trello card:create \
    -n "Task Title" \
    --board <board-id> \
    --list <list-id> \
    --description "Detailed description here"
    --due "2026-03-25T17:00:00.000Z"
```

#### Move a card to another list
```bash
trello card:move -i <card-id> \
    --board <board-id> \
    --list <target-list-id>
```

#### Add label to card
```bash
trello card:label -i <card-id> \
    --board <board-id> \
    "Red Label" "Blue Label"
```

#### Remove label from card
```bash
trello card:unlabel -i <card-id> \
    --board <board-id> \
    "Red Label"
```

#### Add comment to card
```bash
trello card:comment -i <card-id> \
    --text "This is a new comment"
```

#### List all comments on a card
```bash
trello card:comments -i <card-id> --format json
```

#### Archive a card
```bash
trello card:archive -i <card-id>
```

### List Management

#### List lists in a board
```bash
trello list:list -b <board-id> --format json
```

#### Create a new list
```bash
trello list:create \
    -b <board-id> \
    -n "New List Name"
```

#### Rename a list
```bash
trello list:rename -i <list-id> \
    --name "Updated List Name"
```

#### Archive all cards in a list
```bash
trello list:archive-cards -i <list-id>
```

### Label Management

#### Create a label on board
```bash
trello label:create \
    -b <board-id> \
    --name "Bug" \
    --color "darkred"
```

#### List all labels on a board
```bash
trello label:list -b <board-id> --format json
```

### Search Across Trello

```bash
trello search -q "urgent task" --format json
```

## Output Formats

All commands support multiple output formats:
- `default`: Human-readable formatted output
- `silent`: Minimal output, just results
- `json`: Structured JSON for scripting
- `csv`: Comma-separated values for spreadsheets

```bash
trello card:list -l <list-id> --format json | jq .
trello board:list --format csv > boards.csv
```

## Common Workflows

### Backup your workspace
```bash
# Export all boards as JSON
for board in $(trello board:list --format json | jq -r '.[].id'); do
    trello board:show -i $board --format json > "${board}.json"
done
```

### Bulk card creation from CSV
```bash
# Read cards from CSV and create them
while IFS=',' read name description; do
    trello card:create \
        -n "$name" \
        --board $BOARD_ID \
        --list $LIST_ID \
        --description "$description"
done < cards.csv
```

### Automated status updates
```bash
# Move all "Done" cards to Done list
for card in $(trello card:list -l InProgress --format json | jq -r '.[] | select(.name | contains("Done")) | .id'); do
    trello card:move -i $card \
        --board $BOARD_ID \
        --list DoneListID
done
```

## Integration with Shell Tools

### Using jq for JSON parsing
```bash
# Get all cards assigned to me
trello card:assigned-to --format json | jq '.[] | {name, due}'

# Count open tasks per list
for list in $(trello list:list -b $BOARD_ID --format json | jq -r '.[].id'); do
    count=$(trello card:list -l $list --format json | jq '[.[] | select(.closed == false)] | length')
    echo "$count cards in $(trello list:list -b $BOARD_ID --format json | jq -r ".[] | select(.id==\"$list\") | .name")"
done
```

### piping to other tools
```bash
# Create a report of overdue tasks
trello card:assigned-to --format json | \
    jq '[.[] | select(..due != null and .due < now * 1000)]' > \
    overdue-tasks.json
```

## Best Practices

1. **Always use `--format json` for scripting** - Makes parsing predictable
2. **Cache board/list IDs** - Use `trello sync` to build local ID mappings
3. **Handle pagination** - Large boards may need multiple requests
4. **Rate limiting awareness** - Respect Trello's API rate limits (~10 req/sec)
5. **Use environment variables** for sensitive credentials
6. **Test with dry-run flags first** when available
7. **Combine with jq, sed, awk** for powerful text processing pipelines

## Troubleshooting

```bash
# Debug installation issues
trello debug

# Check authentication status
trello auth --help

# View all installed plugins
trello plugins
```

## Examples

### Quick Status Report
```bash
#!/bin/bash
BOARD_ID="your-board-id"
echo "=== Trello Workspace Summary ==="
echo "Boards: $(trello board:list | wc -l)"
echo "Cards in progress: $(trello card:list -l $(trello list:list -b $BOARD_ID --format json | jq -r '.[] | select(.name=="In Progress") | .id') | grep -c '^[a-z]')"
```

### Weekly Digest Email
```bash
# Generate weekly summary
trello card:assigned-to --format json | \
    jq '[.[] | {name, due, tags}]' > weekly-digest.json
mail -s "Weekly Trello Update" team@company.com < weekly-digest.json
```

## Reference

For complete command reference:
- `trello help` - Main help
- `trello <topic> --help` - Topic-specific help (board, card, list, label)
- `trello <command> --help` - Specific command help (e.g., trello board:create --help)