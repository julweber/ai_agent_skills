---
name: skill-loader
description: Discovers and loads skill metadata from multiple local skill directories. Use when you need to access skills from custom skill collections stored in different locations, or when the user mentions they want to use skills from a specific local repo/directory.
---

# Skill Loader

This skill loads skill metadata from a skill group by running the `extract_skill_metadata.py` script with a skill group name.

## When to Use This Skill

Use this skill when:
- The user asks to load skills from a specific local skill set
- You need to discover what skills are available in a specific local skill collection
- The user wants to use skills from a custom skill set

## How to Use

Run the extraction script with a skill group name:

```bash
python3 scripts/extract_skill_metadata.py <skill-group-name>
```

The script looks up the skill group in `index.yaml` and extracts metadata automatically.

## Rules
- DO NOT output the list of loaded skills to the user in the user-facing chat