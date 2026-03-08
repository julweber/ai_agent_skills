---
name: obsidian-open-loops-collector
description: Collects and presents all open loops from the Obsidian vault for GTD-style reflection. Aggregates open tasks from 00-Tasks/, dangling thoughts (notes containing TODO/idea/later/?), and stub notes (< 10 lines). Use when the user asks for an open loops review, GTD sweep, what's unfinished, or wants to clear their mental backlog.
---

# Open Loops Collector

Performs a full GTD-style sweep of the vault and presents a consolidated view of everything unfinished, dangling, or half-baked.

## Vault Layout (this user's specific setup)

- **Tasks**: `00-Tasks/` folder — structured task files per domain
  - `01 - Tasks - Inbox.md` — general inbox
  - `06 - Tasks - Haus.md` — house/home tasks
  - `07 - Tasks - Music.md` — music production tasks
  - `10 - Tasks - Beruflich.md` — professional tasks
  - `TODOs - AKTUELL.md` — current high-priority TODOs
  - `Work/HUK/` — work project tasks (HUK)
- **Vault path**: `/home/verfeinerer/main_vault`
- **Obsidian CLI**: always use `obsidian --no-sandbox`

## Workflow: Three-Pass Collection

Run all three passes, then synthesize into one structured report.

### Pass 1 — Open Tasks

```bash
# Get total count
obsidian --no-sandbox tasks todo total=true

# Get all open tasks grouped by file
obsidian --no-sandbox tasks todo verbose=true format=json
```

Parse JSON output. Group tasks by domain:
- **Inbox / Urgent**: files in `00-Tasks/`
- **Work**: files in `Work/`
- **Music / Creative**: files in `03-denkfabrik/` or `07 - Tasks - Music`
- **House / Personal**: `06 - Tasks - Haus`, `Privat/`, etc.
- **Projects**: everything else

Show top items per group (max 5-7 per group). Skip recurring tasks (`🔁`) in the main list — note them separately.

### Pass 2 — Dangling Thoughts (keyword search)

Run these four searches and deduplicate results (a note may appear in multiple):

```bash
obsidian --no-sandbox search query="TODO" format=json limit=30
obsidian --no-sandbox search query="idea" format=json limit=30
obsidian --no-sandbox search query="later" format=json limit=20
obsidian --no-sandbox search query="?" format=json limit=20
```

**Filter out**:
- Files already in `00-Tasks/` (covered in Pass 1)
- Files in `copilot-conversations/`, `ZZ-Archiv/`, `Evernote Import/`
- Lyrics files (`03-denkfabrik/Lyrics/`)

Present as a deduplicated list of notes with dangling content. For each, read a snippet to show *what* is dangling:
```bash
obsidian --no-sandbox search:context query="TODO" limit=5 format=json
```

### Pass 3 — Stub Notes (incomplete / abandoned)

```bash
bash /home/verfeinerer/.pi/agent/skills/open-loops-collector/scripts/collect_stubs.sh /home/verfeinerer/main_vault
```

This returns lines like: `3\tSome Note.md`

Group stubs by folder/domain. Highlight any stubs that look like project or idea notes (not just reference stubs). Read the content of interesting-looking ones:
```bash
obsidian --no-sandbox read file="Note Name"
```

## Output Format

Present the final report as a structured markdown summary:

```
## 🔁 Open Loops Report — [today's date]

### 📋 Open Tasks ([total count])

**Inbox & Urgent** ([n] tasks)
- [ ] task text — *[file]*
...

**Work** ([n] tasks)
- ...

**Music & Creative** ([n] tasks)
- ...

**House & Personal** ([n] tasks)
- ...

**Other Projects** ([n] tasks)
- ...

---

### 💭 Dangling Thoughts ([n notes])

Notes containing open questions or ideas not yet captured as tasks:
- **Note Name** — "the dangling snippet..."
- ...

---

### 🗒️ Stub Notes ([n stubs])

Incomplete notes that may need attention or archiving:
- **Note Name** (n lines) — consider: develop or archive?
- ...

---

### 🎯 Suggested Next Actions

Based on the above, suggest 3-5 concrete next actions the user could take to close the most impactful loops.
```

## Interaction Patterns

After presenting the report, offer:
1. **"Dive in"** — read any specific note in full
2. **"Close it"** — mark tasks as done, move note to archive
3. **"Capture it"** — turn a dangling thought into a proper task
4. **"Save report"** — write the report as a note in the vault

To save the report:
```bash
obsidian --no-sandbox create name="Open Loops Report [DATE]" content="[report content]"
```

## Performance Notes

- Total open tasks is typically ~328 — fetch all at once with `format=json`, parse client-side
- Stub script runs locally and is fast (~2s)
- Dangling thought searches: run all 4 in sequence, deduplicate by filename
- Skip `format=json` parsing errors by extracting with regex: `\[.*\]` (DOTALL)
