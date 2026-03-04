#!/bin/bash

# Fetch Tool Test Script
# Tests the fetch tool with various endpoints

set -e

echo "=== Fetch Tool Tests ==="
echo ""

TESTS=(
  "fetch https://jsonplaceholder.typicode.com/posts/1"
  "fetch https://httpbin.org/html"
  "fetch https://example.com"
  "fetch https://www.example.com/.well-known/llmstxt"
)

for test in "${TESTS[@]}"; do
  echo "Running: $test"
  pi -p "$test" 2>&1 | head -50 || echo "[Test failed or timed out]"
  echo "---"
done

echo ""
echo "=== All Tests Complete ==="
