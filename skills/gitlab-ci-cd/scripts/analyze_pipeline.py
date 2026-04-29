#!/usr/bin/env python3
"""
GitLab CI/CD Pipeline Analyzer

Analyzes a .gitlab-ci.yml file and produces a structured report with:
- Stage and job inventory
- Dependency graph analysis (needs DAG)
- Performance bottleneck detection
- Efficiency metrics and recommendations

Usage:
    python3 analyze_pipeline.py <path-to-gitlab-ci.yml> [--json]
"""

import sys
import os
import json
import argparse
from collections import defaultdict
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip3 install pyyaml")
    sys.exit(1)


class PipelineAnalyzer:
    def __init__(self, filepath):
        self.filepath = filepath
        self.data = None
        self.jobs = {}
        self.stages = []
        self.global_keywords = {
            "stages", "default", "include", "variables", "workflow", "spec",
        }
        self.job_keywords = {
            "stage", "script", "image", "services", "rules", "needs",
            "artifacts", "cache", "dependencies", "variables", "tags",
            "timeout", "retry", "allow_failure", "environment", "when",
            "parallel", "extends", "before_script", "after_script",
            "coverage", "interruptible", "trigger", "pages", "release",
            "resource_group", "manual_confirmation", "start_in",
            "inherit", "identity", "secrets", "run",
            "dast_configuration",
        }

    def load(self):
        """Load and parse the YAML file."""
        try:
            with open(self.filepath, "r", encoding="utf-8") as f:
                content = f.read()
            if not content.strip():
                raise ValueError("File is empty")
            self.data = yaml.safe_load(content)
            if self.data is None:
                raise ValueError("File contains no valid YAML content")
            if not isinstance(self.data, dict):
                raise ValueError(f"Root must be a YAML mapping, got {type(self.data).__name__}")
        except FileNotFoundError:
            raise ValueError(f"File not found: {self.filepath}")
        except yaml.YAMLError as e:
            raise ValueError(f"YAML parse error: {e}")

    def extract_jobs(self):
        """Extract job definitions from parsed YAML."""
        self.stages = self.data.get("stages", [])
        if not self.stages:
            self.stages = [".pre", "build", "test", "deploy", ".post"]

        for key, value in self.data.items():
            if key in self.global_keywords:
                continue
            if isinstance(value, dict):
                # Check if it looks like a job
                if any(k in value for k in self.job_keywords):
                    self.jobs[key] = value

    def analyze_dependencies(self):
        """Analyze needs DAG for parallelism opportunities."""
        dependencies = {}
        for job_name, job in self.jobs.items():
            needs = job.get("needs")
            if needs:
                if isinstance(needs, list):
                    dep_list = []
                    for need in needs:
                        if isinstance(need, str):
                            dep_list.append(need)
                        elif isinstance(need, dict):
                            dep_list.append(need.get("job", need.get("name", "")))
                    dependencies[job_name] = dep_list
        return dependencies

    def detect_bottlenecks(self):
        """Identify performance bottlenecks."""
        bottlenecks = []

        # Check for jobs without needs (stage-bound)
        for job_name, job in self.jobs.items():
            if "needs" not in job and "script" in job:
                bottlenecks.append({
                    "type": "stage_bound",
                    "severity": "info",
                    "job": job_name,
                    "message": f"Job '{job_name}' has no 'needs' — waits for entire stage to complete",
                    "recommendation": "Add 'needs' to start as soon as dependencies complete"
                })

        # Check for long-running jobs without timeout
        for job_name, job in self.jobs.items():
            if "script" in job and "timeout" not in job:
                bottlenecks.append({
                    "type": "no_timeout",
                    "severity": "warning",
                    "job": job_name,
                    "message": f"Job '{job_name}' has no 'timeout' set",
                    "recommendation": "Add 'timeout: 30m' to prevent hung jobs"
                })

        # Check for missing cache
        has_cache = False
        for job_name, job in self.jobs.items():
            if "cache" in job or (job.get("default", {}).get("cache") if isinstance(job.get("default"), dict) else False):
                has_cache = True
                break
        if not has_cache:
            bottlenecks.append({
                "type": "no_cache",
                "severity": "info",
                "job": "global",
                "message": "No cache configured in pipeline",
                "recommendation": "Add cache for dependency management (npm, pip, etc.)"
            })

        # Check for missing interruptible
        for job_name, job in self.jobs.items():
            if "interruptible" not in job and "script" in job:
                bottlenecks.append({
                    "type": "no_interruptible",
                    "severity": "info",
                    "job": job_name,
                    "message": f"Job '{job_name}' is not interruptible",
                    "recommendation": "Add 'interruptible: true' for long-running jobs"
                })

        return bottlenecks

    def analyze_artifacts(self):
        """Analyze artifact usage patterns."""
        analysis = {
            "jobs_with_artifacts": [],
            "jobs_without_artifacts": [],
            "potential_issues": [],
        }

        for job_name, job in self.jobs.items():
            if "artifacts" in job:
                analysis["jobs_with_artifacts"].append(job_name)
                artifacts = job["artifacts"]
                if "expire_in" not in artifacts:
                    analysis["potential_issues"].append({
                        "type": "no_expiry",
                        "severity": "warning",
                        "job": job_name,
                        "message": f"Job '{job_name}' artifacts have no 'expire_in'",
                        "recommendation": "Set 'expire_in' to manage storage"
                    })
            else:
                analysis["jobs_without_artifacts"].append(job_name)

        return analysis

    def calculate_efficiency_score(self):
        """Calculate a pipeline efficiency score (0-100)."""
        score = 50  # Base score

        # +10 for using needs DAG
        needs_count = sum(1 for j in self.jobs.values() if "needs" in j)
        if needs_count > 0:
            score += 10

        # +10 for having cache
        has_cache = any("cache" in j for j in self.jobs.values())
        if has_cache:
            score += 10

        # +10 for having workflow rules
        if "workflow" in self.data:
            score += 5

        # +10 for having interruptible jobs
        interruptible_count = sum(1 for j in self.jobs.values() if j.get("interruptible"))
        if interruptible_count > 0:
            score += 5

        # -5 for each bottleneck
        bottlenecks = self.detect_bottlenecks()
        score -= len(bottlenecks) * 2

        # -5 for deprecated keywords
        deprecated_count = 0
        for job in self.jobs.values():
            deprecated_count += sum(1 for k in ["only", "except"] if k in job)
        score -= deprecated_count * 3

        # -5 for missing timeout on any job
        no_timeout = any("timeout" not in j for j in self.jobs.values() if "script" in j)
        if no_timeout:
            score -= 5

        return max(0, min(100, score))

    def generate_report(self, as_json=False):
        """Generate the full analysis report."""
        self.load()
        self.extract_jobs()

        dependencies = self.analyze_dependencies()
        bottlenecks = self.detect_bottlenecks()
        artifacts_analysis = self.analyze_artifacts()
        efficiency_score = self.calculate_efficiency_score()

        # Count jobs by stage
        stage_job_count = defaultdict(int)
        for job_name, job in self.jobs.items():
            stage = job.get("stage", "test")
            stage_job_count[stage] += 1

        # Check for parallel jobs in same stage
        parallel_opportunities = []
        for stage, job_count in stage_job_count.items():
            if stage not in [".pre", ".post"] and job_count > 1:
                parallel_opportunities.append({
                    "stage": stage,
                    "job_count": job_count,
                    "recommendation": f"Consider adding 'needs' to run these {job_count} jobs in parallel"
                })

        report = {
            "file": self.filepath,
            "summary": {
                "total_jobs": len(self.jobs),
                "stages": self.stages,
                "stage_job_distribution": dict(stage_job_count),
                "efficiency_score": efficiency_score,
                "has_dag_optimization": any("needs" in j for j in self.jobs.values()),
                "has_cache": has_cache,
                "has_workflow_rules": "workflow" in self.data,
            },
            "dependencies": dependencies,
            "bottlenecks": bottlenecks,
            "artifacts": artifacts_analysis,
            "parallel_opportunities": parallel_opportunities,
            "recommendations": [
                {
                    "priority": "high" if b["severity"] == "warning" else "medium",
                    "message": b["recommendation"],
                    "job": b["job"]
                }
                for b in bottlenecks
            ]
        }

        if as_json:
            return json.dumps(report, indent=2)
        return report


def main():
    parser = argparse.ArgumentParser(
        description="Analyze a GitLab CI/CD pipeline for performance and best practices"
    )
    parser.add_argument("filepath", help="Path to .gitlab-ci.yml file")
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()

    if not os.path.isfile(args.filepath):
        print(f"ERROR: File not found: {args.filepath}", file=sys.stderr)
        sys.exit(2)

    analyzer = PipelineAnalyzer(args.filepath)

    try:
        report = analyzer.generate_report(as_json=args.json)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    if args.json:
        print(report)
    else:
        print("=" * 60)
        print("  GitLab CI/CD Pipeline Analysis Report")
        print("=" * 60)
        print()
        print(f"File: {analyzer.filepath}")
        print(f"Total Jobs: {report['summary']['total_jobs']}")
        print(f"Stages: {', '.join(report['summary']['stages'])}")
        print(f"Efficiency Score: {report['summary']['efficiency_score']}/100")
        print()
        print("Stage Distribution:")
        for stage, count in report['summary']['stage_job_distribution'].items():
            print(f"  {stage}: {count} job(s)")
        print()
        print(f"DAG Optimization: {'Yes' if report['summary']['has_dag_optimization'] else 'No'}")
        print(f"Cache Configured: {'Yes' if report['summary']['has_cache'] else 'No'}")
        print(f"Workflow Rules: {'Yes' if report['summary']['has_workflow_rules'] else 'No'}")
        print()

        if report['bottlenecks']:
            print("Bottlenecks Detected:")
            for b in report['bottlenecks']:
                print(f"  [{b['severity'].upper()}] {b['message']}")
                print(f"    → {b['recommendation']}")
            print()

        if report['parallel_opportunities']:
            print("Parallel Execution Opportunities:")
            for opp in report['parallel_opportunities']:
                print(f"  Stage '{opp['stage']}': {opp['job_count']} jobs — {opp['recommendation']}")
            print()

        if report['recommendations']:
            print("Recommendations:")
            for rec in report['recommendations']:
                print(f"  [{rec['priority'].upper()}] {rec['message']} (job: {rec['job']})")
            print()

        print("=" * 60)


if __name__ == "__main__":
    main()
