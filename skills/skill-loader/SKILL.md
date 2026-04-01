---
name: skill-loader
description: Use when discovering skills from custom local skill collections stored in specific directories. Activates on /skill-loader, load skills, discover skills, or skill collection queries.
license: MIT
metadata:
  author: Julian Weber
  version: 1.0.0
---

# /skill-loader — Discover Local Skills

## Triggering Conditions

**Use when:**
- You need to discover what skills are available in a local collection before selecting which to load for current task
- User asks about available skills, skill collections, or wants to explore custom skill directories
- Query contains `/skill-loader`, "load skills", "discover skills", or "available skills"
- You're working with custom skill collections stored in specific directories (superpowers, ai-agent-skills, obsidian-skills)

**NOT for:**
- Reading individual SKILL.md files directly - let the script handle discovery
- Manual directory listing without YAML frontmatter parsing
- Skills outside your configured local collection directories

## Trigger

User invokes `/skill-loader` followed by a skill group name:

```
/skill-loader superpowers
/skill-loader ai-agent-skills
/skill-loader obsidian-skills
```

Or naturally without the prefix:

```
Load skills from the superpowers collection
What skills are available in ai-agent-skills?
Discover what's in my local skill collections
```

The script looks up the skill group in `index.yaml` and extracts metadata from all SKILL.md files automatically, outputting results in JSON format by default.

## How to Use

### Direct Command

```bash
python3 scripts/extract_skill_metadata.py <skill-group-name>
```

### Example Output (JSON)

The script outputs available skills in JSON format by default:
```json
[
  {
    "name": "superpowers-tdd",
    "description": "Use when implementing test-driven development workflows",
    "location": "/home/user/skills/superpowers/skills/tdd/SKILL.md",
    "original_name": "tdd"
  },
  {
    "name": "superpowers-planning",
    "description": "Use for systematic project planning and task breakdown",
    "location": "/home/user/skills/superpowers/skills/planning/SKILL.md",
    "original_name": "planning"
  }
]
```

## Skill Discovery

**Activation keywords:**
- `/skill-loader` followed by a skill group name
- `load skills`, `discover skills`, `available skills`

## Discipline Enforcement Table

| Excuse | Reality |
|--------|---------|
| "I'll just list the directory" | Misses YAML frontmatter parsing, metadata extraction logic |
| "Just read SKILL.md files manually" | Skips path expansion (~ → home), prefix handling, format selection (--format=xml) |
| "Agent discovers it naturally" | Without skill, agent may not know to run Python script at all |
| "Script is just a helper" | Script handles edge cases: missing index.yaml, empty directories, permission errors |
| "I can grep for SKILL.md files" | Skips YAML parsing, name/description extraction, location tracking |

**Core principle:** The script automates what would otherwise be tedious manual discovery. Trust the mechanism.

## Common Excuses (and Why They're Wrong)

| Excuse | Reality |
|--------|---------|
| "I'll skip this and just list skills manually" | Manual listing misses YAML frontmatter, returns inconsistent format |
| "The script is optional overhead" | Script handles ~ expansion, error handling, format selection automatically |
| "Agent can figure it out without the skill" | Agent needs to know to run `python3 scripts/extract_skill_metadata.py` |

## Pressure Scenarios

**Scenario: Agent forgets `/skill-loader` prefix**

Input: "Load skills from superpowers"
Expected: Script still runs via `extract_skill_metadata.py superpowers`

**Scenario: index.yaml missing or corrupted**

Agent should see clear error message with available groups listed.

**Scenario: No SKILL.md files in directory**

Output empty JSON array `[]` instead of failing silently.

## Rules
- Output discovered skills in JSON format by default
- Skip the full skill list output to user-facing chat if too verbose (14+ items)
- Run script via `python3 scripts/extract_skill_metadata.py <group-name>`
- Don't manually parse SKILL.md files - let the script handle YAML extraction