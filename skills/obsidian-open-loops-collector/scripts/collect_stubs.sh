#!/usr/bin/env bash
# collect_stubs.sh - Find stub notes (< 10 non-empty lines) outside archive folders
# Usage: bash collect_stubs.sh [vault_path]
# Output: one relative path per line, sorted by line count ascending

VAULT="${1:-$HOME/main_vault}"

find "$VAULT" -name "*.md" \
  -not -path "*/copilot-conversations/*" \
  -not -path "00-Tasks/Reports/*" \
  -not -path "*/copilot-custom-prompts/*" \
  -not -path "*/Daily Notes/*" \
  -not -path "*/Weekly Notes/*" \
  -not -path "*/Templates/*" \
  -not -path "*/ZZ-Archiv/*" \
  -not -path "*/Evernote Import/*" \
  -not -path "*/Attachments/*" \
  -not -path "*/Chats/*" \
  -not -path "*/.obsidian/*" | \
while IFS= read -r filepath; do
  count=$(grep -c '[^[:space:]]' "$filepath" 2>/dev/null || echo 0)
  re='^[0-9]+$'
  if [[ "$count" =~ $re ]] && [ "$count" -gt 0 ] && [ "$count" -lt 10 ]; then
    relpath="${filepath#$VAULT/}"
    echo -e "$count\t$relpath"
  fi
done | sort -n
