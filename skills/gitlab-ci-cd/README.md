# GitLab CI/CD Skill

Expert skill for designing, generating, validating, and troubleshooting GitLab CI/CD pipelines.

## What It Does

- Generate production-ready `.gitlab-ci.yml` pipelines from natural language descriptions
- Create reusable CI/CD components with parameterized inputs
- Validate pipelines for syntax errors, deprecated keywords, and anti-patterns
- Optimize existing pipelines for speed and reliability
- Debug pipeline failures and runner issues
- Migrate pipelines from other CI systems (GitHub Actions, Jenkins, etc.)

## Supported Project Types

Auto-detects and generates pipelines for:
- **Node.js** (package.json)
- **Python** (requirements.txt, pyproject.toml, setup.py)
- **Go** (go.mod)
- **Rust** (Cargo.toml)
- **Java/Maven** (pom.xml, build.gradle)
- **Docker** (Dockerfile)
- **PHP** (composer.json)
- **Ruby** (Gemfile)

## Installation

### Auto-Install (Recommended)

```bash
cd gitlab-ci-cd
./install.sh
```

Detects your platform automatically and installs to the correct path.

### Install to All Detected Platforms

```bash
./install.sh --all
```

### Manual Installation

Clone or copy the skill directory to your platform's skill path:

| Platform | Path | Command |
|----------|------|---------|
| **Universal** | `~/.agents/skills/` | `cp -R gitlab-ci-cd ~/.agents/skills/` |
| Claude Code | `~/.claude/skills/` | `cp -R gitlab-ci-cd ~/.claude/skills/` |
| Cursor | `.cursor/rules/` | `cp -R gitlab-ci-cd .cursor/rules/` |
| GitHub Copilot | `.github/skills/` | `cp -R gitlab-ci-cd .github/skills/` |
| Windsurf | `.windsurf/rules/` | `cp -R gitlab-ci-cd .windsurf/rules/` |
| Cline | `.clinerules/` | `cp -R gitlab-ci-cd .clinerules/` |
| Gemini CLI | `~/.gemini/skills/` | `cp -R gitlab-ci-cd ~/.gemini/skills/` |
| Kiro | `.kiro/skills/` | `cp -R gitlab-ci-cd .kiro/skills/` |
| Trae | `.trae/rules/` | `cp -R gitlab-ci-cd .trae/rules/` |
| Roo Code | `.roo/rules/` | `cp -R gitlab-ci-cd .roo/rules/` |
| Goose | `~/.config/goose/skills/` | `cp -R gitlab-ci-cd ~/.config/goose/skills/` |
| OpenCode | `~/.config/opencode/skills/` | `cp -R gitlab-ci-cd ~/.config/opencode/skills/` |

### Platform-Specific Install

```bash
./install.sh --platform claude-code
./install.sh --platform cursor
./install.sh --platform copilot
./install.sh --platform universal
```

## Usage

Once installed, invoke in your AI coding agent:

```
/gitlab-ci-cd Create a pipeline for a Node.js project
```

Or naturally:

```
Write a .gitlab-ci.yml for my Python project
My GitLab pipeline is failing, help me debug it
Optimize this pipeline — it takes too long
Create a reusable component for Docker builds
```

## Scripts

| Script | Description |
|--------|-------------|
| `scripts/validate_pipeline.py` | Validate a `.gitlab-ci.yml` for syntax and best practices |
| `scripts/generate_pipeline.py` | Auto-detect project type and generate a starter pipeline |
| `scripts/migrate_rules.py` | Convert deprecated `only`/`except` to `rules` |
| `scripts/analyze_pipeline.py` | Analyze pipeline structure and efficiency |

### Validate a Pipeline

```bash
python3 scripts/validate_pipeline.py path/to/.gitlab-ci.yml
python3 scripts/validate_pipeline.py --strict path/to/.gitlab-ci.yml
python3 scripts/validate_pipeline.py --json path/to/.gitlab-ci.yml
```

### Generate a Starter Pipeline

```bash
python3 scripts/generate_pipeline.py
python3 scripts/generate_pipeline.py --type node
python3 scripts/generate_pipeline.py --type python /path/to/project
```

### Migrate Deprecated Keywords

```bash
python3 scripts/migrate_rules.py path/to/.gitlab-ci.yml --dry-run
python3 scripts/migrate_rules.py path/to/.gitlab-ci.yml
```

### Analyze Pipeline Efficiency

```bash
python3 scripts/analyze_pipeline.py path/to/.gitlab-ci.yml
python3 scripts/analyze_pipeline.py --json path/to/.gitlab-ci.yml
```

## References

| File | Contents |
|------|----------|
| `references/YAML_SYNTAX_REFERENCE.md` | Complete keyword reference, all job/global/header keywords |
| `references/BEST_PRACTICES.md` | Performance optimization, security, maintainability |
| `references/TEMPLATES_AND_COMPONENTS.md` | Reusable pipeline design, spec:inputs, versioning |
| `references/TROUBLESHOOTING.md` | Common failures, debugging strategies, runner issues |
| `references/RULES_GUIDE.md` | Deep dive on `rules:if`, `rules:changes`, `rules:exists` |
| `references/COMPONENTS_GUIDE.md` | CI/CD component creation and consumption |
| `references/ARTIFACTS_CACHE.md` | artifacts vs cache vs dependencies explained |
| `assets/templates/` | Production-ready pipeline templates (nodejs, python, docker, go, rust) |

## License

MIT
