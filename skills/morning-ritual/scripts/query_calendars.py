#!/usr/bin/env python3
"""Query ICS calendar sources from Obsidian Full Calendar plugin settings.

Reads all configured calendar URLs (Google CalDAV, iCal feeds, etc.) and returns
events for today + next N days in a format ready to embed into the morning briefing.

Usage:
    python3 query_calendars.py                     # Today through tomorrow (1 day)
    python3 query_calendars.py --days 7            # Next 7 days total
    python3 query_calendars.py --today-only        # Only today's events
"""

from __future__ import annotations

import argparse
import json
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
    parser = argparse.ArgumentParser(description="Query ICS calendar sources")
    parser.add_argument("--days", type=int, default=6, help="Days to look ahead (default: 6)")
    parser.add_argument("--today-only", action="store_true", help="Only show today's events")
    return parser.parse_args()


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
        print(f"WARNING: Failed to parse ICS from {start_date}: {e}", file=sys.stderr)
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
        })

    return events


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

    # Fetch calendar sources from Full Calendar plugin settings
    try:
        import subprocess, shlex
        js_code = "JSON.stringify(app.plugins.plugins['obsidian-full-calendar'].settings.calendarSources)"
        cmd_str = f"obsidian eval code={shlex.quote(js_code)}"
        result = subprocess.run(cmd_str, capture_output=True, text=True, timeout=10, shell=True)

        if result.returncode != 0:
            print(f"ERROR: Could not query Full Calendar plugin: {result.stderr.strip()}", file=sys.stderr)
            sys.exit(1)

        # Parse the output (obsidian eval wraps in "=> [...]")
        raw = result.stdout.strip()
        if raw.startswith("=>"):
            raw = raw[2:]
        sources = json.loads(raw)

    except FileNotFoundError:
        print("ERROR: 'obsidian' CLI not found. Is Obsidian running?", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    # Query each calendar source and collect events grouped by date
    all_events_by_date: dict[object, list[dict]] = defaultdict(list)

    for source in sources:
        if source.get("type") != "ical":
            continue  # Skip local calendars (handled by obsidian-cli separately)

        url = source.get("url", "")
        if not url:
            continue

        short_id = url.split("/")[-1][:40]  # Short identifier for display
        ics_data = fetch_ics(url)
        events = extract_events(ics_data, start_date, end_date)

        for e in events:
            e["source_url"] = short_id
            all_events_by_date[e["event_date"]].append(e)

    # Group by date and format for SKILL.md output
    result_lines: list[str] = []
    today_str = now_berlin.strftime("%Y-%m-%d")

    # --- Today section ---
    if today_str in all_events_by_date:  # type: ignore[operator]
        events_today = sorted(all_events_by_date[today_str], key=lambda x: x.get("start", ""))  # type: ignore[index]
        result_lines.append(f"### 📅 Today's External Events ({len(events_today)} events)")
        for e in events_today:
            loc_str = f" — *{e['location']}*" if e["location"] else ""
            if not e["all_day"]:
                result_lines.append(f"- [⏰ {e['start']} – {e['end']}] **{e['summary']}**{loc_str}")
            else:
                result_lines.append(f"- [all-day] **{e['summary']}**{loc_str}")

    # --- Upcoming section (next 5 days, excluding today) ---
    upcoming_dates = sorted(
        d for d in all_events_by_date.keys() if isinstance(d, dt_date) and str(d) > today_str
    )[:5]

    if upcoming_dates:
        result_lines.append("\n### 🔜 Upcoming External Events (Next 5 Days)")
        for date in upcoming_dates:
            day_name = date.strftime("%A, %b %d") if args.days > 1 else "Tomorrow"
            result_lines.append(f"\n**{day_name}**")
            events_date = sorted(all_events_by_date[date], key=lambda x: x.get("start", ""))  # type: ignore[index]
            for e in events_date:
                loc_str = f" — *{e['location']}*" if e["location"] else ""
                if not e["all_day"]:
                    result_lines.append(f"- [⏰ {e['start']} – {e['end']}] **{e['summary']}**{loc_str}")
                else:
                    result_lines.append(f"- [all-day] **{e['summary']}**{loc_str}")

    # Print the formatted output for embedding in SKILL.md briefing
    if result_lines:
        print("\n".join(result_lines))
    else:
        print("No external calendar events found.")


if __name__ == "__main__":
    main()
