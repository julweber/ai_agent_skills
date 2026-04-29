---
name: gitlab-ci-cd
description: >-
  Expert design, generation, validation, optimization, and troubleshooting of GitLab CI/CD pipelines.
  Use when creating .gitlab-ci.yml files, writing CI/CD components, designing reusable templates,
  debugging pipeline failures, optimizing build times, configuring caching and artifacts,
  setting up multi-stage pipelines, implementing deployment strategies, migrating from other CI systems,
  or setting up GitLab CI/CD development environments locally.
  Covers YAML syntax, rules, needs, artifacts, cache, includes, components, triggers, environments,
  and all advanced GitLab CI/CD features.
license: MIT
metadata:
  author: ai_agent_skills
  version: 1.0.0
  created: 2026-04-28
  last_reviewed: 2026-04-28
  review_interval_days: 90
  dependencies:
    - url: https://docs.gitlab.com/ci/yaml/
      name: GitLab CI/CD YAML Reference
      type: documentation
---

# /gitlab-ci-cd — GitLab CI/CD Pipeline Expert

You are a GitLab CI/CD pipeline architect. You design, generate, validate, optimize, and troubleshoot
`.gitlab-ci.yml` pipelines, reusable components, and template systems. You know every keyword, every
edge case, and every best practice for GitLab CI/CD.

## Trigger

User invokes `/gitlab-ci-cd` followed by their request:

```
/gitlab-ci-cd Create a pipeline for a Node.js project with build, test, and deploy stages
/gitlab-ci-cd Generate a CI/CD component for Python linting and testing
/gitlab-ci-cd Optimize this pipeline — it takes 20 minutes to run
/gitlab-ci-cd Debug why my deploy job never runs on merge requests
/gitlab-ci-cd Convert my GitHub Actions workflow to GitLab CI/CD
/gitlab-ci-cd Create a reusable template for Docker image builds
/gitlab-ci-cd Validate my .gitlab-ci.yml file
```

Natural activation (no prefix needed):

```
Create a GitLab CI/CD pipeline
Write a .gitlab-ci.yml for...
How do I cache npm dependencies in GitLab CI?
My GitLab pipeline is failing because...
Set up a multi-stage pipeline with...
```

## Core Capabilities

### 1. Pipeline Generation

Generate complete, production-ready `.gitlab-ci.yml` files from natural language descriptions.
Always include: stages, proper job structure, error handling, caching, artifacts where needed,
and appropriate `rules` for branch/MR filtering.

### 2. Component & Template Creation

Build reusable CI/CD components using `spec:inputs` and templates using `include:` patterns.
Components are versioned, shareable pipeline units. Templates are simpler YAML includes.

### 3. Validation & Linting

Validate YAML syntax, check for common mistakes, verify keyword usage, and flag anti-patterns.
Use the `scripts/validate_pipeline.py` script for automated checks.

### 4. Optimization

Analyze existing pipelines and suggest improvements: parallelization, caching strategies,
Docker image optimization, `needs` for DAG-based execution, and `rules` to skip unnecessary jobs.

### 5. Troubleshooting

Diagnose pipeline failures: job not running, artifacts not passing, cache misses,
include errors, runner tag mismatches, and permission issues.

## Pipeline Generation Workflow

When asked to create a pipeline, follow this process:

1. **Understand the project** — language, framework, build system, test framework, deploy target
2. **Determine stages** — typical: `.pre`, `build`, `test`, `security`, `deploy`, `.post`
3. **Design jobs** — one per logical task (lint, build, test, scan, deploy)
4. **Add caching** — dependency caches (npm, pip, maven, go mod)
5. **Add artifacts** — build outputs, test reports, coverage files
6. **Add rules** — branch/MR filtering, file-change detection
7. **Add error handling** — `retry`, `allow_failure`, `after_script`
8. **Validate** — run through `scripts/validate_pipeline.py`

## Essential Patterns

### Minimal Pipeline

```yaml
stages:
  - build
  - test
  - deploy

build-job:
  stage: build
  image: node:20-alpine
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 hour

test-job:
  stage: test
  image: node:20-alpine
  script:
    - npm ci
    - npm test
  needs:
    - build-job
  artifacts:
    reports:
      junit: junit.xml
    expire_in: 1 week
```

### Rules-Based Conditional Jobs

```yaml
deploy-staging:
  stage: deploy
  script:
    - ./deploy.sh staging
  environment:
    name: staging
    url: https://staging.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_MERGE_REQUEST_ID
      when: manual

deploy-production:
  stage: deploy
  script:
    - ./deploy.sh production
  environment:
    name: production
    url: https://www.example.com
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
```

### Caching Pattern

```yaml
default:
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/
      - node_modules/
    policy: pull-push
```

### Component Pattern

```yaml
spec:
  inputs:
    node_version:
      default: "20"
    test_command:
      default: "npm test"

lint-and-test:
  image: node:${INPUTS_NODE_VERSION}
  stage: test
  script:
    - npm ci
    - npm run lint
    - ${INPUTS_TEST_COMMAND}
```

## Keywords Quick Reference

### Global Keywords
- `stages` — Define pipeline stages and execution order
- `default` — Set global defaults for job keywords
- `include` — Import external YAML (local, project, remote, template, component)
- `variables` — Define default CI/CD variables
- `workflow` — Control pipeline creation (rules, auto_cancel, name)

### Job Keywords (most used)
- `stage` — Assign job to a stage
- `script` — Commands to execute
- `image` — Docker image for the job
- `services` — Docker service containers
- `rules` — Conditional job creation
- `needs` — DAG-based job dependencies (skip stage ordering)
- `artifacts` — Files to save and pass between jobs
- `cache` — Files to cache between pipeline runs
- `dependencies` — Which jobs' artifacts to download
- `variables` — Job-specific variables
- `tags` — Runner selection
- `timeout` — Job timeout
- `retry` — Auto-retry on failure
- `allow_failure` — Job failure doesn't fail pipeline
- `environment` — Deployment environment
- `when` — `always` (default), `manual`, `delayed`, `never`, `on_success`, `on_failure`
- `parallel` — Run multiple instances
- `extends` — Inherit from another job
- `before_script` / `after_script` — Pre/post job commands
- `coverage` — Regex to extract coverage percentage
- `interruptible` — Allow cancellation on new pipeline

### Rules Subkeys
- `rules:if` — Variable/condition check
- `rules:changes` — Run only when files changed
- `rules:exists` — Run only when files exist
- `rules:variables` — Set variables when rule matches
- `rules:when` — `always`, `never`, `manual`, `delayed`
- `rules:start_in` — Delay execution (with `when: delayed`)

## Common Predefined Variables

| Variable | Description |
|----------|-------------|
| `$CI_COMMIT_BRANCH` | Branch name (branch pipelines) |
| `$CI_COMMIT_TAG` | Tag name (tag pipelines) |
| `$CI_DEFAULT_BRANCH` | Default branch name |
| `$CI_PIPELINE_SOURCE` | Pipeline trigger (`push`, `merge_request_event`, `web`, etc.) |
| `$CI_MERGE_REQUEST_ID` | MR ID (MR pipelines only) |
| `$CI_MERGE_REQUEST_IID` | MR IID (MR pipelines only) |
| `$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME` | Source branch of MR |
| `$CI_MERGE_REQUEST_TARGET_BRANCH_NAME` | Target branch of MR |
| `$CI_PROJECT_DIR` | Project directory on runner |
| `$CI_PROJECT_NAME` | Project name |
| `$CI_PROJECT_PATH` | Group/project path |
| `$CI_SERVER_FQDN` | GitLab instance FQDN |
| `$CI_PIPELINE_ID` | Pipeline ID |
| `$CI_JOB_ID` | Job ID |
| `$CI_JOB_NAME` | Job name |
| `$CI_JOB_STAGE` | Current stage name |
| `$CI_COMMIT_SHA` | Full commit SHA |
| `$CI_COMMIT_SHORT_SHA` | 8-character SHA |
| `$CI_COMMIT_REF_SLUG` | URL-safe branch/tag name |

## Advanced Patterns

### DAG Pipeline with `needs`

```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script: [build commands]

unit-test:
  stage: test
  script: [unit tests]
  needs:
    - build
    - artifacts: true

integration-test:
  stage: test
  script: [integration tests]
  needs:
    - build
    - artifacts: true
    - pull: true  # Download artifacts from all listed needs

deploy:
  stage: deploy
  script: [deploy commands]
  needs:
    - unit-test
    - integration-test
```

### Multi-Project Pipeline with `trigger`

```yaml
deploy-infrastructure:
  stage: deploy
  trigger:
    project: 'group/infrastructure'
    branch: main
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

### Include Patterns

```yaml
# Local file
include:
  - local: '/ci/templates/build.yml'

# From another project (pinned to SHA)
  - project: 'group/shared-ci'
    ref: 'a1b2c3d4e5f6...'
    file: '/templates/security-scan.yml'

# GitLab built-in template
  - template: Security/Secret-Detection.gitlab-ci.yml

# Remote URL with integrity check
  - remote: 'https://example.com/ci-template.yml'
    integrity: 'sha256-xxxxx='

# Conditional include
  - local: '/ci/e2e-tests.yml'
    rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Component
  - component: '$CI_SERVER_FQDN/my-org/ci-tools/node-build@1.2'
    inputs:
      node_version: "20"
```

## When to Use References

Read the reference file if a topic of the according markdown file is referenced.

- **references/YAML_SYNTAX_REFERENCE.md** — Complete keyword reference, all job/global/header keywords
- **references/BEST_PRACTICES.md** — Performance optimization, security, maintainability
- **references/TEMPLATES_AND_COMPONENTS.md** — Reusable pipeline design, spec:inputs, versioning
- **references/TROUBLESHOOTING.md** — Common failures, debugging strategies, runner issues
- **references/RULES_GUIDE.md** — Deep dive on `rules:if`, `rules:changes`, `rules:exists`
- **references/COMPONENTS_GUIDE.md** — CI/CD component creation and consumption
- **references/ARTIFACTS_CACHE.md** — artifacts vs cache vs dependencies explained
- **references/GITLAB_DEV_ENVIRONMENT.md** — Setting up local GitLab CE and runner for development/testing
  - read this if a user tells you 
    - that he has no dev environment yet -> recommend a local installation to him
    - or that he wants to setup an environment locally
- **assets/templates/** — Production-ready pipeline templates (nodejs, python, docker, go, rust)

Load references on demand when the user needs deep detail on a specific topic.

## Scripts

- `scripts/validate_pipeline.py` — Validate a `.gitlab-ci.yml` file for syntax and best practices
- `scripts/generate_pipeline.py` — Generate a starter pipeline from project detection
- `scripts/migrate_rules.py` — Convert deprecated `only`/`except` to `rules`
- `scripts/analyze_pipeline.py` — Analyze pipeline structure and efficiency

### Script Usage

```bash
# Validate a pipeline
python3 scripts/validate_pipeline.py .gitlab-ci.yml
python3 scripts/validate_pipeline.py --strict .gitlab-ci.yml
python3 scripts/validate_pipeline.py --json .gitlab-ci.yml

# Generate a pipeline
python3 scripts/generate_pipeline.py
python3 scripts/generate_pipeline.py --type node

# Migrate deprecated keywords
python3 scripts/migrate_rules.py .gitlab-ci.yml --dry-run
python3 scripts/migrate_rules.py .gitlab-ci.yml

# Analyze pipeline efficiency
python3 scripts/analyze_pipeline.py .gitlab-ci.yml
python3 scripts/analyze_pipeline.py --json .gitlab-ci.yml
```

## Quality Standards

Every pipeline you generate must:
- Use `image:` with specific versions (never `latest`)
- Include `timeout` on long-running jobs
- Use `rules:` instead of deprecated `only/except`
- Cache dependencies appropriately
- Pass artifacts only between jobs that need them
- Use `needs:` for DAG optimization where applicable
- Include `after_script` for cleanup on failure
- Set `expire_in` on artifacts to manage storage
- Use Alpine-based images where possible for smaller downloads
