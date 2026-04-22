# Obsidian Vault Structure Guide

How Obsidian organizes information and how to navigate it programmatically. Read this before performing any vault operations.

---

## 1. What a Vault Is

A vault is a **regular folder on disk**. Every note is a plain `.md` (Markdown) file. There is no database. If you can read files, you can read a vault.

```
my-vault/                          # The vault root
├── .obsidian/                     # Config folder — DO NOT modify unless administering
├── Notes/                         # User content (structure varies per vault)
│   ├── Projects/
│   ├── Areas/
│   └── Archive/
├── Attachments/                   # Images, PDFs, etc. (folder name varies)
├── Templates/                     # Note templates (folder name varies)
├── Daily Notes/                   # Journal entries (folder name varies)
└── any-note.md                    # Notes can live at any depth
```

**Key facts:**
- Notes can exist at **any folder depth** — there is no required structure
- Folder names and hierarchy are **entirely user-defined**
- The only fixed structure is `.obsidian/` for configuration
- File extensions are always `.md` for notes

---

## 2. Anatomy of a Single Note

Every `.md` file in the vault follows this structure:

```markdown
---
title: My Note Title
tags:
  - project
  - active
aliases:
  - Alt Name
status: in-progress
date: 2026-04-15
priority: 3
---

# Heading 1

Body text with a [[Link to Another Note]] and a #tag.

## Heading 2

More content with an ![[Embedded Note]] and a task:
- [ ] Do this thing
- [x] Already done

Some paragraph with a block reference. ^my-block-id
```

### 2.1 The Three Layers of a Note

Every note has up to three layers of information. You must understand all three:

| Layer | What It Is | Where It Lives | How to Access |
|-------|-----------|----------------|---------------|
| **Properties** (frontmatter) | Structured metadata as YAML | Between `---` delimiters at the very top | `property:read`, `properties` commands |
| **Content** | The markdown body text | Everything after the closing `---` | `read` command |
| **Connections** | Links to/from other notes | `[[wikilinks]]` inside the content | `links`, `backlinks` commands |

### 2.2 Properties (YAML Frontmatter)

The block between `---` at the top of a file. This is **structured data** — treat it like a database row.

**Three special properties recognized by Obsidian core:**
- `tags` — categorization labels (list of strings)
- `aliases` — alternative names for the note (used in search and link autocomplete)
- `cssclasses` — visual styling (irrelevant for programmatic use)

**All other properties are user-defined.** Common ones include:
- `status` — workflow state (e.g., "draft", "active", "done")
- `type` — note classification (e.g., "meeting", "project", "reference")
- `date`, `due`, `created` — temporal markers
- `priority` — numeric or text ranking
- `author`, `source`, `project` — attribution and grouping

**Property types** (vault-wide, stored in `.obsidian/types.json`):

| Type | Example Value | Notes |
|------|--------------|-------|
| text | `"in-progress"` | Strings |
| list | `["tag1", "tag2"]` | Arrays |
| number | `5` | Numeric |
| checkbox | `true` / `false` | Boolean |
| date | `2026-04-15` | YYYY-MM-DD only |
| datetime | `2026-04-15T14:30:00` | ISO 8601 |

### 2.3 Wikilinks (How Notes Connect)

Links use double-bracket syntax. This is how the knowledge graph is built:

```
[[Note Name]]                    → Link to a note by name
[[Note Name|Display Text]]       → Link with different display text
[[Note Name#Heading]]            → Link to a specific heading
[[Note Name#^block-id]]          → Link to a specific block/paragraph
[[Folder/Subfolder/Note]]        → Link with explicit path
```

**Critical behavior:**
- Link resolution is **case-insensitive**
- If a note name is unique in the vault, just the name works (no path needed)
- If multiple notes share a name, Obsidian prefers the one **closest** to the linking file
- Unresolved links (pointing to non-existent files) are valid — they create the file on click

### 2.4 Embeds (Transclusion)

Prefix any link with `!` to embed content inline:
```
![[Note Name]]                   → Embed entire note content
![[Note Name#Heading]]           → Embed one section
![[image.png]]                   → Embed an image
![[document.pdf#page=3]]         → Embed PDF at page 3
```

### 2.5 Tags

Tags mark notes with cross-cutting labels. They appear in two places:

```markdown
---
tags:
  - project
  - meeting/weekly          # Nested tag in frontmatter
---

Inline tags work too: #project #meeting/weekly
```

**Nested tags** use `/` as delimiter: `#parent/child/grandchild`
- Searching for `#parent` matches ALL descendants (`#parent/child`, `#parent/child/sub`)
- This hierarchy is **convention only** — there is no tag definition file

### 2.6 Tasks (Checkboxes)

```markdown
- [ ] Incomplete task (todo)
- [x] Completed task (done)
- [!] Custom status: important
- [?] Custom status: blocked
- [-] Custom status: deferred
```

Tasks are just checklist items inside note content. They are NOT properties.

---

## 3. The Knowledge Graph — How Notes Relate

Obsidian's power comes from **bidirectional links** between notes. Every `[[wikilink]]` creates a connection.

### 3.1 Link Types

```
Note A  ──[[link]]──>  Note B       Outgoing link (from A)
Note B  <──backlink──  Note A       Backlink (to B from A)
```

For any note, you can discover:
- **Outgoing links** — what this note references → `links` command
- **Backlinks** — what references this note → `backlinks` command
- **Unlinked mentions** — notes that mention this note's name as plain text but don't link

### 3.2 Special Link Patterns

| Pattern | Name | Meaning |
|---------|------|---------|
| Note with many backlinks | **Hub** | Central concept, heavily referenced |
| Note with many outgoing links | **MOC / Index** | Curates links to related notes |
| Note with no outgoing links | **Dead end** | Isolated leaf — may need more links |
| Note with no backlinks | **Orphan** | Nothing points to it — hard to discover |
| Link to non-existent note | **Unresolved link** | Target file doesn't exist yet |

### 3.3 How to Traverse the Knowledge Graph

**To understand a topic, follow this pattern:**

1. **Find the entry point** — search for the topic or find a relevant note
2. **Check its outgoing links** — what does this note reference?
3. **Check its backlinks** — what other notes reference this topic?
4. **Follow the most relevant links** — repeat steps 2-3 on connected notes
5. **Look for MOCs or index notes** — these curate links for a topic area

```bash
# Step 1: Find entry point
obsidian search query="machine learning" format=json limit=10

# Step 2: See what it links to
obsidian links file="Machine Learning"

# Step 3: See what links to it
obsidian backlinks file="Machine Learning" counts=true format=json

# Step 4: Read a connected note
obsidian read file="Neural Networks"
```

---

## 4. Common Vault Organization Patterns

Vaults vary widely in structure. Recognize these common patterns to navigate effectively.

### 4.1 PARA Method (Folder-Based)

```
Projects/          # Active work with deadlines
  Project Alpha/
  Website Redesign/
Areas/             # Ongoing responsibilities (no end date)
  Health/
  Finance/
Resources/         # Reference material by topic
  Programming/
  Cooking/
Archive/           # Completed or inactive items
```

**How to navigate:** Use folder paths to scope searches. Projects/ has active work. Archive/ has old stuff.

### 4.2 Zettelkasten (Link-Based, Flat)

```
202604151430 Gradient Descent.md
202604151445 Learning Rate.md
202604151500 Backpropagation.md
MOC - Machine Learning.md
```

**How to navigate:** Notes are atomic (one idea each) and heavily interlinked. Folder structure is minimal. Use MOC notes and backlinks to find related content. Note names often start with timestamps.

### 4.3 Maps of Content (MOCs)

A MOC is a manually curated index note — think of it as a table of contents for a topic:

```markdown
# Machine Learning MOC

## Fundamentals
- [[Linear Regression]]
- [[Gradient Descent]]
- [[Neural Networks]]

## Applications
- [[NLP]]
- [[Computer Vision]]
```

**How to navigate:** If you find a MOC, it's the best starting point for that topic. Its outgoing links ARE the topic's structure.

### 4.4 Daily Notes (Journal Pattern)

```
Daily Notes/
  2026-04-15.md
  2026-04-14.md
  2026-04-13.md
```

Daily notes serve as an **inbox** — raw thoughts, tasks, and links that get organized later. They often contain tasks and references to other notes.

### 4.5 Hub / Home Note

Many vaults have an `Index.md`, `Home.md`, or `Dashboard.md` at the root. This is the user's main entry point — start here to understand the vault's top-level organization.

---

## 5. How to Find Information — Decision Tree

Use this flowchart when you need to find something in a vault:

### 5.1 "I know the note name or topic"
```
→ search query="<topic>" format=json limit=20
→ If found: read the note
→ Check its outgoing links and backlinks for related content
```

### 5.2 "I need all notes about X"
```
→ search query="X" format=json limit=50
→ Also check: tags name="X" verbose=true
→ Also check: backlinks to any note named "X"
→ Count total results first: search query="X" total=true
```

### 5.3 "I want to understand the vault structure"
```
→ vault (get overview stats)
→ files folder="/" ext=".md" format=json (list top-level notes)
→ Look for Index.md, Home.md, Dashboard.md, or MOC notes
→ tags counts=true sort=count format=json (see how content is categorized)
→ properties counts=true format=json (see what metadata exists)
```

### 5.4 "I need to find notes with specific metadata"
```
→ properties format=json (discover what properties exist)
→ search query="status: active" format=json (search for YAML values)
→ For precise property queries, use property:read on candidate files
```

### 5.5 "I want to find related notes"
```
→ Start with a known note
→ links file="<name>" (outgoing connections)
→ backlinks file="<name>" counts=true format=json (incoming connections)
→ Follow the most-linked notes to expand your understanding
```

### 5.6 "I want to find problems or gaps"
```
→ unresolved format=json (broken links)
→ orphans format=json (notes nothing links to)
→ deadends format=json (notes that link to nothing)
```

---

## 6. Tags vs. Properties vs. Links — When to Use What

Understanding when the vault uses each organizational tool:

| Mechanism | Purpose | Example | How to Query |
|-----------|---------|---------|--------------|
| **Folders** | Broad categorization | `Projects/`, `Archive/` | `files folder="Projects/"` |
| **Tags** | Cross-cutting labels | `#meeting`, `#urgent` | `tag name="meeting" verbose=true` |
| **Properties** | Structured metadata | `status: active`, `priority: 3` | `property:read name="status" file="X"` |
| **Links** | Relationships between ideas | `[[Related Concept]]` | `links`, `backlinks` commands |

**Key insight:** A note in `Projects/Alpha/` tagged `#meeting` with property `status: active` that links to `[[Client Requirements]]` uses ALL FOUR mechanisms simultaneously. You may need to query multiple mechanisms to get the full picture.

---

## 7. File System Conventions

### 7.1 File Naming
- Note names ARE the link targets — `My Note.md` is linked as `[[My Note]]`
- Spaces are allowed and common
- Extensions (`.md`) are optional in links
- Some users prefix with dates: `2026-04-15 Meeting Notes.md`
- Zettelkasten users prefix with timestamps: `202604151430 Note.md`

### 7.2 Attachment Handling
- Attachments (images, PDFs) are stored in a configurable folder
- Common locations: `Attachments/`, `assets/`, `_resources/`, or same folder as the note
- Referenced via `![[filename.png]]` embeds

### 7.3 Folders to Skip
When scanning vault content, always skip:
- `.obsidian/` — configuration only
- `.trash/` — Obsidian's soft-delete folder
- `.git/` — version control
- Any folder starting with `.`

### 7.4 The .obsidian/ Configuration Folder

Only relevant for vault administration. Key files:

| File | What It Controls |
|------|-----------------|
| `app.json` | Editor settings, link format, attachment folder location |
| `core-plugins.json` | Which core plugins are enabled |
| `community-plugins.json` | Which community plugins are installed |
| `types.json` | Property type definitions (maps property names to types) |
| `workspace.json` | Current UI state — changes constantly, ignore this |
| `appearance.json` | Theme and visual settings |
| `plugins/<id>/data.json` | Per-plugin settings |

---

## 8. Markdown Syntax Quick Reference

Obsidian extends standard Markdown. Know these extensions:

| Syntax | What It Does |
|--------|-------------|
| `[[Note]]` | Internal link (wikilink) |
| `[[Note\|Text]]` | Internal link with display text |
| `![[Note]]` | Embed another note's content |
| `![[image.png]]` | Embed an image |
| `#tag` | Inline tag |
| `#parent/child` | Nested/hierarchical tag |
| `- [ ] text` | Task (unchecked) |
| `- [x] text` | Task (checked) |
| `==text==` | Highlighted text |
| `%%text%%` | Comment (hidden in preview) |
| `> [!note] Title` | Callout/admonition block |
| `^block-id` | Block reference anchor (at end of paragraph) |
| `$math$` | Inline LaTeX math |
| `$$math$$` | Block LaTeX math |

---

## 9. Common Mistakes to Avoid

1. **Don't assume folder structure.** Every vault is different. Always discover structure first.
2. **Don't ignore properties.** They contain structured metadata that's invisible in plain text search.
3. **Don't ignore backlinks.** The most important connections are often incoming links, not outgoing ones.
4. **Don't modify `.obsidian/` files** unless doing vault administration tasks.
5. **Don't strip frontmatter** when editing notes — properties will be lost.
6. **Don't remove `^block-id` markers** when editing — other notes may reference them.
7. **Don't assume case matters in links** — `[[my note]]` and `[[My Note]]` resolve to the same file.
8. **Don't forget to count results** — always check `total=true` first to know how many results you're dealing with before pulling full lists.
9. **Don't confuse tags and properties.** `tags:` in frontmatter is a property. `#tag` in body is inline. Both are merged in the tag index, but they are queried differently.
10. **Don't search only by text.** Use multiple strategies: text search, tag lookup, property read, link traversal. Information may be encoded in any of these.

---

## 10. Step-by-Step: First Contact with an Unknown Vault

When you encounter a vault for the first time, follow this sequence:

```bash
# 1. Get vault overview
obsidian vault

# 2. See top-level folder structure
obsidian files ext=".md" format=json

# 3. Look for entry points (home/index/dashboard notes)
obsidian search query="MOC" format=json limit=10
obsidian search query="Index" format=json limit=10
obsidian search query="Dashboard" format=json limit=10

# 4. Understand the tagging system
obsidian tags counts=true sort=count format=json

# 5. Understand what properties are in use
obsidian properties counts=true sort=count format=json

# 6. Check vault health
obsidian unresolved total=true
obsidian orphans total=true
obsidian deadends total=true

# 7. Read a hub note with many backlinks to understand central topics
# (pick from step 3 results, or find via high backlink counts)
obsidian read file="<hub-note>"
obsidian backlinks file="<hub-note>" counts=true format=json
```

After this sequence, you will understand:
- How big the vault is
- How it's organized (folders, tags, properties)
- What the main topics are
- Where the entry points are
- What the health of the link graph looks like
