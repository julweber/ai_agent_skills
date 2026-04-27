# Query Workflow — Detailed

## Step 1: Search

Use the wiki's `index.md` as the starting point:
1. Read `20-llm-wikis/<wiki-name>/index.md`.
2. Identify relevant sections (Entities, Concepts, Syntheses) based on the question.
3. Extract candidate pages from the index entries.

Then search within those pages:
1. Use `obsidian search query="<keyword>" file="<path>"` for targeted searches.
2. Use `obsidian backlinks file="<page>"` to find pages that reference a given entity.
3. Read the most relevant pages to gather information.

## Step 2: Synthesize

Answer the question using wiki content as the primary source:
1. Synthesize information from multiple pages if needed.
2. Cite specific pages with wikilinks: `[[Entity Name]]`, `[[Concept Name]]`.
3. If the wiki has insufficient information, state what's missing.
4. Use tables for comparisons, bullet points for lists, callouts for key findings.

## Step 3: Archive

If the answer reveals new insight worth preserving:
1. Propose filing it as a new synthesis page in `wiki/syntheses/`.
2. Use the synthesis page template from `references/ingestion-workflow.md`.
3. Ask the user if they want to create the page.

## Step 4: Report

Concise summary:
```
Query results for <wiki-name>:
- Answer: <brief answer>
- Sources: [[page1]], [[page2]], [[page3]]
- Coverage: Complete / Partial / Insufficient
```
