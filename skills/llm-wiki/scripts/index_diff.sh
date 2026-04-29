#!/bin/bash
# Compare wiki files against index.md entries.
# Usage: scripts/index_diff.sh <wiki-directory-path>
# Exit 0 if clean, 1 if issues found.

WIKI_PATH="$1"
[ -z "$WIKI_PATH" ] && echo "Usage: $0 <wiki-directory-path>" && exit 1

# Build list of all wiki files
find "$WIKI_PATH/wiki" -name "*.md" -not -name "index.md" -not -name "00-index.md" -not -name "log.md" 2>/dev/null | sort > /tmp/wiki-files.txt

# Extract wikilink targets from index.md (handle both [[name]] and [[name|display]])
grep -oP '\[\[([^\]|]+)' "$WIKI_PATH/index.md" 2>/dev/null | sed 's/\[\[//' | sort -u > /tmp/index-targets.txt

# Check for files not in index
while read -r file; do
    basename_noext=$(basename "$file" .md)
    if ! grep -qF "$basename_noext" /tmp/index-targets.txt 2>/dev/null; then
        echo "STRUCTURAL_MISMATCH:$file is missing from index.md"
    fi
done < /tmp/wiki-files.txt

# Check for stale index entries (pointing to non-existent files)
grep -oP '\[\[([^\]|]+)' "$WIKI_PATH/index.md" 2>/dev/null | sed 's/\[\[//' | sort -u | while read -r target; do
    # Skip if target is a URL or external reference
    case "$target" in
        http*|*://*) continue ;;
    esac
    # Check if the file exists in wiki/
    if ! find "$WIKI_PATH/wiki" -name "${target}.md" -not -name "index.md" 2>/dev/null | grep -q .; then
        echo "STALE_ENTRY:index.md references $target but file does not exist"
    fi
done

# Sub-index sync
for subdir in entities concepts syntheses; do
    subdir_path="$WIKI_PATH/wiki/$subdir"
    index_file="$subdir_path/index.md"
    [ -f "$index_file" ] || continue

    find "$subdir_path" -name "*.md" -not -name "index.md" 2>/dev/null | sort > /tmp/subdir-files.txt
    grep -oP '\[\[([^\]|]+)' "$index_file" 2>/dev/null | sed 's/\[\[//' | sort -u > /tmp/subdir-targets.txt

    while read -r file; do
        basename_noext=$(basename "$file" .md)
        if ! grep -qF "$basename_noext" /tmp/subdir-targets.txt 2>/dev/null; then
            echo "SUBINDEX_MISMATCH:$index_file missing $basename_noext"
        fi
    done < /tmp/subdir-files.txt
done
