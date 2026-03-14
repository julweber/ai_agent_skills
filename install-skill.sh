#!/usr/bin/env bash

################################################################################
# install-skill.sh - Install AI agent skills for supported coding agents
#
# Supported Agents: opencode, pi, claude
# Installation Method: Symlinks (default) or Copy mode
#
# Usage:
#   ./install-skill.sh --help                    # Show this help message
#   ./install-skill.sh --list                    # List available skills
#   ./install-skill.sh --agent AGENT             # Install all skills for agent
#   ./install-skill.sh --skill SKILL1 [SKILL2]  # Install specific skill(s)
#   ./install-skill.sh --status --agent AGENT    # Show installation status
#   ./install-skill.sh --interactive             # Interactive installation wizard
#   ./install-skill.sh --dry-run                 # Preview actions without executing
#   ./install-skill.sh --force                   # Skip confirmation prompts
#   ./install-skill.sh --copy                    # Use copy instead of symlink
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
SKILLS_DIR="$SCRIPT_DIR/skills"

# Agent configuration (local/project level)
declare -A AGENT_CONFIGS=(
    ["opencode"]="$SCRIPT_DIR/.opencode/skills"
    ["pi"]="$SCRIPT_DIR/.pi/skills"
    ["claude"]="$SCRIPT_DIR/.claude/skills"
)

# Global agent configuration paths
declare -A GLOBAL_AGENT_CONFIGS=(
    ["opencode"]="$HOME/.opencode/skills"
    ["pi"]="$HOME/.pi/agent/skills"
    ["claude"]="$HOME/.claude/skills"
)

# Installation mode: local or global
INSTALL_MODE="local"

# Global variables
AGENT=""
SKILL_NAMES=()
COPY_MODE=false
LIST_MODE=false
STATUS_MODE=false
INTERACTIVE_MODE=false
DRY_RUN_MODE=false
FORCE_MODE=false
INSTALL_ALL=false
GLOBAL_MODE=false
SKILL_NAMES=()
COPY_MODE=false
LIST_MODE=false
STATUS_MODE=false
INTERACTIVE_MODE=false
DRY_RUN_MODE=false
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
# Argument Parsing
################################################################################

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install AI agent skills for supported coding agents.

ARGUMENTS:
    skill names           One or more skill names to install (optional)

OPTIONS:
    --agent AGENT         Specify the target agent (required unless interactive)
                          Supported: opencode, pi, claude
    --global              Install globally instead of project level
    --skill SKILL [SKILL] Install specific skill(s) by name
    --all                 Install all available skills
    --list                List all available skills without installing
    --status              Show installation status for specified agent
    --interactive         Start interactive installation wizard
    --dry-run             Preview actions without executing
    --force               Skip confirmation prompts
    --copy                Use file copy instead of symlinks
    --help, -h            Show this help message and exit

EXAMPLES:
    # Install all skills for opencode (interactive mode)
    $(basename "$0") --interactive

    # Install specific skill for pi at project level
    $(basename "$0") --agent pi --skill file-organizer list-large-files

    # Install skill globally for opencode
    $(basename "$0") --agent opencode --global --skill terraform

    # Install all skills with copy mode
    $(basename "$0") --all --copy --force

    # Preview installation without executing
    $(basename "$0") --agent opencode --skill terraform --dry-run

    # Show current installation status (project level)
    $(basename "$0") --status --agent opencode

    # Interactive wizard with global installation selection
    $(basename "$0") --interactive  # Will prompt for project vs global selection

SUPPORTED AGENTS:
    opencode          - Install to <project>/.opencode/skills/ or ~/.opencode/skills/ (global)
    pi   - Install to <project>/.pi/skills/ or ~/.pi/agent/skills/ (global)
    claude            - Install to <project>/.claude/skills/ or ~/.claude/skills/ (global)

EOF
}

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
            --status)
                STATUS_MODE=true
                shift
                ;;
            --interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --dry-run)
                DRY_RUN_MODE=true
                shift
                ;;
            --force)
                FORCE_MODE=true
                shift
                ;;
            --copy)
                COPY_MODE=true
                shift
                ;;
            --all)
                INSTALL_ALL=true
                shift
                ;;
            --agent)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing value for --agent"
                    exit 1
                fi
                AGENT="$2"
                shift 2
                ;;
            --global)
                GLOBAL_MODE=true
                shift
                ;;
            --skill)
                if [[ -z "$2" || "$2" == --* ]]; then
                    print_error "Missing value for --skill"
                    exit 1
                fi
                while [[ -n "$2" && "$2" != --* ]]; do
                    SKILL_NAMES+=("$2")
                    shift
                done
                shift
                ;;
            *)
                # Positional arguments (skill names)
                if [[ ! "$1" =~ ^- ]]; then
                    SKILL_NAMES+=("$1")
                    shift
                else
                    print_error "Unknown option: $1"
                    usage
                    exit 1
                fi
                ;;
        esac
    done

    # Validate agent specification for non-interactive mode (except for --list)
    if [[ "$INTERACTIVE_MODE" == false && -z "$AGENT" && "$LIST_MODE" != true ]]; then
        print_error "Agent must be specified with --agent (or use --interactive)"
        usage
        exit 1
    fi
}

################################################################################
# Skill Discovery
################################################################################

get_available_skills() {
    local skills=()
    
    if [[ ! -d "$SKILLS_DIR" ]]; then
        print_error "Skills directory not found: $SKILLS_DIR"
        exit 1
    fi
    
    for skill_path in "$SKILLS_DIR"/*/; do
        if [[ -f "${skill_path}SKILL.md" ]]; then
            local skill_name
            skill_name=$(basename "$skill_path")
            skills+=("$skill_name")
        fi
    done
    
    printf '%s\n' "${skills[@]}"
}

list_skills() {
    print_header "Available Skills"
    
    local skills
    mapfile -t skills < <(get_available_skills)
    local count=${#skills[@]}
    
    if [[ $count -eq 0 ]]; then
        print_warning "No skills found in $SKILLS_DIR"
        exit 1
    fi
    
    echo ""
    printf "%-40s %s\n" "SKILL NAME" "DESCRIPTION"
    echo "----------------------------------------"
    
    for skill_name in "${skills[@]}"; do
        local skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
        local description=""
        
        # Extract description from YAML frontmatter if available
        if [[ -f "$skill_file" ]]; then
            description=$(grep -E "^description:" "$skill_file" | head -1 | sed 's/^description:[[:space:]]*//' | cut -c1-50)
        fi
        
        description=${description:-"No description available"}
        printf "%-40s %s\n" "$skill_name" "$description"
    done
    
    echo ""
    echo "Total skills available: $count"
}

################################################################################
# Agent Path Resolution
################################################################################

get_agent_path() {
    local agent="$1"
    
    if [[ "$GLOBAL_MODE" == true ]]; then
        echo "${GLOBAL_AGENT_CONFIGS[$agent]}"
    else
        echo "${AGENT_CONFIGS[$agent]}"
    fi
}

validate_agent() {
    local agent="$1"
    
    # Check agent exists in either config
    if [[ -z "${AGENT_CONFIGS[$agent]}" && -z "${GLOBAL_AGENT_CONFIGS[$agent]}" ]]; then
        print_error "Unsupported agent: $agent"
        echo ""
        echo "Supported agents:"
        for supported_agent in "${!AGENT_CONFIGS[@]}"; do
            echo "  - $supported_agent (local)"
        done
        for supported_agent in "${!GLOBAL_AGENT_CONFIGS[@]}"; do
            echo "  - $supported_agent (global)"
        done
        exit 1
    fi
    
    # Determine path based on global mode
    AGENT_PATH=$(get_agent_path "$agent")
}

################################################################################
# Installation Functions
################################################################################

create_installation_directory() {
    local target_dir="$1"
    
    if [[ "$DRY_RUN_MODE" == true ]]; then
        print_info "[DRY-RUN] Would create directory: $target_dir"
        return 0
    fi
    
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        print_success "Created installation directory: $target_dir"
    else
        print_info "Installation directory already exists: $target_dir"
    fi
}

install_single_skill() {
    local skill_name="$1"
    local source_path="$SKILLS_DIR/$skill_name"
    local target_path="$AGENT_PATH/$skill_name"
    
    # Validate skill exists
    if [[ ! -d "$source_path" ]]; then
        print_error "Skill not found: $skill_name"
        return 1
    fi
    
    if [[ ! -f "$source_path/SKILL.md" ]]; then
        print_error "Invalid skill directory (missing SKILL.md): $skill_name"
        return 1
    fi
    
    # Handle existing installation
    local action=""
    
    if [[ -L "$target_path" ]]; then
        local current_target
        current_target=$(readlink "$target_path")
        print_warning "Existing symlink found: $target_path -> $current_target"
        
        if [[ "$FORCE_MODE" == true ]]; then
            print_info "Removing existing symlink (force mode)"
            rm -f "$target_path"
            action="replace_symlink"
        else
            action="confirm_replace"
        fi
    elif [[ -d "$target_path" ]]; then
        print_warning "Existing directory found at: $target_path"
        
        if [[ "$FORCE_MODE" == true ]]; then
            print_info "Removing existing directory (force mode)"
            rm -rf "$target_path"
            action="replace_directory"
        else
            action="confirm_replace"
        fi
    else
        action="install_new"
    fi
    
    # Handle confirmation for overwrites
    if [[ "$action" == "confirm_replace" ]]; then
        echo ""
        read -p "Replace existing installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Skipping skill: $skill_name"
            return 0
        fi
        
        # Backup and remove existing
        local backup_path
        backup_path="${target_path}.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$target_path" "$backup_path"
        print_success "Backed up to: $backup_path"
    fi
    
    # Perform installation
    if [[ "$COPY_MODE" == true ]]; then
        if [[ "$DRY_RUN_MODE" == false ]]; then
            cp -r "$source_path" "$target_path"
        fi
        action_type="copy"
    else
        if [[ "$DRY_RUN_MODE" == false ]]; then
            ln -sf "$SKILLS_DIR/$skill_name" "$target_path"
        fi
        action_type="symlink"
    fi
    
    print_success "Installed $action_type: $skill_name -> $target_path"
}

install_skills() {
    local skills=("$@")
    local success_count=0
    local fail_count=0
    
    for skill in "${skills[@]}"; do
        if install_single_skill "$skill"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
        fi
    done
    
    echo ""
    print_header "Installation Summary"
    echo -e "Success: ${GREEN}$success_count${NC}"
    [[ $fail_count -gt 0 ]] && echo -e "Failed: ${RED}$fail_count${NC}"
    
    if [[ $fail_count -gt 0 ]]; then
        return 1
    fi
    
    return 0
}

install_all_skills() {
    local skills
    mapfile -t skills < <(get_available_skills)
    
    print_header "Installing All Skills"
    echo ""
    echo "Agent: $AGENT"
    echo "Target: $AGENT_PATH"
    echo "Installation type: ${COPY_MODE:+copy}symlink"
    echo ""
    
    if [[ "$DRY_RUN_MODE" == true ]]; then
        print_info "[DRY-RUN] Would install ${#skills[@]} skills"
        for skill in "${skills[@]}"; do
            echo "  - $skill"
        done
        return 0
    fi
    
    create_installation_directory "$AGENT_PATH"
    
    if [[ "${FORCE_MODE}" != true ]]; then
        echo ""
        read -p "Install ${#skills[@]} skills to $AGENT_PATH? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Installation cancelled by user"
            exit 0
        fi
    fi
    
    install_skills "${skills[@]}"
}

show_installation_status() {
    local agent="$1"
    local target_dir
    target_dir=$(get_agent_path "$agent")
    
    print_header "Installation Status for $agent"
    
    if [[ ! -d "$target_dir" ]]; then
        print_warning "No installation found at: $target_dir"
        echo ""
        echo "To install skills, run:"
        echo "  $(basename "$0") --agent $agent --interactive"
        return 0
    fi
    
    local installed_count=0
    echo ""
    printf "%-40s %s\n" "SKILL NAME" "STATUS"
    echo "----------------------------------------"
    
    for skill_path in "$target_dir"/*/; do
        if [[ -d "$skill_path" ]]; then
            local skill_name
            skill_name=$(basename "$skill_path")
            local status=""
            
            if [[ -L "$skill_path" ]]; then
                local target
                target=$(readlink "$skill_path")
                status="symlink -> $target"
                installed_count=$((installed_count + 1))
            elif [[ -d "$skill_path" && -f "$skill_path/SKILL.md" ]]; then
                status="copy installation"
                installed_count=$((installed_count + 1))
            else
                status="invalid (missing SKILL.md)"
            fi
            
            printf "%-40s %s\n" "$skill_name" "$status"
        fi
    done
    
    echo ""
    
    local available_skills
    mapfile -t available_skills < <(get_available_skills)
    local not_installed_count=$((${#available_skills[@]} - installed_count))
    
    print_info "Installed: $installed_count / ${#available_skills[@]}"
    
    if [[ $not_installed_count -gt 0 ]]; then
        echo ""
        print_warning "${not_installed_count} skills not yet installed"
    fi
}

################################################################################
# Interactive Mode
################################################################################

interactive_installation() {
    print_header "AI Agent Skills Installation Wizard"
    echo ""
    
    # Step 1: Select target environment (project vs global)
    echo -e "${BLUE}Step 1: Select installation environment${NC}"
    echo ""
    echo "  1. Project level (local)"
    echo "     - Install to <project>/.pi/skills/, <project>/.opencode/skills/, or <project>/.claude/skills/"
    echo "     - Skills are relative to the project directory"
    echo "     - Updates reflected automatically when repo is updated"
    echo ""
    echo "  2. Global level"
    echo "     - Install to ~/.pi/agent/skills/, ~/.opencode/skills/, or ~/.claude/skills/"
    echo "     - Skills are installed in user home directory"
    echo "     - Independent of project location"
    echo ""
    
    read -r -p "Choose environment (1-2): [1] " env_choice
    env_choice=${env_choice:-1}
    
    if [[ "$env_choice" == "2" ]]; then
        GLOBAL_MODE=true
        INSTALL_MODE="global"
    else
        INSTALL_MODE="local"
    fi
    
    print_success "Selected environment: $INSTALL_MODE"
    echo ""
    
    # Step 2: Select agent
    echo -e "${BLUE}Step 2: Select target agent${NC}"
    echo ""
    
    local i=1
    declare -a agent_options=()
    
    for agent in "${!AGENT_CONFIGS[@]}"; do
        agent_options+=("$agent")
        echo "  $i. $agent"
        ((i++))
    done
    
    echo ""
    read -r -p "Choose an agent (1-${#agent_options[@]}): " agent_choice
    
    if ! [[ "$agent_choice" =~ ^[0-9]+$ ]] || [[ "$agent_choice" -lt 1 || "$agent_choice" -gt ${#agent_options[@]} ]]; then
        print_error "Invalid selection"
        exit 1
    fi
    
    AGENT="${agent_options[$((agent_choice - 1))]}"
    validate_agent "$AGENT"
    
    local target_path
    target_path=$(get_agent_path "$AGENT")
    print_success "Selected agent: $AGENT (target: $target_path)"
    echo ""
    
    # Step 2: Select installation type
    echo -e "${BLUE}Step 2: Select installation type${NC}"
    echo ""
    echo "  1. Symlink (recommended for development)"
    echo "     - Creates symbolic links to the skills repository"
    echo "     - Skills updates are automatically reflected"
    echo "     - Requires write access only to target directory"
    echo ""
    echo "  2. Copy installation"
    echo "     - Copies skill files to target directory"
    echo "     - Useful for ralph loop or isolated environments"
    echo "     - Updates require re-installation"
    echo ""
    
    read -r -p "Choose installation type (1-2): [1] " install_choice
    install_choice=${install_choice:-1}
    
    if [[ "$install_choice" == "2" ]]; then
        COPY_MODE=true
    fi
    
    local install_type="symlink"
    [[ "$COPY_MODE" == true ]] && install_type="copy"
    print_success "Installation type: $install_type"
    echo ""
    
    # Step 3: Select skills
    echo -e "${BLUE}Step 3: Select skills to install${NC}"
    echo ""
    
    local all_skills
    mapfile -t all_skills < <(get_available_skills)
    declare -a selected_skills=()
    
    while true; do
        echo "Available skills:"
        echo ""
        
        i=1
        declare -A skill_map=()
        
        for skill in "${all_skills[@]}"; do
            if [[ $i -le 20 ]]; then  # Limit display to first 20
                local status=""
                if [[ "$COPY_MODE" == true ]]; then
                    status="[$i] "
                else
                    status="$i) "
                fi
                
                echo "  ${status}$skill"
                skill_map["$i"]="$skill"
                ((i++))
            fi
        done
        
        if [[ $i -gt 21 ]]; then
            echo "  ... and $((${#all_skills[@]} - 20)) more skills"
        fi
        
        echo ""
        echo "Options:"
        echo "  a) Install ALL selected skills above"
        echo "  s) Select specific skill(s)"
        echo "  q) Quit installation"
        echo ""
        
        read -r -p "Choose an option (a/s/q): [a] " selection_choice
        selection_choice=${selection_choice:-a}
        
        if [[ "$selection_choice" == "q" ]]; then
            print_warning "Installation cancelled by user"
            exit 0
        elif [[ "$selection_choice" == "s" ]]; then
            echo ""
            local skill_selection=""
            
            while true; do
                read -r -p "Enter skill numbers (comma-separated, or 'done' to finish): " skill_selection
                
                if [[ "$skill_selection" == "done" || -z "$skill_selection" ]]; then
                    break
                fi
                
                IFS=',' read -ra selected_indices <<< "$skill_selection"
                
                for index in "${selected_indices[@]}"; do
                    index=$(echo "$index" | tr -d ' ')  # Remove spaces
                    
                    if [[ -n "${skill_map[$index]}" ]]; then
                        local skill="${skill_map[$index]}"
                        
                        # Check if already selected
                        local already_selected=false
                        for existing in "${selected_skills[@]}"; do
                            if [[ "$existing" == "$skill" ]]; then
                                already_selected=true
                                break
                            fi
                        done
                        
                        if [[ "$already_selected" != true ]]; then
                            selected_skills+=("$skill")
                            print_success "Added: $skill"
                        else
                            print_warning "Already selected: $skill"
                        fi
                    else
                        print_warning "Invalid skill number: $index"
                    fi
                done
                
                echo ""
            done
            
            if [[ ${#selected_skills[@]} -eq 0 ]]; then
                print_warning "No skills selected. Installing all available skills."
                selected_skills=("${all_skills[@]}")
            fi
            
            break
        elif [[ "$selection_choice" == "a" || -z "$selection_choice" ]]; then
            if [[ ${#selected_skills[@]} -eq 0 ]]; then
                # First time: select all displayed skills
                for index in "${!skill_map[@]}"; do
                    selected_skills+=("${skill_map[$index]}")
                done
                
                print_success "Selected ${#selected_skills[@]} skills"
                
                if [[ ${#all_skills[@]} -gt 20 ]]; then
                    echo ""
                    read -r -p "Install ALL ${#all_skills[@]} available skills? [y/N] " confirm_all
                    if [[ "$confirm_all" =~ ^[Yy]$ ]]; then
                        selected_skills=("${all_skills[@]}")
                    fi
                fi
                
                break
            else
                # Add more skills to existing selection
                for index in "${!skill_map[@]}"; do
                    local skill="${skill_map[$index]}"
                    
                    local already_selected=false
                    for existing in "${selected_skills[@]}"; do
                        if [[ "$existing" == "$skill" ]]; then
                            already_selected=true
                            break
                        fi
                    done
                    
                    if [[ "$already_selected" != true ]]; then
                        selected_skills+=("$skill")
                        print_success "Added: $skill"
                    fi
                done
            fi
        else
            print_error "Invalid option: $selection_choice"
        fi
        
        echo ""
    done
    
    # Step 4: Review and install
    echo ""
    print_header "Installation Summary"
    echo ""
    echo "Agent: $AGENT"
    echo "Target: $AGENT_PATH"
    echo "Type: ${COPY_MODE:+copy}symlink"
    echo ""
    echo "Skills to install (${#selected_skills[@]}):"
    
    for skill in "${selected_skills[@]}"; do
        echo "  ✓ $skill"
    done
    
    echo ""
    
    if [[ "$DRY_RUN_MODE" == true ]]; then
        print_info "[DRY-RUN] Installation preview complete"
        return 0
    fi
    
    read -r -p "Proceed with installation? [y/N] " confirm_install
    if [[ ! "$confirm_install" =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled by user"
        exit 0
    fi
    
    # Perform installation
    create_installation_directory "$AGENT_PATH"
    
    echo ""
    install_skills "${selected_skills[@]}"
}

################################################################################
# Main Function
################################################################################

main() {
    parse_arguments "$@"
    
    # Handle list mode
    if [[ "$LIST_MODE" == true ]]; then
        list_skills
        exit 0
    fi
    
    # Validate agent for non-interactive modes (except --list)
    if [[ "$INTERACTIVE_MODE" != true && -n "$AGENT" && "$STATUS_MODE" != true ]]; then
        validate_agent "$AGENT"
    fi
    
    # Handle status mode
    if [[ "$STATUS_MODE" == true ]]; then
        show_installation_status "${AGENT:-opencode}"
        exit 0
    fi
    
    # Handle interactive mode
    if [[ "$INTERACTIVE_MODE" == true ]]; then
        interactive_installation
        exit $?
    fi
    
    # Determine skills to install
    local skills_to_install=()
    
    if [[ "$INSTALL_ALL" == true || ${#SKILL_NAMES[@]} -eq 0 ]]; then
        mapfile -t skills_to_install < <(get_available_skills)
    else
        skills_to_install=("${SKILL_NAMES[@]}")
    fi
    
    # Validate all specified skills exist
    for skill in "${skills_to_install[@]}"; do
        if [[ ! -d "$SKILLS_DIR/$skill" || ! -f "$SKILLS_DIR/$skill/SKILL.md" ]]; then
            print_error "Skill not found: $skill"
            exit 1
        fi
    done
    
    # Perform installation
    if [[ "${#skills_to_install[@]}" -eq $(get_available_skills | wc -w) && "$INSTALL_ALL" == true ]]; then
        install_all_skills
    else
        print_header "Installing Skills"
        echo ""
        echo "Agent: $AGENT"
        echo "Target: $AGENT_PATH"
        echo "Skills: ${#skills_to_install[@]}"
        
        if [[ "$DRY_RUN_MODE" == true ]]; then
            print_info "[DRY-RUN] Would install:"
            for skill in "${skills_to_install[@]}"; do
                echo "  - $skill"
            done
            exit 0
        fi
        
        create_installation_directory "$AGENT_PATH"
        
        if [[ "${FORCE_MODE}" != true ]]; then
            read -r -p "Proceed with installation? [y/N] " confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                print_warning "Installation cancelled by user"
                exit 0
            fi
        fi
        
        install_skills "${skills_to_install[@]}"
    fi
    
    echo ""
    print_success "Installation complete!"
}

# Run main function with all arguments
main "$@"
