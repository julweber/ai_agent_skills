#!/usr/bin/env bash
# Tests for install-skill.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/install-skill.sh"
source "$REPO_ROOT/tests/test_framework.sh"

# ─── fixtures ────────────────────────────────────────────────────────────────
# Pick two real skills from the repo to use in tests
SKILL_A="dev-brainstorming"
SKILL_B="tmux-coder"

# ─── helpers ─────────────────────────────────────────────────────────────────
run() { run_script "$SCRIPT" "$@"; }

# Fresh isolated tmp dir for each logical test; caller assigns to TMP
fresh_tmp() {
    local d
    d=$(mktemp -d)
    echo "$d"
}

cleanup_dirs=()
register_cleanup() { cleanup_dirs+=("$1"); }

cleanup_all() {
    for d in "${cleanup_dirs[@]:-}"; do
        [[ -n "$d" ]] && rm -rf "$d"
    done
}
trap cleanup_all EXIT

# ─── 1. Help / usage ─────────────────────────────────────────────────────────
describe "install-skill.sh --help"

run --help
assert_exit_code "exits 0" "$_RC" "0"
assert_contains   "shows usage"       "$_OUT" "Usage:"
assert_contains   "documents --agent" "$_OUT" "--agent"
assert_contains   "documents --target-dir" "$_OUT" "--target-dir"
assert_contains   "documents --global"     "$_OUT" "--global"

# ─── 2. --list ───────────────────────────────────────────────────────────────
describe "install-skill.sh --list"

run --list
assert_exit_code "exits 0"            "$_RC" "0"
assert_contains  "shows skill header" "$_OUT" "Available Skills"
assert_contains  "lists $SKILL_A"     "$_OUT" "$SKILL_A"
assert_contains  "lists $SKILL_B"     "$_OUT" "$SKILL_B"
assert_contains  "shows total count"  "$_OUT" "Total skills available"

# ─── 3. Missing --agent fails ────────────────────────────────────────────────
describe "install-skill.sh: missing --agent"

run --skill "$SKILL_A"
assert_exit_code "exits non-zero without --agent" "$_RC" "1"
assert_contains  "error mentions --agent"         "$_OUT" "--agent"

# ─── 4. Unknown agent fails ──────────────────────────────────────────────────
describe "install-skill.sh: unknown agent"

run --agent notanagent --skill "$SKILL_A" --dry-run
assert_exit_code "exits non-zero for unknown agent" "$_RC" "1"
assert_contains  "error mentions unsupported"       "$_OUT" "Unsupported"

# ─── 5. --global and --target-dir are mutually exclusive ─────────────────────
describe "install-skill.sh: --global + --target-dir conflict"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --global --target-dir "$TMP" --skill "$SKILL_A" --dry-run
assert_exit_code "exits non-zero"         "$_RC" "1"
assert_contains  "error mentions conflict" "$_OUT" "mutually exclusive"

# ─── 6. --target-dir must exist ──────────────────────────────────────────────
describe "install-skill.sh: --target-dir non-existent path"

run --agent pi --target-dir /no/such/path --skill "$SKILL_A" --dry-run
assert_exit_code "exits non-zero"           "$_RC" "1"
assert_contains  "error mentions directory" "$_OUT" "does not exist"

# ─── 7. --dry-run respects --target-dir (no files written) ───────────────────
describe "install-skill.sh: --dry-run with --target-dir"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --target-dir "$TMP" --skill "$SKILL_A" --dry-run
assert_exit_code "exits 0"                        "$_RC" "0"
assert_contains  "output mentions DRY-RUN"        "$_OUT" "DRY-RUN"
assert_contains  "output shows skill name"        "$_OUT" "$SKILL_A"
assert_contains  "target path contains tmp dir"   "$_OUT" "$TMP"
assert_not_exists "no directory created under tmp" "$TMP/.pi"

# ─── 8. --dry-run defaults to $PWD (not SCRIPT_DIR) ─────────────────────────
describe "install-skill.sh: --dry-run default target is PWD"

TMP=$(fresh_tmp); register_cleanup "$TMP"
(
    cd "$TMP"
    bash "$SCRIPT" --agent pi --skill "$SKILL_A" --dry-run
) > /tmp/_skill_pwd_test.out 2>&1; _RC=$?
_OUT=$(cat /tmp/_skill_pwd_test.out)
assert_exit_code "exits 0"                           "$_RC" "0"
assert_contains  "target contains PWD not REPO_ROOT" "$_OUT" "$TMP"
assert_not_contains "target does not use REPO_ROOT"  "$_OUT" "$REPO_ROOT/.pi"

# ─── 9. --global resolves to $HOME ───────────────────────────────────────────
describe "install-skill.sh: --global resolves to \$HOME"

run --agent pi --global --skill "$SKILL_A" --dry-run
assert_exit_code "exits 0"                    "$_RC" "0"
assert_contains  "target is under HOME"       "$_OUT" "$HOME/.pi/agent/skills"
assert_not_contains "target is not under tmp" "$_OUT" "/tmp"

# ─── 10. Symlink installation via --target-dir ───────────────────────────────
describe "install-skill.sh: symlink install into --target-dir"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --target-dir "$TMP" --skill "$SKILL_A" --force
assert_exit_code "exits 0"                               "$_RC" "0"
assert_dir_exists "install dir created"                  "$TMP/.pi/skills"
assert_symlink    "skill is a symlink"                   "$TMP/.pi/skills/$SKILL_A"
assert_symlink_target "symlink points to repo skills dir" \
    "$TMP/.pi/skills/$SKILL_A" \
    "$REPO_ROOT/skills/$SKILL_A"

# ─── 11. Copy installation via --target-dir ──────────────────────────────────
describe "install-skill.sh: copy install into --target-dir"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --target-dir "$TMP" --skill "$SKILL_A" --copy --force
assert_exit_code "exits 0"                    "$_RC" "0"
assert_dir_exists "install dir created"       "$TMP/.pi/skills"
assert_dir_exists "skill dir exists"          "$TMP/.pi/skills/$SKILL_A"
assert_file_exists "SKILL.md copied"          "$TMP/.pi/skills/$SKILL_A/SKILL.md"
if [[ -L "$TMP/.pi/skills/$SKILL_A" ]]; then
    echo -e "  ${_RED}✗${_NC} skill dir should be a real copy, not a symlink"
    TESTS_FAILED=$(( TESTS_FAILED + 1 ))
else
    echo -e "  ${_GREEN}✓${_NC} skill dir is a real directory (copy, not symlink)"
    TESTS_PASSED=$(( TESTS_PASSED + 1 ))
fi

# ─── 12. Multiple skills in one invocation ───────────────────────────────────
describe "install-skill.sh: multiple skills"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --target-dir "$TMP" --skill "$SKILL_A" "$SKILL_B" --force
assert_exit_code "exits 0"        "$_RC" "0"
assert_symlink   "$SKILL_A installed" "$TMP/.pi/skills/$SKILL_A"
assert_symlink   "$SKILL_B installed" "$TMP/.pi/skills/$SKILL_B"

# ─── 13. --all installs every skill ─────────────────────────────────────────
describe "install-skill.sh: --all installs all skills"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --target-dir "$TMP" --all --force
assert_exit_code "exits 0" "$_RC" "0"

# Every skill that exists in skills/ should be present
while IFS= read -r -d '' skill_dir; do
    skill_name=$(basename "$skill_dir")
    [[ -f "$skill_dir/SKILL.md" ]] || continue   # skip dirs without SKILL.md
    assert_symlink "skill $skill_name installed" "$TMP/.pi/skills/$skill_name"
done < <(find "$REPO_ROOT/skills" -maxdepth 1 -mindepth 1 -type d -print0)

# ─── 14. Re-install is idempotent (symlink already correct) ──────────────────
describe "install-skill.sh: idempotent re-install"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent pi --target-dir "$TMP" --skill "$SKILL_A" --force
run --agent pi --target-dir "$TMP" --skill "$SKILL_A" --force
assert_exit_code "second install exits 0" "$_RC" "0"
assert_symlink   "symlink still correct"  "$TMP/.pi/skills/$SKILL_A"

# ─── 15. --status with --target-dir ──────────────────────────────────────────
describe "install-skill.sh: --status with --target-dir"

TMP=$(fresh_tmp); register_cleanup "$TMP"

# status on empty target
run --status --agent pi --target-dir "$TMP"
assert_exit_code "exits 0 on empty status" "$_RC" "0"
assert_contains  "reports no installation" "$_OUT" "No installation found"

# install one skill (symlink, the default) then check status
TMP2=$(fresh_tmp); register_cleanup "$TMP2"
run --agent pi --target-dir "$TMP2" --skill "$SKILL_A" --force
run --status --agent pi --target-dir "$TMP2"
assert_exit_code "exits 0 after install" "$_RC" "0"
assert_contains  "shows skill in status"  "$_OUT" "$SKILL_A"
assert_contains  "shows symlink label"    "$_OUT" "symlink"

# ─── 16. supported agent paths ────────────────────────────────────────────────
describe "install-skill.sh: all supported agents resolve correct subpaths"

TMP=$(fresh_tmp); register_cleanup "$TMP"

for agent_name in pi opencode claude codex; do
    run --agent "$agent_name" --target-dir "$TMP" --skill "$SKILL_A" --dry-run
    assert_exit_code "exits 0 for agent $agent_name" "$_RC" "0"
    assert_contains  "output contains $TMP for $agent_name" "$_OUT" "$TMP"
done

describe "install-skill.sh: codex install into --target-dir"

TMP=$(fresh_tmp); register_cleanup "$TMP"
run --agent codex --target-dir "$TMP" --skill "$SKILL_A" --force
assert_exit_code "exits 0" "$_RC" "0"
assert_dir_exists "codex install dir created" "$TMP/.codex/skills"
assert_symlink "codex skill is a symlink" "$TMP/.codex/skills/$SKILL_A"
assert_symlink_target "codex symlink points to repo skills dir" \
    "$TMP/.codex/skills/$SKILL_A" \
    "$REPO_ROOT/skills/$SKILL_A"

# ─── Summary ─────────────────────────────────────────────────────────────────
print_summary
