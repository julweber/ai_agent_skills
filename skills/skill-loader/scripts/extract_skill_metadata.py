#!/usr/bin/env python3
"""Extract skill metadata from SKILL.md frontmatter in a skills directory."""

import sys
import yaml
from pathlib import Path


def extract_frontmatter(skill_md_path: Path) -> dict | None:
    """Extract YAML frontmatter from a SKILL.md file."""
    try:
        content = skill_md_path.read_text(encoding='utf-8')
    except Exception as e:
        print(f"Error reading {skill_md_path}: {e}", file=sys.stderr)
        return None

    # Check for YAML frontmatter (--- at start)
    if not content.startswith('---'):
        return None

    # Find the closing --- (second occurrence after position 0)
    end_marker = content.find('---', 3)
    if end_marker == -1:
        return None

    yaml_content = content[3:end_marker]

    try:
        frontmatter = yaml.safe_load(yaml_content)
        if not isinstance(frontmatter, dict):
            return None
        return frontmatter
    except yaml.YAMLError as e:
        print(f"YAML error in {skill_md_path}: {e}", file=sys.stderr)
        return None


def discover_skills(skills_dir: Path, prefix: str = "") -> list[dict]:
    """Discover all skills in a directory and extract their metadata."""
    skills = []

    if not skills_dir.exists():
        print(f"Directory not found: {skills_dir}", file=sys.stderr)
        return skills

    # Find all SKILL.md files in subdirectories
    for skill_md in skills_dir.glob("*/SKILL.md"):
        skill_dir = skill_md.parent
        metadata = extract_frontmatter(skill_md)

        if metadata:
            skill_name = metadata.get('name', skill_dir.name)
            if prefix:
                skill_name = f"{prefix}-{skill_name}"

            skills.append({
                'name': skill_name,
                'description': metadata.get('description', ''),
                'location': str(skill_md.absolute()),
                'original_name': metadata.get('name', ''),
            })

    return skills


def output_xml(skills: list[dict]) -> None:
    """Output skills in XML format for agent consumption."""
    print("<available_skills>")
    for skill in skills:
        # Escape XML special characters
        desc_escaped = (skill['description']
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;'))
        print("  <skill>")
        print(f"    <name>{skill['name']}</name>")
        print(f"    <description>{desc_escaped}</description>")
        print(f"    <location>{skill['location']}</location>")
        print("  </skill>")
    print("</available_skills>")


def output_json(skills: list[dict]) -> None:
    """Output skills in JSON format."""
    import json
    print(json.dumps(skills, indent=2))


def load_index_yaml() -> dict:
    """Load index.yaml from skill-loader directory."""
    script_path = Path(__file__).resolve()
    index_path = script_path.parent.parent / "index.yaml"

    if not index_path.exists():
        print(f"Error: index.yaml not found at {index_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(index_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"Error parsing index.yaml: {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) < 2:
        print("Usage: extract_skill_metadata.py <skill_group> [--format=xml|json]", file=sys.stderr)
        print("       where <skill_group> is a key from index.yaml (e.g., superpowers, ai-agent-skills)", file=sys.stderr)
        sys.exit(1)

    skill_group = sys.argv[1]
    output_format = "xml"

    # Load index.yaml and look up skill group
    index_data = load_index_yaml()

    if skill_group not in index_data:
        print(f"Error: Skill group '{skill_group}' not found in index.yaml", file=sys.stderr)
        print(f"Available skill groups: {', '.join(index_data.keys())}", file=sys.stderr)
        sys.exit(1)

    skills_dir = Path(index_data[skill_group])
    prefix = skill_group

    # Parse remaining arguments
    for arg in sys.argv[2:]:
        if arg.startswith("--format="):
            output_format = arg.split("=", 1)[1]

    skills = discover_skills(skills_dir, prefix)

    if output_format == "json":
        output_json(skills)
    else:
        output_xml(skills)


if __name__ == "__main__":
    main()