#!/bin/bash
# Scan all .md files in a wiki for missing required tags.
# Usage: scripts/scan_tags.sh <wiki-directory-path>
# Exit 0 if clean, 1 if issues found.

WIKI_PATH="$1"
[ -z "$WIKI_PATH" ] && echo "Usage: $0 <wiki-directory-path>" && exit 1

ISSUES=0

# Scan wiki/ files for llmwiki tag (YAML frontmatter uses no # prefix)
while read -r file; do
    if ! grep -q 'llmwiki' "$file" 2>/dev/null; then
        echo "MISSING_TAG:$file:llmwiki"
        ISSUES=$((ISSUES+1))
    fi
    if grep -q 'date_created:' "$file" 2>/dev/null && ! grep -q 'llmwiki/generated' "$file" 2>/dev/null; then
        echo "MISSING_TAG:$file:llmwiki/generated"
        ISSUES=$((ISSUES+1))
    fi
done < <(find "$WIKI_PATH/wiki" -name "*.md" -not -name "index.md" -not -name "00-index.md" 2>/dev/null)

# Scan raw/ files for llmwiki tag
while read -r file; do
    if ! grep -q 'llmwiki' "$file" 2>/dev/null; then
        echo "MISSING_TAG:$file:llmwiki"
        ISSUES=$((ISSUES+1))
    fi
done < <(find "$WIKI_PATH/raw" -name "*.md" 2>/dev/null)

[ "$ISSUES" -gt 0 ] && exit 1 || exit 0
