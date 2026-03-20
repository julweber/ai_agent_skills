#!/usr/bin/env bash

################################################################################
# install-prompt.sh - Install prompts/slash-commands from prompts/ directory
#
# Discovers prompt files from prompts/*.md files.
# Supports installation to Claude, Codex, Pi, and OpenCode platforms.
# All installations use symbolic links to the source files.
#
# Usage:
#   ./install-prompt.sh --help                        # Show this help message
#   ./install-prompt.sh --list                        # List available prompts
#   ./install-prompt.sh --all                         # Install all prompts
#   ./install-prompt.sh --interactive                 # Interactive wizard
#   ./install-prompt.sh <prompt1> [prompt2]           # Install specific prompt(s)
#   ./install-prompt.sh --force --all                 # Skip confirmation prompts
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

# Installation targets for each platform
CLAUDE_TARGET="${HOME}/.claude/commands"
CODEX_TARGET="${HOME}/.codex/prompts"
PI_TARGET="${HOME}/.pi/agent/prompts"
OPENCODE_TARGET="${HOME}/.opencode/commands"

TARGET_DIR=""            # set via --target-dir (defaults to $HOME)
PLATFORMS=()             # array of selected platforms

# Global flags
PROMPT_NAMES=()
LIST_MODE=false
INTERACTIVE_MODE=false
FORCE_MODE=false
INSTALL_ALL=false

################################################################################
# Utility Functions
################################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}" >&2
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

################################################################################
# Usage
################################################################################

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [PROMPT...]

Install prompts/slash-commands from the prompts/ directory.

ARGUMENTS:
    PROMPT...             One or more prompt names to install (without .md extension)

OPTIONS:
    --all                 Install all available prompts
    --list                List available prompts without installing
    --interactive         Start interactive installation wizard
    --force               Skip confirmation prompts
    --target-dir DIR      Base directory for installs instead of ~
    --help, -h            Show this help message and exit

PLATFORMS:
    Claude    ~/.claude/commands/<prompt>.md        (slash commands)
    Codex     ~/.codex/prompts/<prompt>.md          (custom prompts)
    Pi        ~/.pi/agent/prompts/<prompt>.md       (prompts)
    OpenCode  ~/.opencode/commands/<prompt>.md      (custom commands)

EXAMPLES:
    # List available prompts
    $(basename "$0") --list

    # Install all prompts interactively
    $(basename "$0") --interactive

    # Install a specific prompt to all platforms (default target: ~/.pi/agent/prompts/)
    $(basename "$0") pi-session

    # Install to specific platform only
    $(basename "$0") -p claude skill-from-cli

    # Install with custom base directory
    $(basename "$0") --target-dir /path/to/project all

INSTALLATION METHOD:
    All prompts are installed via symbolic links.
    Each prompt file is linked to the target directories of selected platforms.

PROMPT FORMAT:
    Each prompt is a markdown file (.md) in prompts/ with optional YAML frontmatter:
      ---
      description: Brief description of this prompt
      ---
      
    The description will be shown in lists and platform documentation.
EOF
}

################################################################################
# Argument Parsing
################################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                usage
                exit 0
                ;;
            --list)
                LIST_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --all)
                INSTALL_ALL=true
                shift
                ;;
            -p|--platform)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing value for $1"
                    exit 1
                fi
                # Add platform if not already present
                local found=false
                for p in "${PLATFORMS[@]}"; do
                    [[ "$p" == "$2" ]] && found=true && break
                done
                [[ "$found" == false ]] && PLATFORMS+=("$2")
                shift 2
                ;;
            --target-dir|-t)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing value for $1"
                    exit 1
                fi
                TARGET_DIR="$2"
                shift 2
                ;;
            --*)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                PROMPT_NAMES+=("$1")
                shift
                ;;
        esac
    done

    # Validate --target-dir if provided
    if [[ -n "$TARGET_DIR" ]]; then
        if [[ ! -d "$TARGET_DIR" ]]; then
            print_error "Target directory does not exist: $TARGET_DIR"
            exit 1
        fi
        TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
    fi

    # Default platforms if none specified
    if [[ ${#PLATFORMS[@]} -eq 0 ]]; then
        PLATFORMS=("claude" "codex" "pi" "opencode")
    fi

    # Validate selected platforms
    for p in "${PLATFORMS[@]}"; do
        case "$p" in
            claude|codex|pi|opencode) ;;
            *) print_error "Unknown platform: $p. Use claude, codex, pi, or opencode." ;;
        esac
    done

    # Need at least one action
    if [[ "$LIST_MODE" == false && "$INTERACTIVE_MODE" == false && "$INSTALL_ALL" == false && ${#PROMPT_NAMES[@]} -eq 0 ]]; then
        print_error "No action specified. Use --all, --list, --interactive, or provide prompt name(s)."
        echo ""
        usage
        exit 1
    fi
}

resolve_install_base() {
    if [[ -n "$TARGET_DIR" ]]; then
        CLAUDE_TARGET="$TARGET_DIR/.claude/commands"
        CODEX_TARGET="$TARGET_DIR/.codex/prompts"
        PI_TARGET="$TARGET_DIR/.pi/agent/prompts"
        # For OpenCode: project-based installs use .opencode/commands/
        OPENCODE_TARGET="$TARGET_DIR/.opencode/commands"
    else
        CLAUDE_TARGET="${HOME}/.claude/commands"
        CODEX_TARGET="${HOME}/.codex/prompts"
        PI_TARGET="${HOME}/.pi/agent/prompts"
        # For OpenCode: global installs use ~/.config/opencode/commands/
        OPENCODE_TARGET="${HOME}/.config/opencode/commands"
    fi
}

################################################################################
# Prompt Discovery
################################################################################

get_available_prompts() {
    local prompts=()

    if [[ ! -d "$PROMPTS_DIR" ]]; then
        print_error "Prompts directory not found: $PROMPTS_DIR"
        exit 1
    fi

    for prompt_path in "$PROMPTS_DIR"/*.md; do
        [[ -f "$prompt_path" ]] || continue
        prompts+=("$(basename "$prompt_path" .md)")
    done

    printf '%s\n' "${prompts[@]}"
}

get_prompt_description() {
    local prompt_name="$1"
    local prompt_file="$PROMPTS_DIR/$prompt_name.md"
    local description=""

    if [[ -f "$prompt_file" ]]; then
        # Try to get description from frontmatter
        description=$(grep -E "^description:" "$prompt_file" | head -1 | sed 's/^description:[[:space:]]*//' | cut -c1-70)
        # Fall back to first non-empty, non-heading line
        if [[ -z "$description" ]]; then
            description=$(grep -v '^#' "$prompt_file" | grep -v '^[[:space:]]*$' | grep -v '^---' | head -1 | cut -c1-70)
        fi
    fi

    echo "${description:-No description available}"
}

################################################################################
# List Prompts
################################################################################

list_prompts() {
    print_header "Available Prompts"
    echo ""

    local prompts_arr=()
    while IFS= read -r prompt; do
        prompts_arr+=("$prompt")
    done < <(get_available_prompts)
    local count=${#prompts_arr[@]}

    if [[ $count -eq 0 ]]; then
        print_warning "No prompts found in $PROMPTS_DIR"
        exit 1
    fi

    # Show platforms column width based on selected platforms
    local platform_cols=""
    for p in "${PLATFORMS[@]}"; do
        case "$p" in
            claude) platform_cols+=" ${GREEN}[symlink]${NC}" ;;
            codex) platform_cols+=" ${GREEN}[symlink]${NC}" ;;
            pi) platform_cols+=" ${GREEN}[symlink]${NC}" ;;
            opencode) platform_cols+=" ${GREEN}[symlink]${NC}" ;;
        esac
    done

    printf "%-35s %s  %s\n" "PROMPT NAME" "STATUS" "DESCRIPTION"
    echo "----------------------------------------------------------------------------------------------------------------"

    for prompt_name in "${prompts_arr[@]}"; do
        local installed=""

        # Check each platform
        for p in "${PLATFORMS[@]}"; do
            case "$p" in
                claude)
                    if [[ -L "$CLAUDE_TARGET/$prompt_name.md" ]]; then
                        installed+=" ${GREEN}✓${NC}"
                    else
                        installed+="  "
                    fi
                    ;;
                codex)
                    if [[ -L "$CODEX_TARGET/$prompt_name.md" ]]; then
                        installed+=" ${GREEN}✓${NC}"
                    else
                        installed+="  "
                    fi
                    ;;
                pi)
                    if [[ -L "$PI_TARGET/$prompt_name.md" ]]; then
                        installed+=" ${GREEN}✓${NC}"
                    else
                        installed+="  "
                    fi
                    ;;
                opencode)
                    if [[ -L "$OPENCODE_TARGET/$prompt_name.md" ]]; then
                        installed+=" ${GREEN}✓${NC}"
                    else
                        installed+="  "
                    fi
                    ;;
            esac
        done

        local desc
        desc=$(get_prompt_description "$prompt_name")

        printf "%-35s %-20s %s\n" "$prompt_name" "$installed" "${desc:-No description}"
    done

    echo ""
    echo "Total prompts available: $count"
    echo "Selected platforms: ${PLATFORMS[*]}"
}

################################################################################
# Installation Core
################################################################################

create_install_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        print_success "Created directory: $dir"
    fi
}

install_to_platform() {
    local platform="$1"
    local prompt_name="$2"
    local source_path="$3"
    
    # Determine target path based on platform
    local target=""
    case "$platform" in
        claude)   target="$CLAUDE_TARGET/$prompt_name.md" ;;
        codex)    target="$CODEX_TARGET/$prompt_name.md" ;;
        pi)       target="$PI_TARGET/$prompt_name.md" ;;
        opencode) target="$OPENCODE_TARGET/$prompt_name.md" ;;
        *) return 1 ;;
    esac
    
    # Create directory if needed
    create_install_dir "$(dirname "$target")"
    
    # Handle existing symlink or file
    if [[ -L "$target" ]]; then
        local current_target
        current_target=$(readlink "$target")
        if [[ "$current_target" == "$source_path" ]]; then
            print_success "${platform^}: Already installed (symlink correct): $prompt_name.md"
            return 0
        fi
        rm -f "$target"
    elif [[ -f "$target" ]]; then
        print_warning "${platform^}: Existing file, replacing: $target"
        rm -f "$target"
    fi
    
    # Create symlink
    ln -s "$source_path" "$target"
    print_success "${platform^}: Installed (symlink): $prompt_name.md -> $(dirname "$target")/"
    
    return 0
}

validate_prompt() {
    local prompt_name="$1"
    local prompt_file="$PROMPTS_DIR/$prompt_name.md"

    if [[ ! -f "$prompt_file" ]]; then
        print_error "Prompt not found: $prompt_file"
        return 1
    fi

    return 0
}

install_single_prompt() {
    local prompt_name="$1"
    local source_path="$PROMPTS_DIR/$prompt_name.md"

    # Validate
    if ! validate_prompt "$prompt_name"; then
        return 1
    fi

    echo ""
    print_info "Installing: $prompt_name"

    # Install to each platform using helper function
    for p in "${PLATFORMS[@]}"; do
        install_to_platform "$p" "$prompt_name" "$source_path" || true
    done

    return 0
}

install_prompts() {
    local prompts=("$@")
    local success_count=0
    local fail_count=0

    for prompt in "${prompts[@]}"; do
        echo ""
        print_info "Processing: $prompt"
        if install_single_prompt "$prompt"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
        fi
    done

    echo ""
    print_header "Installation Summary"
    echo -e "  Success: ${GREEN}$success_count${NC}"
    [[ $fail_count -gt 0 ]] && echo -e "  Failed:  ${RED}$fail_count${NC}"

    if [[ $fail_count -gt 0 ]]; then
        return 1
    fi
    return 0
}

################################################################################
# Interactive Mode
################################################################################

interactive_installation() {
    print_header "Prompt Installation Wizard"
    echo ""

    # Step 1: Target directory
    echo -e "${BLUE}Step 1: Select base directory${NC}"
    echo ""
    
    read -r -p "  Enter target directory [${HOME}]: " target_dir_input
    target_dir_input="${target_dir_input:-$HOME}"
    target_dir_input="${target_dir_input/#\~/$HOME}"

    if [[ ! -d "$target_dir_input" ]]; then
        print_error "Directory does not exist: $target_dir_input"
        exit 1
    fi

    TARGET_DIR="$(cd "$target_dir_input" && pwd)"
    
    echo ""
    resolve_install_base
    
    # Show installation type and paths after resolving TARGET_DIR
    if [[ -n "$TARGET_DIR" && "$TARGET_DIR" != "$HOME" ]]; then
        echo "  (Project-based installation detected)"
        echo ""
        echo "  Prompts will be installed into platform-specific directories:"
        echo ""
        echo "    Claude:   <base>/.claude/commands/"
        echo "    Codex:    <base>/.codex/prompts/"
        echo "    Pi:       <base>/.pi/agent/prompts/"
        echo "    OpenCode: <base>/.opencode/commands/"
    else
        echo "  (Global installation)"
        echo ""
        echo "  Prompts will be installed into platform-specific directories:"
        echo ""
        echo "    Claude:   ~/.claude/commands/"
        echo "    Codex:    ~/.codex/prompts/"
        echo "    Pi:       ~/.pi/agent/prompts/"
        echo "    OpenCode: ~/.config/opencode/commands/"
    fi
    
    print_success "Base directory: $TARGET_DIR"
    echo ""

    # Step 2: Select platforms
    echo -e "${BLUE}Step 2: Select platforms to install to${NC}"
    echo ""
    echo "  Available platforms:"
    echo ""
    
    if [[ -n "$TARGET_DIR" && "$TARGET_DIR" != "$HOME" ]]; then
        echo "    [1] Claude   (<base>/.claude/commands/)      - Slash commands"
        echo "    [2] Codex    (<base>/.codex/prompts/)         - Custom prompts"
        echo "    [3] Pi       (<base>/.pi/agent/prompts/)     - Prompt files"
        echo "    [4] OpenCode (<base>/.opencode/commands/)    - Custom commands (project)"
    else
        echo "    [1] Claude   (~/.claude/commands/)           - Slash commands"
        echo "    [2] Codex    (~/.codex/prompts/)             - Custom prompts"
        echo "    [3] Pi       (~/.pi/agent/prompts/)          - Prompt files"
        echo "    [4] OpenCode (~/.config/opencode/commands/)  - Custom commands (global)"
    fi
    echo ""

    local selected_platforms=()
    local i=1
    declare -A platform_map=()
    
    # Default to all platforms
    PLATFORMS=("claude" "codex" "pi" "opencode")

    echo "  a) Install to ALL platforms (default)"
    echo "  q) Quit"
    echo ""

    read -r -p "Enter choice(s) - number(s) comma-separated, 'a' for all, 'q' to quit: [a] " selection
    selection=${selection:-a}

    if [[ "$selection" == "q" ]]; then
        print_warning "Installation cancelled"
        exit 0
    elif [[ "$selection" == "a" ]]; then
        print_success "Selected all platforms"
    else
        IFS=',' read -ra indices <<< "$selection"
        for idx in "${indices[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            case "$idx" in
                1) PLATFORMS+=("claude") ;;
                2) PLATFORMS+=("codex") ;;
                3) PLATFORMS+=("pi") ;;
                4) PLATFORMS+=("opencode") ;;
                *) print_warning "Invalid number: $idx" ;;
            esac
        done

        if [[ ${#PLATFORMS[@]} -eq 0 ]]; then
            print_error "No valid platforms selected"
            exit 1
        fi
    fi

    # Step 3: Select prompts
    echo ""
    echo -e "${BLUE}Step 3: Select prompts to install${NC}"
    echo ""

    local all_prompts_arr=()
    while IFS= read -r prompt; do
        all_prompts_arr+=("$prompt")
    done < <(get_available_prompts)

    if [[ ${#all_prompts_arr[@]} -eq 0 ]]; then
        print_warning "No prompts found in $PROMPTS_DIR"
        exit 1
    fi

    local i=1
    declare -A prompt_map=()

    for prompt in "${all_prompts_arr[@]}"; do
        # Check installation status on first platform
        local installed=""
        case "${PLATFORMS[0]}" in
            claude) [[ -L "$CLAUDE_TARGET/$prompt.md" ]] && installed=" ${GREEN}[installed]${NC}" ;;
            codex) [[ -L "$CODEX_TARGET/$prompt.md" ]] && installed=" ${GREEN}[installed]${NC}" ;;
            pi) [[ -L "$PI_TARGET/$prompt.md" ]] && installed=" ${GREEN}[installed]${NC}" ;;
            opencode) [[ -L "$OPENCODE_TARGET/$prompt.md" ]] && installed=" ${GREEN}[installed]${NC}" ;;
        esac

        printf "  %2d) %-30s%s\n" "$i" "$prompt" "${installed:-}"
        prompt_map["$i"]="$prompt"
        ((i++))
    done

    echo ""
    echo "  a) Install ALL prompts"
    echo "  q) Quit"
    echo ""

    read -r -p "Enter choice(s) - number(s) comma-separated, 'a' for all, 'q' to quit: [a] " selection
    selection=${selection:-a}

    local selected_prompts=()

    if [[ "$selection" == "q" ]]; then
        print_warning "Installation cancelled"
        exit 0
    elif [[ "$selection" == "a" ]]; then
        selected_prompts=("${all_prompts_arr[@]}")
        print_success "Selected all ${#all_prompts_arr[@]} prompts"
    else
        IFS=',' read -ra indices <<< "$selection"
        for idx in "${indices[@]}"; do
            idx=$(echo "$idx" | tr -d ' ')
            if [[ -n "${prompt_map[$idx]}" ]]; then
                selected_prompts+=("${prompt_map[$idx]}")
                print_success "Selected: ${prompt_map[$idx]}"
            else
                print_warning "Invalid number: $idx"
            fi
        done

        if [[ ${#selected_prompts[@]} -eq 0 ]]; then
            print_error "No valid prompts selected"
            exit 1
        fi
    fi

    # Step 4: Confirm
    echo ""
    print_header "Installation Plan"
    echo ""
    echo "  Base directory: $TARGET_DIR"
    echo "  Platforms:"
    for p in "${PLATFORMS[@]}"; do
        case "$p" in
            claude)   echo "    - Claude ($CLAUDE_TARGET)" ;;
            codex)    echo "    - Codex ($CODEX_TARGET)" ;;
            pi)       echo "    - Pi ($PI_TARGET)" ;;
            opencode) echo "    - OpenCode ($OPENCODE_TARGET)" ;;
        esac
    done
    echo ""
    echo "  Prompts (${#selected_prompts[@]}):"
    for prompt in "${selected_prompts[@]}"; do
        local desc
        desc=$(get_prompt_description "$prompt")
        echo "    - $prompt  ->  ${desc:0:50}"
    done
    echo ""

    read -r -p "Proceed with installation? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi

    echo ""
    install_prompts "${selected_prompts[@]}"

    post_install_info
}

################################################################################
# Post-Installation Info
################################################################################

post_install_info() {
    echo ""
    print_header "Installation Complete"
    echo ""
    
    for p in "${PLATFORMS[@]}"; do
        case "$p" in
            claude)
                echo -e "${GREEN}✓${NC} Claude commands installed to: $CLAUDE_TARGET/"
                echo "  Usage in Claude: Type /<command-name>"
                ;;
            codex)
                echo -e "${GREEN}✓${NC} Codex prompts installed to: $CODEX_TARGET/"
                echo "  These will be available as custom prompts in Codex"
                ;;
            pi)
                echo -e "${GREEN}✓${NC} Pi prompts installed to: $PI_TARGET/"
                echo "  Prompts are now available in your .pi/agent environment"
                ;;
            opencode)
                echo -e "${GREEN}✓${NC} OpenCode commands installed to: $OPENCODE_TARGET/"
                echo "  Usage in OpenCode: Type /<command-name>"
                ;;
        esac
    done
    
    echo ""
    print_info "You can run './install-prompt.sh --list' to verify installations"
    echo ""
}

main() {
    parse_arguments "$@"
    resolve_install_base

    if [[ "$LIST_MODE" == true ]]; then
        list_prompts
        exit 0
    fi

    if [[ "$INTERACTIVE_MODE" == true ]]; then
        interactive_installation
        exit $?
    fi

    # Determine prompts to install
    local to_install_arr=()

    if [[ "$INSTALL_ALL" == true ]]; then
        while IFS= read -r prompt; do
            to_install_arr+=("$prompt")
        done < <(get_available_prompts)
        if [[ ${#to_install_arr[@]} -eq 0 ]]; then
            print_error "No prompts found in $PROMPTS_DIR"
            exit 1
        fi
    else
        to_install_arr=("${PROMPT_NAMES[@]}")
    fi

    # Validate all named prompts up front
    local valid=true
    for prompt in "${to_install_arr[@]}"; do
        if ! validate_prompt "$prompt"; then
            valid=false
        fi
    done
    [[ "$valid" == false ]] && exit 1

    # Print plan
    print_header "Installing Prompts"
    echo ""
    echo "  Base directory: ${TARGET_DIR:-$HOME}"
    echo "  Platforms:      ${PLATFORMS[*]}"
    echo "  Count:          ${#to_install_arr[@]}"
    
    echo ""
    echo "  Target directories:"
    for p in "${PLATFORMS[@]}"; do
        case "$p" in
            claude)   echo -e "    - Claude:   ${BLUE}$CLAUDE_TARGET${NC}" ;;
            codex)    echo -e "    - Codex:    ${BLUE}$CODEX_TARGET${NC}" ;;
            pi)       echo -e "    - Pi:       ${BLUE}$PI_TARGET${NC}" ;;
            opencode) echo -e "    - OpenCode: ${BLUE}$OPENCODE_TARGET${NC}" ;;
        esac
    done

    if [[ "$FORCE_MODE" != true ]]; then
        echo ""
        read -r -p "Proceed with installation? [y/N] " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_warning "Installation cancelled"
            exit 0
        fi
    fi

    install_prompts "${to_install_arr[@]}"

    echo ""
    print_success "Done!"
    post_install_info
}

main "$@"
