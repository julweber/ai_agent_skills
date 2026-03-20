---
description: Create a pi skill from a CLI tool by auto-discovering its help docs
---
Perform the following series of actions in a row:

**CLI tool to document:** `$1`

## Step 1 — Discover all commands and flags

Run the following to gather full usage information:

```
$1 --help
$1 help        # fallback if --help not recognized
```

Then for every subcommand discovered, run:

```
$1 <subcommand> --help
```

Repeat recursively until all nested subcommands are covered. Collect all flags, arguments, defaults, environment variables, and examples.

## Step 2 — Create the skill

Use the `skill-creator` skill and follow its process to create a new skill called `$1-cli`.

If you can't find the skill-creator skill:
Notify the user and provide this repository address for installing the skill https://github.com/julweber/ai_agent_skills.

The skill should:
- Cover every subcommand, flag, and option discovered in Step 1
- Include practical usage examples for common workflows
- Note any important defaults or environment variables
- Be concise — only include what you don't already know about general CLI usage patterns
- Follow the SKILL.md format with proper YAML frontmatter

After creating the skill, confirm which file was written and show a brief summary of what it covers.
