# Morning Ritual Scripts

Scripts for the morning ritual workflow that queries calendars and tasks.

## Scripts

### `morning-briefing.sh`
Main orchestration script. Queries local calendars, external ICS feeds, and collects tasks.

**Usage:**
```bash
./morning-briefing.sh [vault_path] [days_ahead]
# Examples:
./morning-briefing.sh ~/main_vault 5
./morning-briefing.sh /path/to/vault 7
```

**Defaults:**
- Vault: `$HOME/main_vault`
- Days ahead: `5`

### `query_calendars.py`
Unified calendar query — handles local vault calendars + external ICS feeds.

**Usage:**
```bash
python3 query_calendars.py                     # Today through tomorrow (1 day)
python3 query_calendars.py --days 7            # Next 7 days total
python3 query_calendars.py --today-only        # Only today's events
python3 query_calendars.py --vault /path/to/vault
python3 query_calendars.py --mode local        # Local-only (no obsidian)
python3 query_calendars.py --mode external     # External-only (no obsidian)
```

**Dependencies:**
- `icalendar` Python package (`pip install icalendar`)
- `zoneinfo` (Python 3.9+)
- Obsidian CLI (optional, for external calendar queries)

## Fallback Behavior

If the `obsidian` CLI is not available, the scripts fall back to file-based search:
- Local calendars: `grep` for date-tagged markdown files
- Tasks: `find` + `grep` for unchecked task files

## Timezone

All times are normalized to `Europe/Berlin` timezone (CET/CEST).
