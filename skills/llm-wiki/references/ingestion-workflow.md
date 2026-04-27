# Ingestion Workflow — Detailed

## Step 1: Resolve Source

### File Path
- Resolve relative paths against the vault root (`$HOME/main_vault`).
- Copy or move the file to `20-llm-wikis/<wiki-name>/raw/`.
- If the file already exists in `raw/`, check for `ingested-at`. If present, skip.

### Directory Path
- Recursively find all `.md` files under the directory.
- For each file, check if it already has `ingested-at` in frontmatter.
- Skip files with `ingested-at`. Process remaining files.
- Copy files to `20-llm-wikis/<wiki-name>/raw/`, preserving directory structure if the source has subdirectories.

### URL
1. Check if `pandoc` is installed: `which pandoc`. If not, tell the user:
   ```
   Pandoc is required for URL fetching. Install it:
   - macOS: brew install pandoc
   - Linux: apt install pandoc
   ```
2. Fetch content: `curl -sL <url> > /tmp/llm-wiki-temp.html`
3. Convert to markdown: `pandoc /tmp/llm-wiki-temp.html -f html -t markdown -o <raw-file-path>`
4. Add frontmatter with `source_url` and `ingested-at`.
5. If fetch fails (curl returns non-zero), log the failure and skip.

## Step 2: Survey

Read the wiki's `index.md` to understand:
- Existing entity pages (what's already documented)
- Existing concept pages (what's already covered)
- Existing synthesis pages (what comparisons/analyses exist)
- Source file count and last ingestion date

Also list all files in `wiki/` subdirectories to identify:
- Existing pages that might need updating
- Gaps where new content should fit

## Step 3: Read Source

Extract key information from the source:
- What entities (tools, models, people, systems) are described?
- What concepts (theories, patterns, frameworks) are discussed?
- What syntheses (comparisons, analyses, conclusions) can be drawn?
- What external references (URLs, citations) should be preserved?

## Step 4: Categorize (Strict Taxonomy)

Match extracted information against `SCHEMA.md` taxonomy:

1. **Entities** (`wiki/entities/`): Specific, named things — tools, models, people, hardware, systems.
2. **Concepts** (`wiki/concepts/`): Abstract ideas, theories, patterns, methodologies.
3. **Syntheses** (`wiki/syntheses/`): Comparisons, analyses, conclusions, integration guides.

**If content doesn't fit any category in SCHEMA.md**:
- Do NOT create a page in a guessed category.
- Log the gap: `## [YYYY-MM-DD] schema_gap | Content from <source> does not fit SCHEMA.md taxonomy — <description>`.
- Flag for user review.

**If content fits multiple categories**:
- Choose the primary category based on SCHEMA.md's focus areas.
- Cross-link to related pages in other categories.

## Step 5: Create/Update Wiki Pages

### Entity Page Template
```markdown
---
title: <Entity Name>
date_created: YYYY-MM-DD
source_refs:
  - "20-llm-wikis/<wiki-name>/raw/<source-file>"
tags: [entity, #llmwiki, #llmwiki/generated]
---

# <Entity Name>

<Summary paragraph: what this entity is, why it matters>

## Key Details
<Bullet points or sections for important details>

## Related
- [[related-entity]]
- [[related-concept]]

---

*Generated from <source-file>. Date: YYYY-MM-DD*
```

### Concept Page Template
```markdown
---
title: <Concept Name>
date_created: YYYY-MM-DD
source_refs:
  - "20-llm-wikis/<wiki-name>/raw/<source-file>"
tags: [concept, #llmwiki, #llmwiki/generated]
---

# <Concept Name>

<Summary paragraph: what this concept is, core principles>

## Core Principles
<Bullet points or numbered list>

## Related
- [[related-entity]]
- [[related-concept]]

---

*Generated from <source-file>. Date: YYYY-MM-DD*
```

### Synthesis Page Template
```markdown
---
title: <Synthesis Title>
date_created: YYYY-MM-DD
source_refs:
  - "20-llm-wikis/<wiki-name>/raw/<source-file>"
tags: [synthesis, #llmwiki, #llmwiki/generated]
---

# <Synthesis Title>

<Summary paragraph: what this synthesis covers, key conclusions>

## Analysis
<Detailed analysis sections>

## Related
- [[related-entity]]
- [[related-concept]]

---

*Generated from <source-file>. Date: YYYY-MM-DD*
```

### Proactive Page Creation

When a source references an entity/concept that doesn't have a page:
1. Check if the source contains enough information to write a valid page.
2. If yes, create the page immediately in the correct category.
3. Link to it with `[[wikilink]]`.
4. If the source only mentions the name without substance, note it in the referencing page's "Related" section without creating a page.

### Wikilink Rules

- **Internal wiki references**: Always `[[wikilink]]` — even if the target page doesn't exist yet (create it proactively).
- **External URLs**: Always `[text](url)` — never use wikilinks for external content.
- **Section links**: `[[page#section]]` only if the section exists in the target file.
- **Block links**: `[[page#^block-id]]` only if the block ID exists.
- **Same-note links**: `[[#heading]]` for headings within the same file.

## Step 6: Update Index

Update `index.md`:
- Add new entries to the appropriate section (Entities, Concepts, Syntheses).
- Each entry: `- [[wikilink|Display Name]]: Brief description (1 line)`
- Update `source_refs` in frontmatter with new source paths.
- Update `last_updated` date.
- Update `source_file_count`.

Update the appropriate sub-index:
- `wiki/entities/index.md` — add new entity entries
- `wiki/concepts/index.md` — add new concept entries
- `wiki/syntheses/index.md` — add new synthesis entries

## Step 7: Add Cross-Links

Create bidirectional wikilinks between related pages:
- Entity ↔ Concept (when the entity embodies or uses the concept)
- Entity ↔ Entity (when the entities are related tools/models)
- Concept ↔ Concept (when concepts are related or contrasting)
- Synthesis ↔ Entity/Concept (when the synthesis analyzes specific items)

## Step 8: Log

Append to `log.md`:
```markdown
## [YYYY-MM-DD] ingest | <Brief description of what was ingested>

**Source Files Processed:**
- `<raw-file-1>` — <brief description>
- `<raw-file-2>` — <brief description>

### Wiki Pages Created (<n>):
- `wiki/entities/<name>` — <1-line description>
- `wiki/concepts/<name>` — <1-line description>

### Wiki Pages Updated (<n>):
- `wiki/entities/<name>` — <what was updated>

### Index Updates:
- Updated `index.md` with new entries
- Updated `wiki/entities/index.md` / `wiki/concepts/index.md` / `wiki/syntheses/index.md`

### All source files marked with `ingested-at: YYYY-MM-DD`
```

## Step 9: Tag Sources

Set `ingested-at: YYYY-MM-DD` in each source file's YAML frontmatter:
```bash
obsidian property:set name="ingested-at" value="YYYY-MM-DD" file="<raw-file-path>"
```

If the file has no frontmatter, create one:
```bash
obsidian append file="<raw-file-path>" content="\n---\ningested-at: YYYY-MM-DD\n---\n"
```

## Step 10: Report

Concise summary:
```
Ingested <n> sources into <wiki-name>:
- <n> entity pages created, <n> updated
- <n> concept pages created, <n> updated
- <n> synthesis pages created, <n> updated
- <n> items flagged for review (schema gaps)
```
