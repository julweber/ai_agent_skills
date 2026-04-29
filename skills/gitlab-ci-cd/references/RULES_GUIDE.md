# GitLab CI/CD Rules — Complete Guide

Deep dive into the `rules` keyword: syntax, evaluation order, and common patterns.

## Overview

`rules` replaced the deprecated `only`/`except` keywords in GitLab 13.1+. Rules provide
more flexible and powerful job scheduling with first-match-wins evaluation.

## Rule Structure

Each rule is a dictionary with these keys:

| Key | Description |
|-----|-------------|
| `if` | Variable/condition check (required if no `when` alone) |
| `changes` | Run only when files changed |
| `exists` | Run only when files exist |
| `when` | `always`, `never`, `manual`, `delayed`, `on_success`, `on_failure` |
| `variables` | Set variables when rule matches |
| `start_in` | Delay execution (with `when: delayed`) |
| `allow_failure` | Allow failure for this rule match |
| `needs` | Require specific jobs to complete first |

## Rule Evaluation Order

1. Rules are evaluated **top to bottom**
2. **First matching rule wins** — subsequent rules are ignored
3. If no rule matches, the job is **not created**
4. A bare `when: always` (no `if`) acts as a catch-all

## Common Rule Patterns

### Branch-Based Rules

```yaml
deploy-staging:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Always run on main
    - if: $CI_MERGE_REQUEST_ID  # Also run on MR pipelines
```

### Tag-Based Rules

```yaml
deploy-production:
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/  # Semantic version tags
      when: manual
```

### File Change Detection

```yaml
run-e2e-tests:
  rules:
    - changes:
        - src/**/*.js
        - cypress/**/*
    - if: $CI_PIPELINE_SOURCE == "schedule"  # Also run on scheduled pipelines
```

### File Existence Check

```yaml
build-docker:
  rules:
    - exists:
        - Dockerfile
        - docker-compose.yml
```

### Pipeline Source Rules

```yaml
# Run on all pipeline sources except web UI
build:
  rules:
    - if: $CI_PIPELINE_SOURCE != "web"
```

### Variable-Based Rules

```yaml
# Set variables when rule matches
deploy:
  script:
    - echo "Deploying to $DEPLOY_ENV"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        DEPLOY_ENV: staging
    - if: $CI_COMMIT_TAG
      variables:
        DEPLOY_ENV: production
```

### Delayed Execution

```yaml
# Run after 1 hour delay
scheduled-deploy:
  rules:
    - if: $SCHEDULED_DEPLOY
      when: delayed
      start_in: 1 hour 30 minutes
```

### Combining Conditions

```yaml
# Multiple conditions in one rule (AND logic)
conditional-build:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      changes:
        - src/**/*
```

### Excluding with `when: never`

```yaml
# Skip draft MRs
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

## Migration from `only`/`except`

| Deprecated | Equivalent `rules` |
|------------|-------------------|
| `only: [main]` | `rules: [{if: '$CI_COMMIT_BRANCH == \"main\"}]` |
| `only: [tags]` | `rules: [{if: '$CI_COMMIT_TAG'}]` |
| `only: [merge_requests]` | `rules: [{if: '$CI_PIPELINE_SOURCE == \"merge_request_event\"}]` |
| `except: [tags]` | `rules: [{if: '$CI_COMMIT_TAG', when: never}]` |
| `only: {refs: [branches], changes: [src/]} ` | `rules: [{if: '$CI_COMMIT_BRANCH'}, {changes: [src/]}]` |

## Common Mistakes

### 1. Missing Catch-All Rule

```yaml
# BAD — pipeline won't run for unhandled commits
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_MERGE_REQUEST_ID

# GOOD — add catch-all
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - when: always  # Catch-all
```

### 2. Variable Not Available in All Pipelines

```yaml
# BAD — $CI_MERGE_REQUEST_ID is only set in MR pipelines
my-job:
  rules:
    - if: $CI_MERGE_REQUEST_ID  # Won't match in branch pipelines
      when: manual

# GOOD — check pipeline source first
my-job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      if: $CI_MERGE_REQUEST_ID
      when: manual
```

### 3. String Comparison Without Quotes

```yaml
# BAD — variable comparison without quotes
rules:
  - if: $CI_COMMIT_BRANCH == main

# GOOD — quote string values
rules:
  - if: $CI_COMMIT_BRANCH == "main"
```

---

## Source URLs

| Topic | URL |
|-------|-----|
| `rules` keyword | https://docs.gitlab.com/ci/yaml/#rules |
| `rules:if` | https://docs.gitlab.com/ci/yaml/#rulesif |
| `rules:changes` | https://docs.gitlab.com/ci/yaml/#ruleschanges |
| `rules:exists` | https://docs.gitlab.com/ci/yaml/#rulesexists |
| `rules:when` | https://docs.gitlab.com/ci/yaml/#ruleswhen |
| `rules:variables` | https://docs.gitlab.com/ci/yaml/#rulesvariables |
| `rules:start_in` | https://docs.gitlab.com/ci/yaml/#rulesstart_in |
| `rules:allow_failure` | https://docs.gitlab.com/ci/yaml/#rulesallow_failure |
| `rules:needs` | https://docs.gitlab.com/ci/yaml/#rulesneeds |
| Deprecated keywords | https://docs.gitlab.com/ci/yaml/deprecated_keywords/ |
| Rules migration guide | https://docs.gitlab.com/ci/yaml/#migrating-from-onlyexcept-to-rules |
