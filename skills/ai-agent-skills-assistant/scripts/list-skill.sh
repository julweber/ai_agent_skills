#!/usr/bin/env bash
# Simple command-line script to list skills in a directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ ! -d "$SKILLS_DIR" ]]; then
    echo "No skills directory found at: $SKILLS_DIR"
    exit 1
fi

echo "Available Skills in: $SKILLS_DIR"
echo ""

mapfile -t skill_dirs < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | while read -r dir; do
    [[ -f "${dir}/SKILL.md" ]] && echo "$dir"
done)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
    exit 1
fi

for skill_dir in "${skill_dirs[@]}"; do
    skill_name=$(basename "$skill_dir")

    if [[ -f "${skill_dir}/SKILL.md" ]]; then
        desc=$(grep -E "^description:" "${skill_dir}/SKILL.md" | head -1 | sed 's/^description:[[:space:]]*//' | cut -c1-50)
        echo "Skill: $skill_name ($desc)"
    else
        echo "No SKILL.md found for: $skill_name"
    fi

    echo ""
done

exit 0
