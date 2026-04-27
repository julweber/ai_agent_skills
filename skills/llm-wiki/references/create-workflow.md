# Create Workflow — Detailed

## Step 1: Guided Wizard

Ask the user 7 questions in sequence:

1. **Wiki name** — directory name (e.g., `quantum-physics`). Must be lowercase, hyphens, no spaces.
2. **Domain/topic** — what subject area this wiki covers (1-2 sentences).
3. **Focus areas** — 3-5 key themes (one per line).
4. **Target audience** — who will use this wiki (you, your team, public).
5. **Initial sources** — URLs, files, or directories to ingest right away (optional).
6. **Output goal** — what the wiki will produce (reference docs, comparison matrices, research reports, implementation blueprints).
7. **Taxonomy preference** — entities/concepts/syntheses only, or additional categories (e.g., `guides/`, `reference/`).

## Step 2: Create Directory Structure

```
20-llm-wikis/<wiki-name>/
├── SCHEMA.md
├── index.md
├── log.md
├── raw/
│   └── (sources go here)
└── wiki/
    ├── entities/
    │   └── index.md
    ├── concepts/
    │   └── index.md
    └── syntheses/
        └── index.md
```

If the user specified additional categories (e.g., `guides/`), create them under `wiki/`.

## Step 3: Write SCHEMA.md

```markdown
# Schema: <wiki-name> LLM Wiki

## Project Goal
<Domain/topic from question 2>

## Focus Areas
- <Focus area 1>
- <Focus area 2>
- <Focus area 3>

## Formatting Guidelines
- **Tags**: Every file must include `#llmwiki`. LLM-generated content must include `#llmwiki/generated`.
- **Linking**: Use `[[wikilinks]]` for all entities and concepts.
- **Provenance**: Always link back to the source file in `/raw` when synthesizing information.

## Taxonomy
- `/entities`: Specific models, tools, people, or systems.
- `/concepts`: Theoretical foundations, patterns, and frameworks.
- `/syntheses`: Implementation guides, comparison matrices, and analysis.
<Add additional categories if specified by user>
```

## Step 4: Write index.md

```markdown
# <Wiki Name> Wiki Index

Welcome to the knowledge base for <domain/topic>.

## Concepts
<Placeholder section — will be populated on first ingestion>

## Entities
<Placeholder section — will be populated on first ingestion>

## Syntheses
<Placeholder section — will be populated on first ingestion>
```

## Step 5: Write Sub-indexes

Each sub-index (`wiki/entities/index.md`, `wiki/concepts/index.md`, `wiki/syntheses/index.md`) starts with:
```markdown
# <Category> Index

<Placeholder section>
```

## Step 6: Write log.md

```markdown
# <Wiki Name> Wiki Log

## [YYYY-MM-DD] init | Wiki structure created, SCHEMA and Index initialized.
```

## Step 7: Register in main-index.md

Add the wiki to `main-index.md` under the LLM Wikis section:
```markdown
- [[20-llm-wikis/<wiki-name>/index|<wiki-name>]] — <Brief description from domain/topic>
```

## Step 8: Ingest Initial Sources (if provided)

If the user provided initial sources (URLs, files, directories):
1. Run the ingestion workflow from `references/ingestion-workflow.md`.
2. Process each source through the full ingest pipeline.

## Step 9: Report

Concise summary:
```
Created wiki <wiki-name>:
- Directory structure initialized
- SCHEMA.md written with <n> focus areas
- Registered in main-index.md
- <n> initial sources ingested (if any)
```
