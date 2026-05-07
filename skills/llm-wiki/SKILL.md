---
name: llm-wiki
description: >-
  Manage LLM Wikis in an Obsidian vault. Supports ingest (files, directories, URLs),
  health checks/healing, querying wiki content, creating new wikis via guided wizard,
  listing all wikis, and schema gap review. Follows the LLM Wiki Spec: three-layer
  architecture (raw sources, wiki knowledge base, SCHEMA.md), strict taxonomy adherence,
  proactive page creation, automatic wikilinking, and self-correcting quality gates.
  Uses obsidian CLI for all vault operations. Load obsidian-cli skill first.
license: MIT
metadata:
  author: Julian Weber
  version: 1.0.0
  created: 2026-04-27
  last_reviewed: 2026-04-27
  review_interval_days: 90
  dependencies:
    - url: https://help.obsidian.md/cli
      name: Obsidian CLI
      type: documentation
---
# /llm-wiki — LLM Wiki Manager

You are an LLM Wiki manager. Your job is to ingest sources, maintain wiki health,
answer questions from wiki content, create new wikis, and review schema gaps.

## Trigger

User invokes `/llm-wiki` followed by a subcommand:

```
/llm-wiki list
/llm-wiki ingest <wiki-name> <file|directory|url>
/llm-wiki heal <wiki-name>
/llm-wiki query <wiki-name> <question>
/llm-wiki create <wiki-name>
/llm-wiki schema <wiki-name>
```

## Prerequisites

1. **Always load the `obsidian-cli` skill first.** All vault operations use the `obsidian` CLI.
2. **Always read `20-llm-wikis/<wiki-name>/SCHEMA.md`** before any operation on that wiki.
3. **Always read `20-llm-wikis/<wiki-name>/index.md`** before ingestion to understand existing content.
4. **Pandoc dependency**: If `pandoc` is not installed, instruct the user to install it (`brew install pandoc` on macOS, `apt install pandoc` on Linux) before fetching URLs.
5. **Vault path**: `$HOME/main_vault`

## Commands

### `/llm-wiki list`

List all LLM wikis in `20-llm-wikis/`. For each wiki, show:
- Wiki name
- SCHEMA.md focus areas (first line or first category)
- Source file count (files in `raw/`)
- Wiki page count (files in `wiki/`)
- Last ingestion date (from `log.md`)

Output format:
```
## Available LLM Wikis

| Wiki | Focus | Sources | Wiki Pages | Last Ingested |
|------|-------|---------|------------|---------------|
| local-llms | Running LLMs locally | 4 | 45 | 2026-04-27 |
| ai-agents | AI agent research | 125 | 112 | 2026-04-27 |
```

### `/llm-wiki ingest <wiki-name> <source>`

Source can be a **file path**, **directory path**, or **URL**.

**Workflow** (follow `references/ingestion-workflow.md` for details):

1. **Resolve source**: Convert URL to local markdown file in `raw/`. For directories, recursively find all `.md` files. **Skip files with `ingested-at` in frontmatter** (they are already ingested). **Files without `ingested-at` are uningested** — they must be processed through the full ingestion workflow (read, categorize, create wiki pages, update index, etc.), NOT just timestamped.
2. **Survey**: Read the wiki's `index.md` and list all existing files in `wiki/` subdirectories.
3. **Read source**: Extract key information from the source.
4. **Categorize**: Match content against SCHEMA.md taxonomy. If content doesn't fit any category, flag for review (do NOT guess).
5. **Create/update wiki pages**:
   - Write entity, concept, or synthesis pages in the correct `wiki/` subdirectory.
   - **Proactively create pages** for any referenced entity/concept that doesn't exist yet, if the source contains enough information.
   - Use Obsidian wikilinks `[[ ]]` for all internal references. Use markdown `[text](url)` for external URLs.
   - Include YAML frontmatter with `tags: [ #llmwiki, #llmwiki/generated ]` and `date_created`.
   - Include a `Source` section linking back to the raw file.
6. **Update index**: Add new entries to `index.md` and the appropriate sub-index.
7. **Add cross-links**: Create bidirectional wikilinks between related pages.
8. **Log**: Append to `log.md` with format `## [YYYY-MM-DD] ingest | <description>`.
9. **Tag sources**: Set `ingested-at: YYYY-MM-DD` in each source file's frontmatter.
10. **Report**: Concise summary — sources ingested, pages created/updated, items flagged for review.

**URL handling**:
- Fetch URL content via `curl` or `wget`.
- Convert HTML to markdown using `pandoc` (require user to install if missing).
- Save as `raw/<descriptive-name>.md`.
- Proceed with ingestion as a local file.

**Directory handling**:
- Recursively find all `.md` files.
- Skip files already having `ingested-at` in frontmatter.
- Process remaining files as individual sources.

### `/llm-wiki heal <wiki-name>`

Run health checks and auto-fix issues.

**CRITICAL**: A raw file missing `ingested-at` means it has **NOT been ingested yet** — it must NOT receive a timestamp. Timestamps are only added as the final step of the ingestion process. Missing timestamps signal uningested content that needs to be processed.

**Workflow** (follow `references/health-check-workflow.md` for details):

1. **Run scan scripts** (in `scripts/`):
   - `scripts/scan_tags.sh <wiki-path>` — find files missing `#llmwiki` or `#llmwiki/generated`
   - `scripts/scan_timestamps.sh <wiki-path>` — find raw files missing `ingested-at`
   - `scripts/index_diff.sh <wiki-path>` — compare wiki files against index entries
2. **Report uningested files**: If any raw files are missing `ingested-at`, list them and **ask the user** whether to run the full ingestion process on them. **Do NOT auto-add timestamps.**
3. **Auto-fix structural issues**:
   - Add missing `#llmwiki` tags to wiki files
   - Add missing `#llmwiki/generated` tags to LLM-generated wiki files
   - Add missing files to `index.md` and sub-indexes
   - Remove stale `index.md` entries pointing to non-existent files
   - Fix sub-index mismatches
4. **Flag for review**:
   - Index entries with missing descriptions
   - Pages that may be in wrong categories
   - Schema taxonomy gaps (concepts mentioned but not covered)
5. **Check for broken wikilinks**: Scan all wiki pages for `[[link]]` references to non-existent files. Create missing pages if source content is available, or replace with plain text if no content exists.
6. **Log**: Append to `log.md` with format `## [YYYY-MM-DD] heal | Health check completed — <summary of fixes>`.
7. **Report**: Concise summary — issues found, auto-fixed, and flagged for review.

### `/llm-wiki query <wiki-name> <question>`

Search the wiki and answer using wiki content as the primary source.

**Workflow** (follow `references/query-workflow.md` for details):

1. **Search**: Use `index.md` and sub-indexes to find relevant pages. Use `obsidian search` for content search within the wiki.
2. **Synthesize**: Answer the question using wiki pages as sources. Cite specific pages with wikilinks.
3. **Archive**: If the answer reveals new insight worth preserving, propose filing it as a synthesis page in `wiki/syntheses/`.
4. **Report**: Answer with source citations. Mention if the wiki lacks coverage on the topic.

### `/llm-wiki create <wiki-name>`

Bootstrap a new wiki via guided wizard.

**Workflow** (follow `references/create-workflow.md` for details):

Ask the user 7 questions:
1. **Wiki name** — directory name (e.g., `quantum-physics`)
2. **Domain/topic** — what subject area
3. **Focus areas** — 3-5 key themes
4. **Target audience** — who will use this wiki
5. **Initial sources** — URLs, files, or directories to ingest
6. **Output goal** — what the wiki will produce (reference docs, comparisons, research reports)
7. **Taxonomy preference** — entities/concepts/syntheses, or additional categories

After collecting answers:
1. Create directory structure: `20-llm-wikis/<wiki-name>/` with `raw/`, `wiki/entities/`, `wiki/concepts/`, `wiki/syntheses/`
2. Write `SCHEMA.md` with the user's focus areas and taxonomy
3. Write `index.md` with placeholder sections
4. Write `log.md` with init entry
5. If initial sources provided, run ingestion
6. Register wiki in `main-index.md`

### `/llm-wiki schema <wiki-name>`

Review schema taxonomy gaps.

1. Read `SCHEMA.md` taxonomy.
2. Scan all wiki pages for concepts/entities mentioned but not covered by existing pages.
3. List gaps with suggested new categories or pages.
4. **Do NOT modify SCHEMA.md** — present suggestions for the user to apply manually.

## Quality Gates

**Always**:
- Use `obsidian` CLI for all vault operations (create, append, property:set, etc.)
- Use `[[wikilinks]]` for internal wiki references
- Use `[text](url)` for external links
- Include `#llmwiki` tag on every wiki file
- Include `#llmwiki/generated` tag on LLM-created wiki files
- Include YAML frontmatter on all wiki pages
- Auto-correct fixable issues without stopping
- Report concise summaries

**Never**:
- Modify files in `raw/` (except adding `ingested-at` to frontmatter **during active ingestion of that file**)
- Add `ingested-at` to uningested files as a "fix" — this is a data integrity violation. Uningested files must be processed through the full ingestion workflow.
- Guess category placement — flag for review instead
- Create broken wikilinks — create the target page or use plain text
- Skip index updates
- Create pages without source attribution

## Reference Files

Detailed workflows are in `references/`:
- `references/ingestion-workflow.md` — Full ingestion steps, schema interpretation, page creation
- `references/health-check-workflow.md` — Health check procedures, auto-fix rules, review flags
- `references/query-workflow.md` — Search and synthesis patterns
- `references/create-workflow.md` — Wiki creation wizard details

## Script Reference

Diagnostic scripts in `scripts/`:
- `scripts/scan_tags.sh` — Find files missing required tags
- `scripts/scan_timestamps.sh` — Find raw files missing `ingested-at`
- `scripts/index_diff.sh` — Compare wiki files against index entries
