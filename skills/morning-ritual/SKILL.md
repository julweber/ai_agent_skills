---
name: morning-ritual
description: Use when starting your workday with a structured Obsidian task briefing - automatically loads obsidian-cli and obsidian-markdown skills to parse vault tasks, surface urgent/due items, and identify 1-5 MIT focus tasks. Triggers on "Good morning", "Morning briefing", "Daily Kickoff", "What should I work on today"
---

# Morning Ritual Workflow

A daily work kickoff ritual that surfaces what matters most and helps the user start with intention and clarity — not chaos.

## When to Use

Activate when the user says things like:
- "Good morning" / "Morning briefing"
- "What should I work on today?"
- "Start my day" / "Daily kickoff"
- "What's on my plate?"
- "Morning ritual"

## Vault Configuration

| Setting          | Value              |
| ------------------| --------------------|
| **Vault path**   | `$HOME/main_vault` |
| **Obsidian CLI** | `obsidian`         |
- **Main Task directory**:
  - `00-Tasks/*.md` — categorized task definitions

## The Morning Ritual Workflow
Run in this order. Be fast — use parallel reads where possible.

### Step 0 - Load Obsidian CLI Skills first
- If you have the `obsidian-cli` agent skill: load the `obsidian-cli` skill
- If you have the `obsidian-master` agent skill: load the `obsidian-master` skill

### Step 1 - Get current date

```bash
date +%Y-%m-%d
```

### Step 2 — Query Calendar Events

Query all calendar sources: local vault calendars and external ICS/CalDAV feeds.

#### Part A — Local Vault Calendars (`01-Calendars`)

**Important:** The Obsidian CLI's `search` command interprets `field:value` as a property filter, so search for the **date value directly** (e.g., `2026-04-30`) rather than the frontmatter key.

```bash
# Get today's date and the next 5 days
TODAY=$(date +%Y-%m-%d)
TOMORROW=$(date -d "+1 day" +%Y-%m-%d)
DAY2=$(date -d "+2 days" +%Y-%m-%d)
DAY3=$(date -d "+3 days" +%Y-%m-%d)
DAY4=$(date -d "+4 days" +%Y-%m-%d)
DAY5=$(date -d "+5 days" +%Y-%m-%d)

# Search for event files matching each date value in the calendar folder
obsidian search query="$TODAY" path="01-Calendars" format=json
obsidian search query="$TOMORROW" path="01-Calendars" format=json
obsidian search query="$DAY2" path="01-Calendars" format=json
obsidian search query="$DAY3" path="01-Calendars" format=json
obsidian search query="$DAY4" path="01-Calendars" format=json
obsidian search query="$DAY5" path="01-Calendars" format=json
```

For each file found (excluding `00-index.md`), read its content to extract event details:

```bash
obsidian read path="01-Calendars/<filename>"
```

Parse the frontmatter to extract:
- `title` — event name
- `date` — event date (verify it matches the search date)
- `startTime` / `endTime` — time range (if `allDay: false`)
- `allDay` — whether it's an all-day event
- Any additional body content (e.g., location, notes)



#### Part B — External ICS/CalDAV Calendars

Query Google Calendar, iCloud, or any other calendar source connected to the Full Calendar plugin:

```bash
# Option 1: Use the reusable script (recommended)
python3 "$HOME/main_vault/.pi/skills/morning-ritual/scripts/query_calendars.py" --days 7

# Option 2: Query directly via obsidian eval + Python
obsidian eval code="JSON.stringify(app.plugins.plugins['obsidian-full-calendar'].settings.calendarSources)"
# → Returns array of {type, url} objects. Filter for type='ical' and fetch with curl/python.
```

The script (`scripts/query_calendars.py`) automatically:
1. Reads the calendar sources from Full Calendar plugin settings via `obsidian eval`
2. Fetches each ICS URL using Python's `urllib` (with 10s timeout)
3. Parses with `icalendar` library, normalizes to Europe/Berlin timezone
4. Filters events by **actual date** — today vs upcoming
5. Returns formatted output for today + next N days in a ready-to-embed format

**Important:** The script correctly separates events into "Today" and "Upcoming" sections based on the event's actual start date (normalized to Europe/Berlin timezone). Do not manually merge or re-sort — use the structured output as-is.

**Prerequisites:**
- `pip install icalendar` (usually pre-installed)
- Full Calendar plugin must be running with ICS sources configured
- If `obsidian eval` fails, check that Obsidian is open and the Full Calendar plugin is loaded

#### Merge Local and External Events

**CRITICAL: Do NOT manually merge or re-sort event lists.** The script output is already correctly separated by date. Follow these rules:

1. **Today's Events** — Only include events where the event's actual date (local or external) equals **today's date**. Never include tomorrow's events here, even if they appear in the same script output block.
2. **Upcoming Events** — Only include events for tomorrow through Day 5. Never include today's events here.
3. **Never cross-contaminate**: An event on Apr 30 MUST go under "Tuesday, Apr 30" in Upcoming, NEVER under "Today's Events" on Apr 29.
4. Tag external sources if relevant: e.g., `(Google)`, `(iCloud)`.

When in doubt, trust the script's date-based separation — it already groups by the event's actual start date.

### Step 3 — Collect Open Tasks

```bash
obsidian tasks todo verbose=false format=json
```

Parse the JSON output. Filter only incomplete tasks (lines starting with `- [ ]`).

Group them:
- **🔥 Urgent / High Priority**: tasks with `⏫` or `🔺` or `#urgent` or overdue dates
- **💼 Work**: tasks with `#work`, `#task/work`, or from `10 - Tasks - Beruflich.md`
- **🎵 Music & Creative**: tasks with `#music`, from `07 - Tasks - Music.md`
- **🏠 House & Personal**: tasks with `#haus`, `#task/haus`, from `06 - Tasks - Haus.md`
- **📥 Inbox**: everything else from `01 - Tasks - Inbox.md` not yet categorized

### Step 4 — Check for Due Today / Overdue

Scan for tasks containing today's date (format: `📅 YYYY-MM-DD`) or past dates that haven't been completed.

Flag these as **⚠️ Due Today** or **🚨 Overdue**.

### Step 5 — Pick the MIT (Most Important Tasks)

Based on the collected tasks, suggest **1–5 MIT (Most Important Tasks)** for today. Use this logic:
1. Overdue items first
2. Items marked `⏫` (urgent) or with today's date
3. Work tasks over personal tasks (unless personal items are urgent)
4. Prefer tasks that are actionable (not vague ideas)

Present these as the **"Today's Focus"** block — the 1–5 things the user should commit to finishing today.

### Step 6 — Quick Stats

Show a brief summary:
- Total open tasks (across all files)
- How many are work vs personal vs creative
- Anything overdue

### Step 7 — Optional: Save Daily Briefing

If the user asks to save/log the briefing, create a note:

```bash
obsidian create name="Daily Briefing YYYY-MM-DD" content="[full briefing content]"
```

Use today's date. Store in the vault root or wherever the user prefers.

## Output Format

```
## ☀️ Morning Briefing — [Day, Date]

### 📅 Today's Events ([n events])
- [⏰ HH:MM – HH:MM] **Event Title** — *location/notes*
- [all-day] **Event Title** — *location/notes*

---

### 🎯 Today's Focus (MIT)
1. [Most important task]
2. [Second task]
3. [Third task — optional]

---

### 🚨 Overdue / Due Today ([n items])
- [ ] task — *[file/domain]*
- ...

---

### 💼 Work ([n open])
Top items:
- [ ] task
- ...

### 🎵 Music & Creative ([n open])
Top items:
- [ ] task
- ...

### 🏠 House & Personal ([n open])
Top items:
- [ ] task
- ...

### 📥 Inbox ([n open])
Top items:
- [ ] task
- ...

---

### 🔜 Upcoming Events (Next 5 Days)
**[Day, Date]**
- [⏰ HH:MM – HH:MM] **Event Title** — *location/notes*

**[Day, Date]**
- [⏰ HH:MM – HH:MM] **Event Title** — *location/notes* (Google)

---

### 📊 Stats
- Total open: [n] tasks
- Work: [n] | Music: [n] | Personal: [n] | Inbox: [n]
- Overdue: [n]
- Events this week: [n] (local: [n], external: [n])

---

*Ready to go! Type "done [task]" to mark something complete, or "focus [area]" to dive into a domain.*
```

## Interaction After Briefing

After presenting the briefing, offer these options:
- **"done [task name]"** — mark a task complete via Obsidian CLI
- **"focus work"** / **"focus music"** / **"focus inbox"** — show full list for a domain
- **"add task [text]"** — add a new task to the inbox
- **"save briefing"** — save the briefing as a note
- **"Evening review"** — close the day (summarize what got done, what's still open)
- **"Deeper analysis?"** or **"Full review"** — call `gtd-assistant` for comprehensive view including dangling thoughts and stub notes

## Marking Tasks Done

```bash
# Mark a specific task done in a file
obsidian tasks:update file="00-Tasks/01 - Tasks - Inbox.md" line=[LINE_NUMBER] status=x
```

Always confirm before marking done.

## Adding a New Task

```bash
obsidian append file="00-Tasks/01 - Tasks - Inbox.md" content="\n- [ ] [new task text]"
```

## Evening Review (optional extension)

If the user asks for an evening review:
1. Re-run task collection
2. Compare with morning MIT — were they completed?
3. Present "Wins today" (tasks completed since morning)
4. Show what rolled over
5. Ask: "What's the one thing for tomorrow?"
6. Optionally save an evening note

## Deeper Analysis: Calling `gtd-assistant`

When a user needs more than just daily tasks — perhaps they feel overwhelmed, need to understand their full backlog, or want pattern recognition across their vault:

### Trigger Phrases
- "What's really blocking me?"
- "I need a full review of my vault"
- "Help me understand what's unfinished"
- "Open loops sweep" (or similar GTD terminology)
- "Deeper analysis" after morning briefing
- "Weekly/Monthly review"

### Implementation
When these triggers are detected, switch to the `gtd-assistant` workflow:

> "I'll now run a full GTD sweep using the gtd-assistant skill."

Follow Phase 1 → Phase 2 → Phase 3 as defined in `gtd-assistant`. The current conversation context carries over — no data needs to be passed explicitly.

The `gtd-assistant` will return a more detailed report including:
- All open tasks by domain
- Dangling thoughts from notes
- Stub notes requiring attention
- GTD analysis insights on consolidation opportunities
- Pattern recognition across the vault


## Performance Notes

- Open task count is typically > 300 — always parse with regex `^- \[ \]` for open items
- Use today's date (`date +%Y-%m-%d`) to detect overdue tasks
- Keep the briefing scannable — no walls of text, max 5 items per group shown
- Suggest MIT based on signal (emoji priorities, dates, tags) — don't overthink it