#!/usr/bin/env bash
# GitLab CI/CD Skill Installer
# Auto-detects platform and installs the skill

set -euo pipefail

SKILL_NAME="gitlab-ci-cd"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Platform detection
detect_platforms() {
    local platforms=()

    if [ -d "$HOME/.claude" ]; then
        platforms+=("claude-code")
    fi
    if [ -d ".cursor" ] || [ -d "$HOME/.cursor" ]; then
        platforms+=("cursor")
    fi
    if [ -d ".github" ]; then
        platforms+=("copilot")
    fi
    if [ -d ".windsurf" ] || [ -d "$HOME/.windsurf" ]; then
        platforms+=("windsurf")
    fi
    if [ -d ".clinerules" ]; then
        platforms+=("cline")
    fi
    if [ -d "$HOME/.gemini" ]; then
        platforms+=("gemini")
    fi
    if [ -d ".kiro" ]; then
        platforms+=("kiro")
    fi
    if [ -d ".trae" ]; then
        platforms+=("trae")
    fi
    if [ -d ".roo" ]; then
        platforms+=("roo-code")
    fi
    if [ -d "$HOME/.config/goose" ]; then
        platforms+=("goose")
    fi
    if [ -d "$HOME/.config/opencode" ]; then
        platforms+=("opencode")
    fi
    if [ -d "$HOME/.agents" ] || [ -d ".agents" ]; then
        platforms+=("universal")
    fi

    echo "${platforms[@]}"
}

# Get install path for a platform
get_install_path() {
    local platform="$1"
    case "$platform" in
        claude-code) echo "$HOME/.claude/skills/$SKILL_NAME" ;;
        cursor)      echo ".cursor/rules/$SKILL_NAME" ;;
        copilot)     echo ".github/skills/$SKILL_NAME" ;;
        windsurf)    echo ".windsurf/rules/$SKILL_NAME" ;;
        cline)       echo ".clinerules/$SKILL_NAME" ;;
        gemini)      echo "$HOME/.gemini/skills/$SKILL_NAME" ;;
        kiro)        echo ".kiro/skills/$SKILL_NAME" ;;
        trae)        echo ".trae/rules/$SKILL_NAME" ;;
        roo-code)    echo ".roo/rules/$SKILL_NAME" ;;
        goose)       echo "$HOME/.config/goose/skills/$SKILL_NAME" ;;
        opencode)    echo "$HOME/.config/opencode/skills/$SKILL_NAME" ;;
        universal)   echo "$HOME/.agents/skills/$SKILL_NAME" ;;
        *)           log_error "Unknown platform: $platform"; return 1 ;;
    esac
}

# Install to a single platform
install_to() {
    local platform="$1"
    local target
    target=$(get_install_path "$platform")

    log_info "Installing to $platform ($target)..."

    mkdir -p "$(dirname "$target")"
    rm -rf "$target"
    cp -R "$SKILL_DIR" "$target"

    log_ok "Installed to $platform"
}

# Show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --platform <name>   Install to specific platform"
    echo "  --all               Install to all detected platforms"
    echo "  --dry-run           Show what would be installed without doing it"
    echo "  --help              Show this help"
    echo ""
    echo "Supported platforms:"
    echo "  claude-code, cursor, copilot, windsurf, cline,"
    echo "  gemini, kiro, trae, roo-code, goose, opencode, universal"
}

# Main
DRY_RUN=false
SPECIFIC_PLATFORM=""
INSTALL_ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --platform)
            SPECIFIC_PLATFORM="$2"
            shift 2
            ;;
        --all)
            INSTALL_ALL=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -n "$SPECIFIC_PLATFORM" ]; then
    target=$(get_install_path "$SPECIFIC_PLATFORM")
    if [ "$DRY_RUN" = true ]; then
        log_info "Would install to: $target"
    else
        install_to "$SPECIFIC_PLATFORM"
    fi
elif [ "$INSTALL_ALL" = true ]; then
    platforms=$(detect_platforms)
    if [ -z "$platforms" ]; then
        log_warn "No platforms detected. Installing to universal path."
        platforms="universal"
    fi

    for platform in $platforms; do
        if [ "$DRY_RUN" = true ]; then
            target=$(get_install_path "$platform")
            log_info "Would install to $platform: $target"
        else
            install_to "$platform"
        fi
    done
else
    # Auto-detect and install
    platforms=$(detect_platforms)
    if [ -z "$platforms" ]; then
        log_warn "No platforms detected. Installing to universal path."
        platforms="universal"
    fi

    log_info "Detected platforms: $platforms"
    echo ""

    for platform in $platforms; do
        if [ "$DRY_RUN" = true ]; then
            target=$(get_install_path "$platform")
            log_info "Would install to $platform: $target"
        else
            install_to "$platform"
        fi
    done

    echo ""
    log_ok "Skill installed successfully!"
    echo ""
    echo "To use it, open a new session and type:"
    echo ""
    echo "  /gitlab-ci-cd Create a pipeline for my Node.js project"
    echo ""
    echo "Or naturally:"
    echo ""
    echo "  Write a .gitlab-ci.yml for a Python project with tests and Docker"
    echo ""
fi
