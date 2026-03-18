#!/usr/bin/env bash
# Tests for install-extension.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/install-extension.sh"
source "$REPO_ROOT/tests/test_framework.sh"

# ─── fixtures ────────────────────────────────────────────────────────────────
# Pick two real extensions from extensions/pi/
mapfile -t _ALL_EXTS < <(
    find "$REPO_ROOT/extensions/pi" -maxdepth 1 -mindepth 1 -type d \
        -exec test -f {}/index.ts \; -print | xargs -I{} basename {} | sort
)
EXT_A="${_ALL_EXTS[0]}"
EXT_B="${_ALL_EXTS[1]:-}"   # may be empty if only one extension exists

# ─── helpers ─────────────────────────────────────────────────────────────────
run() { run_script "$SCRIPT" "$@"; }

cleanup_dirs=()
register_cleanup() { cleanup_dirs+=("$1"); }
cleanup_all() {
    for d in "${cleanup_dirs[@]:-}"; do [[ -n "$d" ]] && rm -rf "$d"; done
}
trap cleanup_all EXIT

# ─── 1. Help / usage ─────────────────────────────────────────────────────────
describe "install-extension.sh --help"

run --help
assert_exit_code "exits 0"                  "$_RC" "0"
assert_contains  "shows Usage"              "$_OUT" "Usage:"
assert_contains  "documents --all"          "$_OUT" "--all"
assert_contains  "documents --target-dir"   "$_OUT" "--target-dir"
assert_contains  "documents --interactive"  "$_OUT" "--interactive"

# ─── 2. --list ───────────────────────────────────────────────────────────────
describe "install-extension.sh --list"

run --list
assert_exit_code "exits 0"           "$_RC" "0"
assert_contains  "header present"    "$_OUT" "Available Pi Extensions"
assert_contains  "lists $EXT_A"      "$_OUT" "$EXT_A"
assert_contains  "shows total count" "$_OUT" "Total extensions available"

# Each extension should appear on its own line (regression: was joined by spaces)
ext_line_count=$(echo "$_OUT" | grep -c "^$EXT_A" || true)
assert_eq "extension name appears on its own line" "$ext_line_count" "1"

# ─── 3. No action specified fails ────────────────────────────────────────────
describe "install-extension.sh: no action"

run
assert_exit_code "exits non-zero"       "$_RC" "1"
assert_contains  "error mentions --all" "$_OUT" "--all"

# ─── 4. Unknown extension fails ──────────────────────────────────────────────
describe "install-extension.sh: unknown extension name"

TMP=$(mktemp -d); register_cleanup "$TMP"
run --target-dir "$TMP" notanextension
assert_exit_code "exits non-zero"           "$_RC" "1"
assert_contains  "error mentions not found" "$_OUT" "not found"

# ─── 5. --target-dir must exist ──────────────────────────────────────────────
describe "install-extension.sh: --target-dir non-existent path"

run --target-dir /no/such/path "$EXT_A"
assert_exit_code "exits non-zero"           "$_RC" "1"
assert_contains  "error mentions directory" "$_OUT" "does not exist"

# ─── 6. Default install base is $HOME/.pi/agent/extensions ───────────────────
describe "install-extension.sh: default target resolves to \$HOME"

run --list
assert_contains "installation target mentions HOME" "$_OUT" "$HOME/.pi/agent/extensions"

# ─── 7. Symlink install into --target-dir ────────────────────────────────────
describe "install-extension.sh: symlink install into --target-dir"

TMP=$(mktemp -d); register_cleanup "$TMP"
run --target-dir "$TMP" "$EXT_A" --force
assert_exit_code "exits 0"                            "$_RC" "0"
assert_dir_exists "install dir created"               "$TMP/.pi/agent/extensions"
assert_symlink    "$EXT_A is a symlink"               "$TMP/.pi/agent/extensions/$EXT_A"
assert_symlink_target "symlink points to repo source" \
    "$TMP/.pi/agent/extensions/$EXT_A" \
    "$REPO_ROOT/extensions/pi/$EXT_A"

# Verify index.ts is reachable through the symlink
assert_file_exists "index.ts reachable via symlink" "$TMP/.pi/agent/extensions/$EXT_A/index.ts"

# ─── 8. Multiple extensions in one invocation ────────────────────────────────
describe "install-extension.sh: multiple extensions"

if [[ -z "$EXT_B" ]]; then
    skip "only one extension available in repo"
else
    TMP=$(mktemp -d); register_cleanup "$TMP"
    run --target-dir "$TMP" "$EXT_A" "$EXT_B" --force
    assert_exit_code "exits 0"          "$_RC" "0"
    assert_symlink   "$EXT_A installed" "$TMP/.pi/agent/extensions/$EXT_A"
    assert_symlink   "$EXT_B installed" "$TMP/.pi/agent/extensions/$EXT_B"
fi

# ─── 9. --all installs every extension ───────────────────────────────────────
describe "install-extension.sh: --all installs all extensions"

TMP=$(mktemp -d); register_cleanup "$TMP"
run --target-dir "$TMP" --all --force
assert_exit_code "exits 0" "$_RC" "0"

for ext_name in "${_ALL_EXTS[@]}"; do
    assert_symlink "extension $ext_name installed" "$TMP/.pi/agent/extensions/$ext_name"
done

# ─── 10. Idempotent re-install ───────────────────────────────────────────────
describe "install-extension.sh: idempotent re-install"

TMP=$(mktemp -d); register_cleanup "$TMP"
run --target-dir "$TMP" "$EXT_A" --force
run --target-dir "$TMP" "$EXT_A" --force
assert_exit_code "second install exits 0"     "$_RC" "0"
assert_symlink   "symlink still present"      "$TMP/.pi/agent/extensions/$EXT_A"
assert_symlink_target "symlink target unchanged" \
    "$TMP/.pi/agent/extensions/$EXT_A" \
    "$REPO_ROOT/extensions/pi/$EXT_A"

# ─── 11. Stale symlink is replaced ───────────────────────────────────────────
describe "install-extension.sh: stale symlink replaced"

TMP=$(mktemp -d); register_cleanup "$TMP"
mkdir -p "$TMP/.pi/agent/extensions"
ln -s /nonexistent/old "$TMP/.pi/agent/extensions/$EXT_A"

run --target-dir "$TMP" "$EXT_A" --force
assert_exit_code "exits 0 after stale replace"       "$_RC" "0"
assert_symlink   "link is still a symlink"            "$TMP/.pi/agent/extensions/$EXT_A"
assert_symlink_target "link now points to repo" \
    "$TMP/.pi/agent/extensions/$EXT_A" \
    "$REPO_ROOT/extensions/pi/$EXT_A"

# ─── 12. Extension without index.ts is rejected ──────────────────────────────
describe "install-extension.sh: extension missing index.ts is rejected"

TMP=$(mktemp -d); register_cleanup "$TMP"
# Create a fake extension dir without index.ts
FAKE_EXT_DIR="$REPO_ROOT/extensions/pi/_test_fake_ext_$$"
mkdir -p "$FAKE_EXT_DIR"
# no index.ts

set +e
_OUT=$(bash "$SCRIPT" --target-dir "$TMP" "_test_fake_ext_$$" --force 2>&1)
_RC=$?
set -e

rm -rf "$FAKE_EXT_DIR"

assert_exit_code "exits non-zero for invalid extension" "$_RC" "1"
assert_contains  "mentions missing index.ts"            "$_OUT" "index.ts"

# ─── Summary ─────────────────────────────────────────────────────────────────
print_summary
