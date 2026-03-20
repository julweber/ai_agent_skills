---
name: codex-cli
description: Expert control of Codex CLI tooling including exec, review, login/logout, and MCP server management. Covers all commands, flags, options, configuration profiles, sandbox modes, and usage patterns for working with the Codex AI coding agent from command line.
---

## Overview

Codex provides a powerful AI coding assistant with various subcommands for different workflows including interactive sessions, non-interactive execution, code reviews, authentication management, MCP server operations, and sandbox debugging. This skill covers all discovered commands and flags.

## Main Commands & Flags

### Global Options (applies to all subcommands)
```bash
codex [OPTIONS] [PROMPT]
  
Global options:
- -c, --config <key=value>    # Override configuration values from ~/.codex/config.toml
- --enable <FEATURE>             # Enable a feature (repeatable)
- --disable <FEATURE>            # Disable a feature (repeatable)
- -i, --image <FILE>...         # Optional image(s) to attach to the initial prompt
- -m, --model <MODEL>           # Specify which model to use
- --oss                          # Use open-source provider instead of default
- --local-provider <OSS_PROVIDER># Specify local provider (lmstudio or ollama)
- -s, --sandbox <SANDBOX_MODE>  # Select sandbox policy for shell commands
- -p, --profile <CONFIG_PROFILE> # Use configuration profile from config.toml
- -C, --cd <DIR>               # Change working directory
- --full-auto                   # Low-friction mode (equivalent to certain flags)
- --dangerously-bypass-approvals-and-sandbox  # Skip all safety checks (EXTREMELY DANGEROUS)
- --search                      # Enable web search capabilities
- -a, --ask-for-approval <APPROVAL_POLICY>  # Configure approval requirements
- -h, --help                    # Show help message
- -V, --version                 # Show version information
```

### Non-interactive execution (`exec` or `e`)
```bash
codex exec [OPTIONS] [PROMPT] [COMMAND]
  
Usage patterns:
- codex exec "fix the bug in main.py"
- echo "fix the bug" | codex exec -
- codex exec --review "analyze this file for security issues"
- codex e -c model="o3" "add tests to utils.rs"

Subcommands:
- resume      # Resume a previous session by ID or use --last
- review      # Run code review against current repository

Options:
- --uncommitted   # Review staged, unstaged, and untracked changes
- --base <BRANCH># Review changes against specified base branch
- --commit <SHA>  # Review specific commit's changes
- --title <TITLE> # Optional title for review summaries
- --ephemeral      # Run without persisting session files
- --output-schema <FILE>   # Path to JSON Schema file describing response format
- --color <auto|always|never># Color output settings (default: auto)
- --progress-cursor         # Force cursor-based progress updates
- --json                   # Output events as JSONL format
- -o, --output-last-message <FILE>  # Write last message to specified file
- --skip-git-repo-check   # Allow running outside Git repository
```

### Code review (`review`)
```bash
codex review [OPTIONS] [PROMPT]

Options:
- --uncommitted    # Review all uncommitted changes
- --base <BRANCH>  # Specify base branch for comparison
- --commit <SHA>   # Review specific commit's changes
- --title <TITLE>  # Optional title for review summary output
```

### Authentication management (`login`, `logout`)
```bash
codex login [OPTIONS] <COMMAND>
  
Subcommands:
- status      # Show current login status
- --with-api-key   # Read API key from stdin
- --device-auth     # Use device-based authentication flow

Usage: codex login [status|--with-api-key]

Examples:
- echo $OPENAI_API_KEY | codex login --with-api-key  # Login with existing API key
- codex login status                                   # Check login status
```

### MCP server operations (`mcp`)
```bash
codex mcp [OPTIONS] <COMMAND>

Subcommands:
- list     # List configured MCP servers
- get      # Get information about a specific MCP server
- add      # Add a new MCP server configuration
- remove   # Remove an existing MCP server
- login    # Login to MCP server authentication
- logout   # Logout from MCP server authentication
```

### Sandbox operations (`sandbox`)
```bash
codex sandbox [OPTIONS] <COMMAND>
  
Subcommands:
- macos     # Run commands under Seatbelt (macOS only) [aliases: seatbelt]
- linux     # Run commands under Landlock+seccomp (Linux only) [aliases: landlock]
- windows   # Run commands under Windows restricted token sandbox
```

#### macOS Sandbox (`sandbox macos`)
```bash
codex sandbox macos [OPTIONS] [COMMAND]...
  
Options:
- --full-auto      # Convenience alias for low-friction automatic execution
- --log-denials    # Capture and log macOS sandbox denials via `log stream`

Usage patterns:
- codex sandbox macos "echo hello"
- codex s linux -c model="o3" "ls -la"
```

#### Linux Sandbox (`sandbox linux`)
```bash
codex sandbox linux [OPTIONS] [COMMAND]...
  
Options:
- --full-auto     # Low-friction mode that disables network access but allows local writes
```

#### Windows Sandbox (`sandbox windows`)
```bash
codex sandbox windows [OPTIONS] [COMMAND]...
  
Options:
Same as global options plus platform-specific restrictions via Windows restricted tokens.
```

### Completion scripts (`completion`)
```bash
codex completion [OPTIONS] [SHELL]
  
Arguments:
- [SHELL]   # Shell to generate completions for (default: bash)
  Possible values: bash, elvish, fish, powershell, zsh

Options:
Same global configuration options apply.
```

### Debugging tools (`debug`)
```bash
codex debug [OPTIONS] <COMMAND>
  
Subcommands:
- app-server   # Tooling to help debug the app server operations
```

### Cloud operations (`cloud`)
[EXPERIMENTAL]
```bash
codex cloud [OPTIONS] [COMMAND]
  
Subcommands:
- exec    # Submit new Codex Cloud tasks without TUI
- status  # Show task status in Codex Cloud
- list    # List available Codex Cloud tasks
- apply   # Apply diffs from Codex Cloud tasks locally
- diff    # Show unified diff for a specific task
```

#### Global Codex cloud options:
- --enable <FEATURE>   # Enable experimental features
- --disable <FEATURE>  # Disable experimental features

## Configuration Profiles

The `-p, --profile` flag allows loading predefined configuration profiles from `~/.codex/config.toml`.

Example profile structure in config.toml:
```toml
[profiles]
my-profile = { model = "o3", sandbox_permissions = ["workspace-write-access"] }
review-profile = { model = "claude-sonnet-4", features = { code_review_enabled = true } }
```

Usage:
```bash
codex exec -p my-profile "fix the bug in main.py"
codex review --profile review-profile "analyze this file"
```

## Important Configuration Values

### Default configuration file location: `~/.codex/config.toml`

Key configuration settings include:
- `[model]` - Default model selection
- `[sandbox_permissions]` - Array of allowed sandbox permissions
  Possible values: ["read-only", "workspace-write", "danger-full-access"]
- `[shell_environment_policy]` - Controls environment variable inheritance
  Possible nested values: inherit, restricted, all
- `[features.<name>]` - Feature flags configuration

### Sandbox permission policies:
```bash
--sandbox read-only                    # Only read workspace files
--sandbox workspace-write              # Read and modify workspace files
--sandbox danger-full-access           # Full filesystem access with potential system impact
```

## Common Usage Examples

### Interactive development sessions
```bash
# Start an interactive session
codex "help me implement a REST API endpoint"
  
# Continue previous session
codex resume --last

# Fork current session to continue in parallel
codex fork <session-id>
```

### Non-interactive code analysis
```bash
# Run code review on all changes
codex review
  
# Review specific commit
codex review --commit abc1234
  
# Run non-interactive model with custom prompt
codex exec "analyze this Rust file for memory safety issues"
```

### Authentication workflows
```bash
# Login using existing API key from environment variable
export OPENAI_API_KEY="your-key-here"
echo $OPENAI_API_KEY | codex login --with-api-key
  
# Check current authentication status
codex login status
  
# Logout to clear stored credentials
codex logout
```

### MCP server management
```bash
# List configured MCP servers
codex mcp list
  
# Add a new MCP server configuration
codex mcp add --name some-server --server some-provider:some-tool
  
# Remove an existing MCP server
codex mcp remove --name some-server
```

### Sandbox debugging operations
```bash
# Run command in macOS sandbox with denial logging
codex sandbox macos --log-denials "git commit -m 'test'"
  
# Linux sandbox execution (network disabled)
codex s linux "make build"
  
# Windows restricted token sandbox
codex sandbox windows "dir C:\\Users"
```

### Shell completion generation
```bash
# Generate bash completion scripts
codex completion bash > ~/.local/share/bash-completion/completions/codex
  
source ~/.local/share/bash-completion/completions/codex
  
# Generate zsh completions
codez completion zsh > ~/.oh-my-zsh/completions/_codex
```

### Configuration overrides for specific tasks
```bash
# Override model and sandbox permissions temporarily
codex exec -c model="o3" -s workspace-write "fix the code"
  
# Enable specific features for a session
codex --enable search --disable untrusted-commands "analyze this file with web search"
  
# Use custom config values via dotted notation
codex exec -c 'shell_environment_policy.inherit.all=true' "show me environment variables"
```

## Known defaults and behaviors:

- **Model**: Uses the configured default model unless overridden with `-m/--model` or `model="..."` in config
- **Sandbox permissions**: Default to `read-only` unless specified otherwise
- **Color output**: Automatic based on terminal capabilities unless `--color` is set
- **Progress display**: Cursor-based updates are preferred for interactive sessions
- **Working directory**: Current working directory by default unless changed with `-C/--cd`
- **Feature flags**: Most features disabled by default and must be explicitly enabled

## Security considerations:

### Sandbox modes and approval policies:
```bash
# Read-only sandbox (safe for viewing files)
codex --sandbox read-only exec "analyze the code"
  
# Workspace-write sandbox (allows file modifications within workspace only)
codex --sandbox workspace-write exec "fix security issues in src/"
  
# Danger-full-access sandbox (potentially unsafe - use with caution!)
codex --sandbox danger-full-access exec "system maintenance task"
  
# Ask for approval on every potentially dangerous command
codez --ask-for-approval never exec "run this without asking me"
```

### Dangerous flags to avoid:
```bash
--dangerously-bypass-approvals-and-sandbox   # EXTREMELY DANGEROUS - skips ALL safety checks
--full-auto                                # Convenience alias that enables potentially dangerous modes
```

## Troubleshooting and debugging

### Debugging features:
```bash
# Enable debug logging for troubleshooting
codex --enable debug-logging exec "help me"
  
# Check feature flags status
codex features list
  
# Get detailed information about a specific feature
codez features get <feature-name>
```

### Platform-specific sandbox operations:
- **macOS**: Uses Seatbelt profile with `--log-denials` to capture macOS sandbox violations
- **Linux**: Uses Landlock+seccomp restrictions; requires kernel support for Landlock
- **Windows**: Uses restricted tokens; may require elevated privileges for certain configurations

## Integration patterns

### Using Codex with environment variables:
```bash
# Set API key via environment variable before login
OPENAI_API_KEY="your-api-key" codex login --with-api-key
  
# Use local provider configuration
codez --oss exec "help me with this local model"
```

### Working directory management:
```bash
# Change working directory for the session
codex -C /path/to/project exec "fix files in this project"
  
# Add additional directories to workspace access
codex --add-dir /tmp/some-dir exec "work with files from multiple locations"
```

## File system and tool permissions

### Workspace write vs read-only modes:
- **workspace-write**: Allows file modifications within the primary workspace directory
- **read-only**: Only allows reading files (safe for viewing sensitive information)
- **danger-full-access**: Grants full filesystem access including potentially dangerous operations

### Environment policy inheritance:
```bash
# Inherit all environment variables from shell
codex exec -c shell_environment_policy.inherit=all "show me the env"
  
# Restricted inheritance (safer)
codez --local-provider lmstudio exec "work with local model without network access"
```

## Notes

- Codex uses TOML-based configuration files by default
- Configuration values can be overridden via command line flags using dotted notation
- Most commands support both direct arguments and stdin input (using `-`)
- Sandbox modes are platform-specific and may require additional setup
- Cloud operations are experimental and subject to change
- Feature flags enable/disable specific Codex capabilities like web search, approval policies, etc.