#!/usr/bin/env python3
"""
GitLab CI/CD Pipeline Validator

Validates .gitlab-ci.yml files for:
- YAML syntax
- Required keywords (stages)
- Deprecated keywords (only/except)
- Common anti-patterns
- Best practice violations
- Security issues

Usage:
    python3 validate_pipeline.py <path-to-gitlab-ci.yml>
    python3 validate_pipeline.py --strict <path-to-gitlab-ci.yml>
"""

import sys
import os
import re
import json
import argparse
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip3 install pyyaml")
    sys.exit(1)


class ValidationResult:
    """Container for validation results."""

    def __init__(self) -> None:
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.info: List[str] = []
        self.passed: List[str] = []

    @property
    def has_errors(self) -> bool:
        return len(self.errors) > 0

    def summary(self) -> str:
        lines = []
        lines.append("")
        lines.append("=" * 60)
        lines.append("  GitLab CI/CD Pipeline Validation Report")
        lines.append("=" * 60)

        if self.passed:
            lines.append(f"\n[PASS] {len(self.passed)} checks passed")
            for p in self.passed:
                lines.append(f"  ✓ {p}")

        if self.errors:
            lines.append(f"\n[ERROR] {len(self.errors)} error(s) found")
            for e in self.errors:
                lines.append(f"  ✗ {e}")

        if self.warnings:
            lines.append(f"\n[WARN] {len(self.warnings)} warning(s) found")
            for w in self.warnings:
                lines.append(f"  ⚠ {w}")

        if self.info:
            lines.append(f"\n[INFO] {len(self.info)} informational note(s)")
            for i in self.info:
                lines.append(f"  ℹ {i}")

        lines.append("")
        status = "PASS" if not self.errors else "FAIL"
        lines.append(f"Overall: {status}")
        lines.append("=" * 60)
        return "\n".join(lines)


def load_yaml(filepath: str) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """Load and parse a YAML file, returning (data, error)."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        if not content.strip():
            return None, "File is empty"
        data = yaml.safe_load(content)
        if data is None:
            return None, "File contains no valid YAML content"
        if not isinstance(data, dict):
            return None, f"Root must be a YAML mapping, got {type(data).__name__}"
        return data, None
    except yaml.YAMLError as e:
        return None, f"YAML parse error: {e}"
    except FileNotFoundError:
        return None, f"File not found: {filepath}"
    except PermissionError:
        return None, f"Permission denied: {filepath}"


def check_stages(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check that stages are defined or default stages are acceptable."""
    if "stages" in data:
        stages = data["stages"]
        if not isinstance(stages, list):
            result.errors.append("'stages' must be a list")
            return
        if not stages:
            result.warnings.append("'stages' is defined but empty")
        else:
            result.passed.append("stages defined: " + ", ".join(stages))

            # Check for duplicate stages
            if len(stages) != len(set(stages)):
                result.errors.append("Duplicate stages detected")

            # Check for reserved stage names used incorrectly
            reserved = {".pre", ".post"}
            for stage in stages:
                if stage in reserved:
                    result.warnings.append(
                        f"Explicitly defining reserved stage '{stage}' — "
                        f"this is valid but usually unnecessary"
                    )
    else:
        result.info.append(
            "No 'stages' defined — using defaults: .pre, build, test, deploy, .post"
        )


def check_deprecated_keywords(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check for deprecated keywords like only/except."""
    deprecated = {"only", "except"}
    job_keys = {
        k for k in data.keys()
        if k not in {
            "stages", "default", "include", "variables", "workflow", "spec",
            ".pre", ".post",
        }
        and isinstance(data.get(k), dict)
    }

    for job_name in job_keys:
        job = data[job_name]
        for dep in deprecated:
            if dep in job:
                result.warnings.append(
                    f"Job '{job_name}' uses deprecated '{dep}' keyword — "
                    f"migrate to 'rules:' instead"
                )


def check_image_tags(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check that Docker images don't use 'latest' tag."""
    job_keys = {
        k for k in data.keys()
        if isinstance(data.get(k), dict)
    }

    for job_name in job_keys:
        job = data[job_name]
        image = job.get("image")
        if image:
            if isinstance(image, str) and image.endswith(":latest"):
                result.warnings.append(
                    f"Job '{job_name}' uses ':latest' tag for image '{image}' — "
                    f"pin to a specific version for reproducibility"
                )
            elif isinstance(image, str) and ":" not in image:
                result.warnings.append(
                    f"Job '{job_name}' uses image '{image}' without version tag — "
                    f"defaults to ':latest'"
                )

    # Check default image
    default = data.get("default", {})
    if isinstance(default, dict):
        image = default.get("image")
        if image:
            if isinstance(image, str) and image.endswith(":latest"):
                result.warnings.append(
                    f"default image uses ':latest' tag — pin to specific version"
                )


def check_artifacts_expiry(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check that artifacts have expire_in set."""
    job_keys = {
        k for k in data.keys()
        if isinstance(data.get(k), dict)
    }

    for job_name in job_keys:
        job = data[job_name]
        artifacts = job.get("artifacts")
        if artifacts and isinstance(artifacts, dict):
            if "expire_in" not in artifacts:
                result.info.append(
                    f"Job '{job_name}' has artifacts without 'expire_in' — "
                    f"consider setting expiry to manage storage"
                )


def check_needs_artifacts(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check needs keyword usage."""
    job_keys = {
        k for k in data.keys()
        if isinstance(data.get(k), dict)
    }

    for job_name in job_keys:
        job = data[job_name]
        needs = job.get("needs")
        if needs:
            if isinstance(needs, list):
                for need_item in needs:
                    if isinstance(need_item, dict) and "artifacts" in need_item:
                        pass  # Valid explicit artifacts control
                    elif isinstance(need_item, str):
                        # String form downloads artifacts by default — just info
                        pass


def check_include_patterns(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check include patterns for best practices."""
    includes = data.get("include")
    if not includes:
        return

    if isinstance(includes, str):
        includes = [includes]

    if not isinstance(includes, list):
        result.errors.append("'include' must be a list or string")
        return

    for i, inc in enumerate(includes):
        if isinstance(inc, str):
            # Short form — could be local or remote
            if inc.startswith("http://") or inc.startswith("https://"):
                result.warnings.append(
                    f"Include #{i+1} uses remote URL without 'integrity' hash — "
                    f"consider adding integrity check for security"
                )
        elif isinstance(inc, dict):
            if "remote" in inc and "integrity" not in inc:
                result.warnings.append(
                    f"Remote include '{inc['remote']}' has no 'integrity' hash — "
                    f"add integrity check for supply chain security"
                )
            if "project" in inc and "ref" not in inc:
                result.info.append(
                    f"Project include '{inc['project']}' has no 'ref' pinned — "
                    f"consider pinning to a specific SHA or tag"
                )


def check_workflow_rules(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check workflow configuration."""
    workflow = data.get("workflow")
    if workflow and isinstance(workflow, dict):
        rules = workflow.get("rules")
        if rules:
            # Check if there's a catch-all rule
            has_catch_all = any(
                isinstance(r, dict) and "if" not in r
                for r in rules
            )
            if not has_catch_all:
                result.warnings.append(
                    "workflow:rules has no catch-all (no bare 'when: always') — "
                    "some pipelines may not run"
                )
            result.passed.append("workflow:rules configured")


def check_job_structure(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check basic job structure."""
    global_keywords = {
        "stages", "default", "include", "variables", "workflow", "spec",
    }

    jobs = []
    for key, value in data.items():
        if key in global_keywords:
            continue
        if isinstance(value, dict):
            # Check if it looks like a job (has job-level keywords)
            job_keywords = {
                "stage", "script", "image", "services", "rules", "needs",
                "artifacts", "cache", "dependencies", "variables", "tags",
                "timeout", "retry", "allow_failure", "environment", "when",
                "parallel", "extends", "before_script", "after_script",
                "coverage", "interruptible", "trigger", "pages", "release",
                "resource_group", "manual_confirmation", "start_in",
                "inherit", "identity", "secrets", "run",
                "dast_configuration",
            }
            if any(k in value for k in job_keywords):
                jobs.append(key)

    if jobs:
        result.passed.append(f"Found {len(jobs)} job(s): " + ", ".join(jobs[:10]))
        if len(jobs) > 10:
            result.passed.append(f"  ... and {len(jobs) - 10} more")
    else:
        result.warnings.append("No jobs detected in pipeline configuration")

    # Check for jobs without stage
    for job_name in jobs:
        job = data[job_name]
        if "stage" not in job and "script" in job:
            result.info.append(
                f"Job '{job_name}' has no 'stage' — defaults to 'test' stage"
            )


def check_retry_format(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check retry keyword format."""
    default = data.get("default", {})
    if isinstance(default, dict):
        retry = default.get("retry")
        if retry is not None:
            if isinstance(retry, dict):
                max_val = retry.get("max")
                when_list = retry.get("when", [])
                if max_val is not None and not isinstance(max_val, int):
                    result.errors.append("default:retry:max must be an integer")
            elif isinstance(retry, int):
                if retry < 0 or retry > 3:
                    result.warnings.append(
                        f"default:retry is {retry} — GitLab recommends 0-3 retries"
                    )


def check_cache_config(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check cache configuration."""
    default = data.get("default", {})
    if isinstance(default, dict):
        cache = default.get("cache")
        if cache:
            if isinstance(cache, dict):
                if "key" not in cache and "paths" not in cache:
                    result.errors.append("default:cache must have 'key' or 'paths'")
                if "key" in cache:
                    key = cache["key"]
                    if isinstance(key, str) and "${CI_COMMIT_SHA}" in key:
                        result.info.append(
                            "Cache key uses $CI_COMMIT_SHA — cache will be unique "
                            "per commit (no reuse across commits). Consider using "
                            "$CI_COMMIT_REF_SLUG for branch-level cache sharing."
                        )


def check_parallel_syntax(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check parallel keyword syntax."""
    job_keys = {k for k in data if isinstance(data.get(k), dict)}
    for job_name in job_keys:
        job = data[job_name]
        parallel = job.get("parallel")
        if parallel is not None:
            if isinstance(parallel, int):
                if parallel < 1:
                    result.errors.append(
                        f"Job '{job_name}': parallel matrix count must be >= 1"
                    )
            elif isinstance(parallel, dict):
                matrix = parallel.get("matrix")
                if not matrix:
                    result.errors.append(
                        f"Job '{job_name}': parallel dict requires 'matrix' key"
                    )
            else:
                result.errors.append(
                    f"Job '{job_name}': parallel must be int or dict with 'matrix'"
                )


def check_security_issues(data: Dict[str, Any], result: ValidationResult) -> None:
    """Check for security issues in the pipeline configuration."""
    # Patterns that might indicate hardcoded secrets
    secret_patterns = [
        r'password\s*[:=]\s*["\x27][^"\x27]+["\x27]',
        r'secret\s*[:=]\s*["\x27][^"\x27]+["\x27]',
        r'api[_-]?key\s*[:=]\s*["\x27][^"\x27]+["\x27]',
        r'token\s*[:=]\s*["\x27][^"\x27]+["\x27]',
        r'access[_-]?key\s*[:=]\s*["\x27][^"\x27]+["\x27]',
    ]

    # Check for hardcoded secrets in script blocks
    job_keys = {k for k in data if isinstance(data.get(k), dict)}
    for job_name in job_keys:
        job = data[job_name]

        # Check script content
        script = job.get("script", [])
        if isinstance(script, str):
            script = [script]
        if isinstance(script, list):
            for line in script:
                for pattern in secret_patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        result.warnings.append(
                            f"Job '{job_name}': Potential hardcoded secret in script — "
                            f"use CI/CD variables instead"
                        )

        # Check for DOCKER_SOCKET or privileged usage
        before_script = job.get("before_script", [])
        if isinstance(before_script, str):
            before_script = [before_script]
        if isinstance(before_script, list):
            for line in before_script:
                if "DOCKER_SOCKET" in line or "/var/run/docker.sock" in line:
                    result.warnings.append(
                        f"Job '{job_name}': Docker socket mounted — "
                        f"privileged container usage detected"
                    )

    # Check for deploy jobs without environment
    for job_name in job_keys:
        job = data[job_name]
        if "deploy" in job_name.lower() and "script" in job and "environment" not in job:
            result.warnings.append(
                f"Deploy job '{job_name}' has no 'environment' — "
                f"add environment for deployment tracking and protection"
            )

    # Check for allow_failure on security-sensitive jobs
    security_keywords = ["sast", "dast", "security", "secret", "scan", "audit"]
    for job_name in job_keys:
        job = data[job_name]
        if any(kw in job_name.lower() for kw in security_keywords):
            if job.get("allow_failure") is True:
                result.warnings.append(
                    f"Security job '{job_name}' has 'allow_failure: true' — "
                    f"security findings should not be ignored"
                )

    # Check for workflow:rules with no catch-all
    workflow = data.get("workflow")
    if workflow and isinstance(workflow, dict):
        rules = workflow.get("rules")
        if rules:
            has_catch_all = any(
                isinstance(r, dict) and "if" not in r
                for r in rules
            )
            if not has_catch_all:
                result.warnings.append(
                    "workflow:rules has no catch-all — "
                    "pipelines may not run for all commits"
                )


def validate(filepath: str, strict: bool = False) -> ValidationResult:
    """Run all validation checks on a pipeline file."""
    result = ValidationResult()

    data, err = load_yaml(filepath)
    if err:
        result.errors.append(err)
        return result

    result.passed.append("YAML syntax is valid")

    # Run all checks
    check_stages(data, result)
    check_deprecated_keywords(data, result)
    check_image_tags(data, result)
    check_artifacts_expiry(data, result)
    check_needs_artifacts(data, result)
    check_include_patterns(data, result)
    check_workflow_rules(data, result)
    check_job_structure(data, result)
    check_retry_format(data, result)
    check_cache_config(data, result)
    check_parallel_syntax(data, result)
    check_security_issues(data, result)

    if strict:
        # In strict mode, promote warnings to errors
        if result.warnings:
            result.errors.extend(result.warnings)
            result.warnings = []

    return result


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate a GitLab CI/CD pipeline file"
    )
    parser.add_argument("filepath", help="Path to .gitlab-ci.yml file")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as errors",
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

    result = validate(args.filepath, strict=args.strict)

    if args.json:
        output = {
            "valid": not result.has_errors,
            "errors": result.errors,
            "warnings": result.warnings,
            "info": result.info,
            "passed": result.passed,
        }
        print(json.dumps(output, indent=2))
    else:
        print(result.summary())

    sys.exit(1 if result.has_errors else 0)


if __name__ == "__main__":
    main()
