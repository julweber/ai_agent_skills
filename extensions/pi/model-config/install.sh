#!/usr/bin/env bash
# Install model-config extension to ~/.pi/agent/extensions/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.pi/agent/extensions/model-config"

echo "Installing model-config extension..."

mkdir -p "$TARGET_DIR"
cp "$SCRIPT_DIR/index.ts" "$TARGET_DIR/index.ts"

echo "Installed to $TARGET_DIR"
echo ""
echo "Reload pi with /reload or restart to activate."
echo ""
echo "Optional: create a config file at ~/.pi/agent/model-config.json"
echo "Example:"
echo '  { "temperature": 0.7, "top_p": 0.9 }'
