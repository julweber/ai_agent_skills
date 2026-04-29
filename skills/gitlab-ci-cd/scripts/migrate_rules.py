#!/usr/bin/env python3
"""
GitLab CI/CD Rules Migration Tool

Converts deprecated 'only'/'except' keywords to modern 'rules' syntax.

Usage:
    python3 migrate_rules.py <path-to-gitlab-ci.yml> [--dry-run] [--json]
"""

import sys
import os
import re
import json
import argparse
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip3 install pyyaml")
    sys.exit(1)


# Mapping of deprecated patterns to rules equivalents
DEPRECATED_PATTERNS = {
    "branches": "CI_COMMIT_BRANCH",
    "tags": "CI_COMMIT_TAG",
    "merge_requests": "CI_PIPELINE_SOURCE",
    "web": "CI_PIPELINE_SOURCE",
    "schedules": "CI_PIPELINE_SOURCE",
    "api": "CI_PIPELINE_SOURCE",
    "push": "CI_PIPELINE_SOURCE",
    "pull_request": "CI_PIPELINE_SOURCE",
}


def only_to_rules(only_value, is_except=False):
    """Convert an 'only' or 'except' value to equivalent 'rules'."""
    rules = []

    if isinstance(only_value, str):
        # Single string value
        if is_except:
            # except: "branches" → rules:if: CI_COMMIT_TAG (run on tags only)
            rules.append({
                "if": f"$CI_COMMIT_TAG",
                "when": "never"
            })
        else:
            # only: "branches" → rules:if: CI_COMMIT_BRANCH
            rules.append({
                "if": f"$CI_COMMIT_BRANCH",
                "when": "always"
            })
        return rules

    if isinstance(only_value, list):
        # List of values
        conditions = []
        for val in only_value:
            if val in DEPRECATED_PATTERNS:
                var_name = DEPRECATED_PATTERNS[val]
                if is_except:
                    # except in list means "exclude these"
                    if val == "tags":
                        conditions.append({"if": "$CI_COMMIT_TAG", "when": "never"})
                    elif val == "merge_requests":
                        conditions.append({"if": "$CI_PIPELINE_SOURCE == 'merge_request_event'", "when": "never"})
                    else:
                        conditions.append({"if": f"${var_name}", "when": "never"})
                else:
                    # only in list means "include these"
                    if val == "tags":
                        conditions.append({"if": "$CI_COMMIT_TAG", "when": "always"})
                    elif val == "merge_requests":
                        conditions.append({"if": "$CI_PIPELINE_SOURCE == 'merge_request_event'", "when": "always"})
                    else:
                        conditions.append({"if": f"${var_name}", "when": "always"})

        # If no specific conditions matched, add fallback
        if not conditions:
            for val in only_value:
                if is_except:
                    rules.append({"if": val, "when": "never"})
                else:
                    rules.append({"if": val, "when": "always"})
        else:
            rules.extend(conditions)
        return rules

    if isinstance(only_value, dict):
        # Dict format: only: {refs: [...], changes: [...]}
        refs = only_value.get("refs", [])
        changes = only_value.get("changes", [])
        exists = only_value.get("exists", [])

        if refs:
            for ref in refs:
                if is_except:
                    rules.append({"if": ref, "when": "never"})
                else:
                    rules.append({"if": ref, "when": "always"})

        if changes:
            for change_pattern in changes:
                if is_except:
                    rules.append({"changes": [change_pattern], "when": "never"})
                else:
                    rules.append({"changes": [change_pattern]})

        if exists:
            for file_pattern in exists:
                if is_except:
                    rules.append({"exists": [file_pattern], "when": "never"})
                else:
                    rules.append({"exists": [file_pattern]})

        return rules

    return rules


def migrate_file(filepath, dry_run=False, as_json=False):
    """Migrate a single file from only/except to rules."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"ERROR: File not found: {filepath}", file=sys.stderr)
        sys.exit(2)
    except PermissionError:
        print(f"ERROR: Permission denied: {filepath}", file=sys.stderr)
        sys.exit(2)

    try:
        data = yaml.safe_load(content)
    except yaml.YAMLError as e:
        print(f"ERROR: YAML parse error: {e}", file=sys.stderr)
        sys.exit(1)

    if not isinstance(data, dict):
        print("ERROR: Root must be a YAML mapping", file=sys.stderr)
        sys.exit(1)

    # Global keywords that are not jobs
    global_keywords = {
        "stages", "default", "include", "variables", "workflow", "spec",
    }

    # Track changes
    changes = []
    migrated = False

    for key, value in data.items():
        if key in global_keywords:
            continue
        if not isinstance(value, dict):
            continue

        # Check for deprecated keywords
        for dep_keyword in ["only", "except"]:
            if dep_keyword in value:
                is_except = dep_keyword == "except"
                new_rules = only_to_rules(value[dep_keyword], is_except)

                if new_rules:
                    # Add to existing rules or create new
                    if "rules" in value:
                        existing_rules = value["rules"]
                        if isinstance(existing_rules, list):
                            value["rules"].extend(new_rules)
                        else:
                            value["rules"] = [existing_rules] + new_rules
                    else:
                        value["rules"] = new_rules

                    changes.append({
                        "job": key,
                        "from": f"{dep_keyword}: {value[dep_keyword]}",
                        "to": f"rules: [{len(new_rules)} rule(s)]"
                    })
                    migrated = True
                    del value[dep_keyword]

    # Handle workflow:rules with only/except
    workflow = data.get("workflow")
    if workflow and isinstance(workflow, dict):
        w_rules = workflow.get("rules")
        if w_rules and isinstance(w_rules, list):
            for i, rule in enumerate(w_rules):
                if isinstance(rule, dict):
                    for dep_keyword in ["only", "except"]:
                        if dep_keyword in rule:
                            new_rules = only_to_rules(rule[dep_keyword], dep_keyword == "except")
                            if new_rules:
                                w_rules[i] = new_rules[0] if len(new_rules) == 1 else new_rules
                                changes.append({
                                    "job": "workflow:rules",
                                    "from": f"{dep_keyword}: {rule[dep_keyword]}",
                                    "to": f"rules: [{len(new_rules)} rule(s)]"
                                })
                                migrated = True
                                del w_rules[i][dep_keyword]

    # Output results
    if dry_run:
        if as_json:
            print(json.dumps({
                "dry_run": True,
                "migrated": migrated,
                "changes": changes
            }, indent=2))
        else:
            print("=" * 60)
            print("  DRY RUN — No files modified")
            print("=" * 60)
            if migrated:
                print(f"\nWould migrate {len(changes)} deprecated pattern(s):")
                for change in changes:
                    print(f"  Job: {change['job']}")
                    print(f"    FROM: {change['from']}")
                    print(f"    TO:   {change['to']}")
                    print()
            else:
                print("\nNo deprecated patterns found.")
        return migrated

    # Write migrated file
    output_path = filepath.replace(".gitlab-ci.yml", "-migrated.yml")
    if output_path == filepath:
        output_path = filepath + ".migrated"

    with open(output_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    if as_json:
        print(json.dumps({
            "output": output_path,
            "migrated": migrated,
            "changes": changes
        }, indent=2))
    else:
        print("=" * 60)
        print("  GitLab CI/CD Rules Migration")
        print("=" * 60)
        if migrated:
            print(f"\nMigrated {len(changes)} deprecated pattern(s):")
            for change in changes:
                print(f"  Job: {change['job']}")
                print(f"    FROM: {change['from']}")
                print(f"    TO:   {change['to']}")
                print()
            print(f"Output written to: {output_path}")
        else:
            print("\nNo deprecated patterns found.")
        print("=" * 60)

    return migrated


def main():
    parser = argparse.ArgumentParser(
        description="Migrate GitLab CI/CD 'only'/'except' to 'rules'"
    )
    parser.add_argument("filepath", help="Path to .gitlab-ci.yml file")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show changes without modifying files",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()

    if not os.path.isfile(args.filepath):
        print(f"ERROR: File not found: {args.filepath}", file=sys.stderr)
        sys.exit(2)

    migrated = migrate_file(args.filepath, dry_run=args.dry_run, as_json=args.json)
    sys.exit(0)


if __name__ == "__main__":
    main()
