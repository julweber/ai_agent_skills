#!/bin/bash

# Fetch Tool Installation Script
# Installs the fetch tool extension to ~/.pi/agent/extensions/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.pi/agent/extensions/fetch-tool"

echo "=== Fetch Tool Installation ==="
echo ""
echo "Source: $SCRIPT_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy files recursively
cp -r "$SCRIPT_DIR/." "$TARGET_DIR/" 2>/dev/null || true

# Install npm dependencies (required for @mozilla/readability, jsdom, node-html-markdown)
echo "Installing npm dependencies…"
cd "$TARGET_DIR"
npm install

echo ""
echo "=== Installation Complete ==="
echo ""
echo "The fetch tool is now available in your pi-coding-agent."
echo ""
echo "Test with:"
echo '  pi --test "fetch https://jsonplaceholder.typicode.com/posts/1"'
echo ''
echo "Or use in code:"
echo '  fetch("https://example.com")'
