#!/usr/bin/env bash
# Minimal test framework — sourced by each test file.
# No external dependencies required.

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
_CURRENT_SUITE=""

# ── Colours ──────────────────────────────────────────────────────────────────
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[1;33m'
_BLUE='\033[0;34m'
_BOLD='\033[1m'
_NC='\033[0m'

# ── Suite / describe ──────────────────────────────────────────────────────────
describe() {
    _CURRENT_SUITE="$1"
    echo -e "\n${_BOLD}${_BLUE}▶ $1${_NC}"
}

# ── Assertions ────────────────────────────────────────────────────────────────
# Usage: assert_eq  "label" "$actual" "$expected"
assert_eq() {
    local label="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    expected: ${_YELLOW}${expected}${_NC}"
        echo -e "    actual:   ${_YELLOW}${actual}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# assert_contains "label" "$haystack" "needle"
assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    needle:   ${_YELLOW}${needle}${_NC}"
        echo -e "    haystack: ${_YELLOW}${haystack}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# assert_not_contains "label" "$haystack" "needle"
assert_not_contains() {
    local label="$1" haystack="$2" needle="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    unexpected needle: ${_YELLOW}${needle}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# assert_exit_code "label" $actual_code $expected_code
assert_exit_code() {
    local label="$1" actual="$2" expected="$3"
    assert_eq "$label (exit code)" "$actual" "$expected"
}

# assert_file_exists "label" "/path"
assert_file_exists() {
    local label="$1" path="$2"
    if [[ -e "$path" ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    missing: ${_YELLOW}${path}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# assert_symlink "label" "/path"
assert_symlink() {
    local label="$1" path="$2"
    if [[ -L "$path" ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    not a symlink: ${_YELLOW}${path}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# assert_symlink_target "label" "/link" "/expected-target"
assert_symlink_target() {
    local label="$1" link="$2" expected_target="$3"
    local actual_target
    actual_target=$(readlink "$link" 2>/dev/null || echo "")
    assert_eq "$label (symlink target)" "$actual_target" "$expected_target"
}

# assert_dir_exists "label" "/path"
assert_dir_exists() {
    local label="$1" path="$2"
    if [[ -d "$path" ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    missing dir: ${_YELLOW}${path}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# assert_not_exists "label" "/path"
assert_not_exists() {
    local label="$1" path="$2"
    if [[ ! -e "$path" ]]; then
        echo -e "  ${_GREEN}✓${_NC} $label"
        TESTS_PASSED=$(( TESTS_PASSED + 1 ))
    else
        echo -e "  ${_RED}✗${_NC} $label"
        echo -e "    unexpectedly exists: ${_YELLOW}${path}${_NC}"
        TESTS_FAILED=$(( TESTS_FAILED + 1 ))
    fi
}

# skip "reason"
skip() {
    echo -e "  ${_YELLOW}⊘${_NC} SKIPPED: $1"
    TESTS_SKIPPED=$(( TESTS_SKIPPED + 1 ))
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# make_tmp_dir — creates a temp dir and registers cleanup on EXIT
make_tmp_dir() {
    local d
    d=$(mktemp -d)
    # register cleanup unless caller opts out
    trap 'rm -rf '"$d" EXIT
    echo "$d"
}

# run_script SCRIPT [ARGS...] — captures stdout+stderr, sets _RC
# Usage:
#   run_script install-skill.sh --list
#   echo "$_RC"  "$_OUT"
run_script() {
    local script="$1"; shift
    _OUT=$(bash "$script" "$@" 2>&1); _RC=$?; return 0
}

# ── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
    local total=$(( TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED ))
    echo ""
    echo -e "${_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_NC}"
    echo -e "${_BOLD}Results: $total tests${_NC}"
    echo -e "  ${_GREEN}Passed:  $TESTS_PASSED${_NC}"
    [[ $TESTS_FAILED  -gt 0 ]] && echo -e "  ${_RED}Failed:  $TESTS_FAILED${_NC}"
    [[ $TESTS_SKIPPED -gt 0 ]] && echo -e "  ${_YELLOW}Skipped: $TESTS_SKIPPED${_NC}"
    echo -e "${_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_NC}"
    echo ""
    [[ $TESTS_FAILED -eq 0 ]]   # return non-zero if any failures
}
