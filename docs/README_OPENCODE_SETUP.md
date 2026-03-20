# Setup Opencode for Agentic Engineering

- [opencode](https://github.com/anomalyco/opencode)
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode?tab=readme-ov-file)
- [ai agent skills](https://github.com/julweber/ai_agent_skills/blob/main/README.md)
  - ralph loop - see https://github.com/julweber/ai_agent_skills/blob/main/ralph/README.md

## Opencode Installation

### Recommended Methods

```bash
# macOS and Linux (recommended, always up to date)
brew install anomalyco/tap/opencode

# npm/yarn/bun/pnpm
npm i -g opencode-ai@latest

# mise (any OS)
mise use -g opencode

# nix
nix run nixpkgs#opencode  # or github:anomalyco/opencode for latest dev branch

# Arch Linux (Stable)
sudo pacman -S opencode

# Arch Linux (Latest from AUR)
paru -S opencode-bin
```

### Alternative Methods

```bash
# YOLO (curl to bash)
curl -fsSL https://opencode.ai/install | bash

# Windows (scoop)
scoop install opencode

# Windows (Chocolatey)
choco install opencode

# macOS (Homebrew desktop app)
brew install --cask opencode-desktop
```

### Installation Directory

The install script respects the following priority order:

1. `$OPENCODE_INSTALL_DIR` - Custom installation directory
2. `$XDG_BIN_DIR` - XDG Base Directory Specification compliant path
3. `$HOME/bin` - Standard user binary directory (if it exists or can be created)
4. `$HOME/.opencode/bin` - Default fallback

```bash
# Examples
OPENCODE_INSTALL_DIR=/usr/local/bin curl -fsSL https://opencode.ai/install | bash
XDG_BIN_DIR=$HOME/.local/bin curl -fsSL https://opencode.ai/install | bash
```

> [!TIP]
> Remove versions older than 0.1.x before installing.

## Oh My Opcode Installation

### For Humans

Fetch the installation guide directly:

```bash
curl -s https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/refs/heads/master/docs/guide/installation.md | bash
```

Or follow the instructions at: https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/refs/heads/master/docs/guide/installation.md

### For LLM Agents

Copy and paste this prompt to your LLM agent (Claude Code, AmpCode, Cursor, etc.):

```
Install and configure oh-my-opencode by following the instructions here:
https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/refs/heads/master/docs/guide/installation.md
```

> [!NOTE]
> **Oh My OpenCode 3.0** is now stable! Use `oh-my-opencode@latest` to install it.

## Uninstallation

### Remove Oh My Opencode Plugin

1. **Remove plugin from OpenCode config**

   Edit `~/.config/opencode/opencode.json` (or `.jsonc`) and remove `"oh-my-opencode"` from the `plugin` array:

   ```bash
   # Using jq
   jq '.plugin = [.plugin[] | select(. != "oh-my-opencode")]' \
       ~/.config/opencode/opencode.json > /tmp/oc.json && \
       mv /tmp/oc.json ~/.config/opencode/opencode.json
   ```

2. **Remove configuration files (optional)**

   ```bash
   # Remove user config
   rm -f ~/.config/opencode/oh-my-opencode.json ~/.config/opencode/oh-my-opencode.jsonc

   # Remove project config (if exists)
   rm -f .opencode/oh-my-opencode.json .opencode/oh-my-opencode.jsonc
   ```

3. **Verify removal**

   ```bash
   opencode --version
   # Plugin should no longer be loaded
   ```
