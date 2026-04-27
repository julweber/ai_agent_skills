#!/bin/bash
# Scan raw/ files for missing ingested-at timestamps.
# Usage: scripts/scan_timestamps.sh <wiki-directory-path>
# Exit 0 if clean, 1 if issues found.

WIKI_PATH="$1"
[ -z "$WIKI_PATH" ] && echo "Usage: $0 <wiki-directory-path>" && exit 1

ISSUES=0

while read -r file; do
    if ! grep -q 'ingested-at:' "$file" 2>/dev/null; then
        echo "MISSING_TIMESTAMP:$file"
        ISSUES=$((ISSUES+1))
    fi
done < <(find "$WIKI_PATH/raw" -name "*.md" 2>/dev/null)

[ "$ISSUES" -gt 0 ] && exit 1 || exit 0
