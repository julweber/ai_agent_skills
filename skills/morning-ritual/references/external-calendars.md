# External ICS/CalDAV Calendar Integration

## Overview

The morning ritual can now query events from external calendars (Google, iCloud, Nextcloud) that are connected to the Obsidian Full Calendar plugin. This is done by reading the plugin's configured `calendarSources` and fetching their ICS feeds directly.

## How It Works

1. The script uses `obsidian eval` to read the Full Calendar plugin settings
2. It filters for sources with `type: "ical"` (external calendars)
3. For each source, it fetches the ICS URL via HTTP
4. Parses the ICS data using Python's `icalendar` library
5. Normalizes all times to Europe/Berlin timezone
6. Filters events for today + next N days

## Script Location

```
scripts/query_calendars.py
```

## Usage

```bash
# Basic: Today through tomorrow (default)
python3 scripts/query_calendars.py

# Custom range
python3 scripts/query_calendars.py --days 7

# Only today's events
python3 scripts/query_calendars.py --today-only
```

## Dependencies

- `icalendar` Python package (`pip install icalendar`)
- Full Calendar plugin must be running in Obsidian
- Internet access to fetch ICS feeds (Google CalDAV URLs)

## Error Handling

The script handles these gracefully:
- Network timeouts (10s per URL) → warns but continues
- Invalid ICS data → skips that calendar, continues
- Missing `obsidian` CLI → exits with error
- No external calendars configured → prints "No external events"

## Adding New Calendar Sources

To add a new Google/iCloud calendar to the morning briefing:

1. Open Obsidian Full Calendar plugin settings
2. Add a new ICS source (paste the public/ICS URL)
3. The script will automatically pick it up on next run

No code changes needed — the script reads whatever sources are configured.

## Timezone Handling

All times are normalized to `Europe/Berlin` timezone (`CET`/`CEST`). This is hardcoded in the script and should match your location. To change:

```python
berlin = ZoneInfo("America/New_York")  # or any other IANA tz
```
