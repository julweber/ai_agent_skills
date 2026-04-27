# Health Check Workflow — Detailed

## Step 1: Run Scan Scripts

Execute the diagnostic scripts from `scripts/` in order. Each returns exit code 0 (clean) or 1 (issues found).

### `scripts/scan_tags.sh <wiki-path>`

Scans all `.md` files in `wiki/` and `raw/` for missing required tags.

**What it checks:**
- `wiki/**/*.md` (excluding `index.md`, `00-index.md`) must have `#llmwiki`
- Files with `date_created:` in frontmatter must also have `#llmwiki/generated`
- `raw/**/*.md` must have `#llmwiki`

**Output format:** `MISSING_TAG:<file>:<required-tag>`

See `scripts/scan_tags.sh` for full implementation.

### `scripts/scan_timestamps.sh <wiki-path>`

Scans all `.md` files in `raw/` for missing `ingested-at` timestamps.

**What it checks:**
- Every `.md` file under `raw/` must have `ingested-at: YYYY-MM-DD` in YAML frontmatter

**Output format:** `MISSING_TIMESTAMP:<file>`

See `scripts/scan_timestamps.sh` for full implementation.

### `scripts/index_diff.sh <wiki-path>`

Compares wiki files against `index.md` and sub-indexes.

**What it checks:**
- Every file in `wiki/entities/`, `wiki/concepts/`, `wiki/syntheses/` vs. main `index.md`
- Every entry in `index.md` vs. actual file existence (flags stale entries)
- `wiki/entities/index.md` vs. `wiki/entities/` files (sub-index sync)
- `wiki/concepts/index.md` vs. `wiki/concepts/` files
- `wiki/syntheses/index.md` vs. `wiki/syntheses/` files

**Output format:**
- `STRUCTURAL_MISMATCH:<path>:<description>` — file exists but not in index
- `STALE_ENTRY:<index-file>:<reference>` — index references non-existent file
- `SUBINDEX_MISMATCH:<sub-index>:<file>` — file not in its sub-index

See `scripts/index_diff.sh` for full implementation.

## Step 2: Auto-Fix Issues

### Missing Tags

For each `MISSING_TAG:<file>:<tag>`:
```bash
obsidian append file="<file>" content="\n## Tags\n#<tag>"
```
If the file already has a `## Tags` section, append the tag to the existing list instead.

### Missing Timestamps

For each `MISSING_TIMESTAMP:<file>`:
```bash
obsidian property:set name="ingested-at" value="YYYY-MM-DD" file="<file>"
```

### Structural Mismatches (files not in index)

For each `STRUCTURAL_MISMATCH:<file> is missing from index.md`:
1. Determine the file's category from its path (`entities/`, `concepts/`, `syntheses/`).
2. Add an entry to `index.md` in the appropriate section.
3. Use the file's title (first `# heading`) as the display name.
4. Write a 1-line summary based on the first paragraph of the file.

### Stale Entries (index points to non-existent file)

For each `STALE_ENTRY:index.md references <target> but file does not exist`:
1. Check if the target is a real wiki page that was deleted, or just a reference to an external entity.
2. If it's a wiki page reference (no URL pattern), remove the entry from `index.md`.
3. If it's an external reference (URL, person name, tool name), keep it but convert to plain text.

### Sub-index Mismatches

For each `SUBINDEX_MISMATCH:<index-file> missing <basename>`:
1. Add the missing entry to the sub-index file.
2. Sync the description from the main `index.md` if available.

## Step 3: Flag for Review

### Missing Descriptions

Check index entries that have no description (just the wikilink, no `: Description`). Flag these.

### Wrong Category Placement

If a page seems to be in the wrong category based on SCHEMA.md:
- Example: A concept page in `entities/` or an entity page in `concepts/`.
- Flag for review, do NOT move automatically.

### Schema Taxonomy Gaps

Scan all wiki pages for concepts/entities mentioned but not covered:
1. Extract all wikilinks from wiki pages.
2. Compare against existing wiki files.
3. Links that don't resolve to any file are potential gaps.
4. For each gap, check if the source content justifies creating a new page.
5. If yes, note it as a suggested new page.
6. If no, note it as a reference to an external entity (acceptable).

## Step 4: Check Broken Wikilinks

Scan all wiki pages for `[[link]]` references:
1. Parse each `[[wikilink]]` from every `.md` file in `wiki/`.
2. Resolve the link to a file path.
3. If the file doesn't exist:
   - **If there's source content available** to create the page → create it proactively (same logic as ingestion).
   - **If no source content** → replace `[[link]]` with plain text `link` (or `[link](url)` if a URL is known).
4. Log all broken link fixes in `log.md`.

## Step 5: Log

Append to `log.md`:
```markdown
## [YYYY-MM-DD] heal | Health check completed — <summary>

### Raw Sources
- <list of tag fixes, timestamp fixes>

### Wiki Pages Created
- <list of pages created for broken links>

### Index Updates
- <list of index fixes>

### Schema Gaps Noted
- <list of taxonomy gaps for review>

### Wiki Status: HEALTHY (or list remaining issues)
```

## Step 6: Report

Concise summary:
```
Healed <wiki-name>:
- <n> tag issues auto-fixed
- <n> timestamp issues auto-fixed
- <n> index mismatches resolved
- <n> broken links fixed (pages created: <n>, replaced with text: <n>)
- <n> schema gaps flagged for review
```
