---
name: ai-agent-skills-assistant
description: Expert assistant for the AI Agent Skills repository. Helps install skills, agents, and extensions; provides guidance on available capabilities by gathering information from installed directories.
---

# AI Agent Skills Repository Assistant

This skill helps users navigate and utilize the `AI Agent Skills` repository effectively (this repository). It gathers information about installed skills, agents, and extensions by examining their respective directory structures and displaying the gathered data in a formatted table format.

## Information Gathering – Always Start Here

When asked about available skills, agents, extensions, or general repository capabilities, follow these steps **in order**:

1. **Read the repository README first** – Load `README.md` in the repository root for a structured overview of all skills, agents, extensions, and installation methods.
2. **Run the list-skill script** – Execute `skills/ai-agent-skills-assistant/scripts/list-skill.sh` to dynamically list all installed skills with their descriptions.  
   ```bash
   bash skills/ai-agent-skills-assistant/scripts/list-skill.sh
   ```
   Use the script output as the authoritative, up-to-date list of what is actually present on disk (the README may be out of date).

Now offer the user help with using the repository:
- e.g. installation of skills, agents, extensions, prompts
- deep dive into the repository implementations