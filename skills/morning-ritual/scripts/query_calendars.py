#!/usr/bin/env python3
"""Unified calendar query — local vault calendars + external ICS feeds.

Reads all configured calendar URLs (Google CalDAV, iCal feeds, etc.) and
local vault calendar files, returning events for today + next N days.

Usage:
    python3 query_calendars.py                     # Today through tomorrow (1 day)
    python3 query_calendars.py --days 7            # Next 7 days total
    python3 query_calendars.py --today-only        # Only today's events
    python3 query_calendars.py --vault /path/to/vault
    python3 query_calendars.py --mode local        # Local-only (no obsidian)
    python3 query_calendars.py --mode external     # External-only (no obsidian)
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections import defaultdict
from datetime import date as dt_date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo

try:
    from urllib.request import urlopen
except ImportError:
    from requests import get as _get
    def urlopen(url):  # type: ignore[no-redef]
        return _get(url).content


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Query calendar sources")
    parser.add_argument("--days", type=int, default=6, help="Days to look ahead (default: 6)")
    parser.add_argument("--today-only", action="store_true", help="Only show today's events")
    parser.add_argument("--vault", type=str, default=os.path.expanduser("~/main_vault"),
                        help="Vault path (default: ~/main_vault)")
    parser.add_argument("--mode", choices=["auto", "local", "external"], default="auto",
                        help="Query mode: auto=try obsidian then fallback, local=file-only, external=ics-only")
    return parser.parse_args()


def has_obsidian_cli() -> bool:
    """Check if obsidian CLI is available."""
    return subprocess.run(["which", "obsidian"], capture_output=True).returncode == 0


def fetch_ics(url: str) -> bytes:
    """Fetch ICS content from a URL."""
    try:
        resp = urlopen(url, timeout=10)
        if isinstance(resp, bytes):
            return resp
        return resp.read()
    except Exception as e:
        print(f"WARNING: Failed to fetch {url}: {e}", file=sys.stderr)
        return b""


def extract_events(ics_data: bytes, start_date: datetime, end_date: datetime) -> list[dict]:
    """Parse ICS data and filter events within the date range.

    Returns a list of event dicts with 'event_date' (date object) for proper
    per-day grouping in the output stage.
    """
    try:
        from icalendar import Calendar
    except ImportError:
        print("ERROR: 'icalendar' package required. Install with: pip install icalendar", file=sys.stderr)
        sys.exit(1)

    berlin = ZoneInfo("Europe/Berlin")
    events: list[dict] = []

    try:
        cal = Calendar.from_ical(ics_data)
    except Exception as e:
        print(f"WARNING: Failed to parse ICS: {e}", file=sys.stderr)
        return events

    for component in cal.walk():
        if component.name != "VEVENT":
            continue

        dtstart = component.get("DTSTART")
        if not dtstart:
            continue

        summary = str(component.get("SUMMARY", "?"))
        location = str(component.get("LOCATION") or "")

        # Normalize start time to Berlin timezone
        raw_dtstart = dtstart.dt
        if isinstance(raw_dtstart, datetime):
            if raw_dtstart.tzinfo is not None:
                dtstart_b = raw_dtstart.astimezone(berlin)
            else:
                dtstart_b = raw_dtstart.replace(tzinfo=berlin)
            event_date = dtstart_b.date()  # date object for per-day grouping
        else:
            # All-day event (date, not datetime)
            dtstart_b = datetime.combine(raw_dtstart, datetime.min.time()).replace(tzinfo=berlin)
            event_date = raw_dtstart

        # Skip if outside range — use the Berlin-normalized datetime for comparison
        start_dt = start_date.replace(tzinfo=None) if start_date.tzinfo else start_date
        end_dt = end_date.replace(tzinfo=None) if end_date.tzinfo else end_date
        dtstart_naive = dtstart_b.replace(tzinfo=None) if dtstart_b.tzinfo else dtstart_b

        if not (start_dt <= dtstart_naive < end_dt):
            continue

        # Get time strings for timed events
        start_time = dtstart_b.strftime("%H:%M")
        dtend = component.get("DTEND")
        end_time = ""
        all_day = False
        if dtend:
            raw_end = dtend.dt
            if isinstance(raw_end, datetime):
                if raw_end.tzinfo is not None:
                    end_dt_b = raw_end.astimezone(berlin)
                else:
                    end_dt_b = raw_end.replace(tzinfo=berlin)
                end_time = end_dt_b.strftime("%H:%M")
            elif isinstance(raw_end, dt_date):
                all_day = True

        events.append({
            "summary": summary,
            "start": start_time if not all_day else "",
            "end": end_time,
            "location": location,
            "all_day": all_day,
            "event_date": event_date,  # date object for grouping
            "source": "external",
        })

    return events


def query_local_calendars_file_based(vault_path: str, start_date: datetime, end_date: datetime) -> list[dict]:
    """Fallback: scan vault markdown files for date-tagged calendar entries."""
    berlin = ZoneInfo("Europe/Berlin")
    calendar_dir = os.path.join(vault_path, "01-Calendars")
    events: list[dict] = []

    if not os.path.isdir(calendar_dir):
        print(f"Warning: Calendar directory not found: {calendar_dir}", file=sys.stderr)
        return events

    today_str = datetime.now(berlin).strftime("%Y-%m-%d")

    for filename in os.listdir(calendar_dir):
        if not filename.endswith(".md") or filename == "00-index.md":
            continue

        filepath = os.path.join(calendar_dir, filename)
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
                # Check if file contains any date in our range
                file_dates = set()
                for i in range((end_date - start_date).days):
                    check_date = (start_date + timedelta(days=i)).strftime("%Y-%m-%d")
                    if check_date in content:
                        file_dates.add(check_date)

                if file_dates:
                    # Extract event details from frontmatter
                    for d in file_dates:
                        # Simple parsing: look for title and time patterns
                        title_match = None
                        for line in content.split("\n"):
                            if line.startswith("title:") or line.startswith("- title:"):
                                title_match = line.split(":", 1)[1].strip().strip('"').strip("'")
                                break

                        if not title_match:
                            title_match = filename.replace(".md", "")

                        # Try to find time info
                        time_match = None
                        for line in content.split("\n"):
                            if "⏰" in line or "time:" in line.lower():
                                time_match = line.strip()
                                break

                        events.append({
                            "summary": title_match or filename,
                            "start": time_match or "",
                            "end": "",
                            "location": "",
                            "all_day": True,
                            "event_date": datetime.strptime(d, "%Y-%m-%d").date(),
                            "source": "local",
                            "file": filename,
                        })
        except Exception as e:
            print(f"Warning: Failed to read {filepath}: {e}", file=sys.stderr)

    return events


def query_external_calendars(vault_path: str, start_date: datetime, end_date: datetime) -> list[dict]:
    """Query external ICS calendars via Obsidian Full Calendar plugin."""
    berlin = ZoneInfo("Europe/Berlin")
    events: list[dict] = []

    # Fetch calendar sources from Full Calendar plugin settings
    try:
        import shlex
        js_code = "JSON.stringify(app.plugins.plugins['obsidian-full-calendar'].settings.calendarSources)"
        cmd_str = f"obsidian eval code={shlex.quote(js_code)}"
        result = subprocess.run(cmd_str, capture_output=True, text=True, timeout=10, shell=True)

        if result.returncode != 0:
            print(f"ERROR: Could not query Full Calendar plugin: {result.stderr.strip()}", file=sys.stderr)
            return events

        # Parse the output (obsidian eval wraps in "=> [...]")
        raw = result.stdout.strip()
        if raw.startswith("=>"):
            raw = raw[2:]
        sources = json.loads(raw)

    except FileNotFoundError:
        print("ERROR: 'obsidian' CLI not found. Is Obsidian running?", file=sys.stderr)
        return events
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return events

    # Query each calendar source and collect events
    all_events_by_date: dict[object, list[dict]] = defaultdict(list)

    for source in sources:
        if source.get("type") != "ical":
            continue  # Skip local calendars (handled by file-based fallback)

        url = source.get("url", "")
        if not url:
            continue

        short_id = url.split("/")[-1][:40]  # Short identifier for display
        ics_data = fetch_ics(url)
        cal_events = extract_events(ics_data, start_date, end_date)

        for e in cal_events:
            e["source_url"] = short_id
            e["source"] = "external"
            all_events_by_date[e["event_date"]].append(e)

    for date, date_events in all_events_by_date.items():
        events.extend(date_events)

    return events


def format_output(events: list[dict], today_str: str, days_ahead: int) -> str:
    """Format events into markdown output sections."""
    # Group by date
    events_by_date: dict[dt_date, list[dict]] = defaultdict(list)
    for e in events:
        events_by_date[e["event_date"]].append(e)

    result_lines: list[str] = []

    # --- Today section ---
    today_events = sorted(events_by_date.get(dt_date.today(), []), key=lambda x: x.get("start", ""))
    if today_events:
        result_lines.append(f"### 📅 Today's Events ({len(today_events)} events)")
        for e in today_events:
            source_tag = f" ({e['source']})" if e['source'] == 'external' else ""
            loc_str = f" — *{e['location']}*" if e["location"] else ""
            if not e["all_day"]:
                result_lines.append(f"- [⏰ {e['start']} – {e['end']}] **{e['summary']}**{loc_str}{source_tag}")
            else:
                result_lines.append(f"- [all-day] **{e['summary']}**{loc_str}{source_tag}")

    # --- Upcoming section (next 5 days, excluding today) ---
    upcoming_dates = sorted(
        d for d in events_by_date.keys() if isinstance(d, dt_date) and str(d) > today_str
    )[:5]

    if upcoming_dates:
        result_lines.append("\n### 🔜 Upcoming Events (Next 5 Days)")
        for date in upcoming_dates:
            day_name = date.strftime("%A, %b %d") if days_ahead > 1 else "Tomorrow"
            result_lines.append(f"\n**{day_name}**")
            events_date = sorted(events_by_date[date], key=lambda x: x.get("start", ""))
            for e in events_date:
                source_tag = f" ({e['source']})" if e['source'] == 'external' else ""
                loc_str = f" — *{e['location']}*" if e["location"] else ""
                if not e["all_day"]:
                    result_lines.append(f"- [⏰ {e['start']} – {e['end']}] **{e['summary']}**{loc_str}{source_tag}")
                else:
                    result_lines.append(f"- [all-day] **{e['summary']}**{loc_str}{source_tag}")

    if result_lines:
        return "\n".join(result_lines)
    return "No calendar events found."


def main() -> None:
    args = parse_args()
    berlin = ZoneInfo("Europe/Berlin")
    now_berlin = datetime.now(berlin)

    if args.today_only:
        start_date = now_berlin.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=1)
    else:
        start_date = now_berlin.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=args.days)

    today_str = now_berlin.strftime("%Y-%m-%d")
    has_cli = has_obsidian_cli()

    all_events: list[dict] = []

    # Determine query mode
    if args.mode == "auto":
        if has_cli:
            # Try obsidian first
            all_events.extend(query_external_calendars(args.vault, start_date, end_date))
        else:
            # Fallback to file-based
            print("[⚠️ Obsidian CLI not found — using file-based fallback]", file=sys.stderr)
            all_events.extend(query_local_calendars_file_based(args.vault, start_date, end_date))
    elif args.mode == "local":
        all_events.extend(query_local_calendars_file_based(args.vault, start_date, end_date))
    elif args.mode == "external":
        if has_cli:
            all_events.extend(query_external_calendars(args.vault, start_date, end_date))
        else:
            print("[⚠️ Obsidian CLI not found — external mode requires obsidian CLI]", file=sys.stderr)

    # Format and print output
    print(format_output(all_events, today_str, args.days))


if __name__ == "__main__":
    main()
