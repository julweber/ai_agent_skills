---
name: morning-ritual
description: Runs a structured morning work ritual for the user. Pulls open tasks from Obsidian, surfaces what's due today, highlights urgent items, identifies 1-3 focus tasks (MIT), and optionally saves a daily briefing note. Use when the user asks for their morning briefing, daily kickoff, what to work on today, or to start their workday. Activate when the user says "Good morning", "Morning briefing", "Daily Kickoff", "Morning ritual", "Start my day"
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

| Setting | Value |
|---------|-------|
| **Vault path** | `$HOME/main_vault` |
| **Obsidian CLI** | Always use `obsidian --no-sandbox` |
- **Task files**:
  - `00-Tasks/01 - Tasks - Inbox.md` — general inbox (all mixed items)
  - `00-Tasks/10 - Tasks - Beruflich.md` — professional/work tasks
  - `00-Tasks/07 - Tasks - Music.md` — music & creative tasks
  - `00-Tasks/06 - Tasks - Haus.md` — house/personal tasks
  - `00-Tasks/02 - Tasks - Recurring.md` — recurring tasks
  - `00-Tasks/00 - Tasks - Wichtig Urgent.md` — urgent / important items
  - `TODOs - AKTUELL.md` — current high-priority TODOs (root of vault)
  - `Work/HUK/` — work project tasks (HUK subfolder)

## The Morning Ritual Workflow

Run in this order. Be fast — use parallel reads where possible.

### Step 0 - Get current date

```bash
date +%Y-%m-%d
```

### Step 1 — Collect Open Tasks

```bash
obsidian --no-sandbox tasks todo verbose=true format=json
```

Parse the JSON output. Filter only incomplete tasks (lines starting with `- [ ]`).

Group them:
- **🔥 Urgent / High Priority**: tasks with `⏫` or `🔺` or `#urgent` or overdue dates
- **💼 Work**: tasks with `#work`, `#task/work`, or from `10 - Tasks - Beruflich.md`
- **🎵 Music & Creative**: tasks with `#music`, from `07 - Tasks - Music.md`
- **🏠 House & Personal**: tasks with `#haus`, `#task/haus`, from `06 - Tasks - Haus.md`
- **📥 Inbox**: everything else from `01 - Tasks - Inbox.md` not yet categorized

### Step 2 — Check for Due Today / Overdue

Scan for tasks containing today's date (format: `📅 YYYY-MM-DD`) or past dates that haven't been completed.

Flag these as **⚠️ Due Today** or **🚨 Overdue**.

### Step 3 — Pick the MIT (Most Important Tasks)

Based on the collected tasks, suggest **1–3 MIT (Most Important Tasks)** for today. Use this logic:
1. Overdue items first
2. Items marked `⏫` (urgent) or with today's date
3. Work tasks over personal tasks (unless personal items are urgent)
4. Prefer tasks that are actionable (not vague ideas)

Present these as the **"Today's Focus"** block — the 1–3 things the user should commit to finishing today.

### Step 4 — Quick Stats

Show a brief summary:
- Total open tasks (across all files)
- How many are work vs personal vs creative
- Anything overdue

### Step 5 — Optional: Save Daily Briefing

If the user asks to save/log the briefing, create a note:

```bash
obsidian --no-sandbox create name="Daily Briefing YYYY-MM-DD" content="[full briefing content]"
```

Use today's date. Store in the vault root or wherever the user prefers.

## Output Format

```
## ☀️ Morning Briefing — [Day, Date]

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

### 📊 Stats
- Total open: [n] tasks
- Work: [n] | Music: [n] | Personal: [n] | Inbox: [n]
- Overdue: [n]

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
obsidian --no-sandbox tasks:update file="00-Tasks/01 - Tasks - Inbox.md" line=[LINE_NUMBER] status=x
```

Always confirm before marking done.

## Adding a New Task

```bash
obsidian --no-sandbox append file="00-Tasks/01 - Tasks - Inbox.md" content="\n- [ ] [new task text]"
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
