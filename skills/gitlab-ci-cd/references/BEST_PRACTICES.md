# GitLab CI/CD Best Practices

Performance optimization, security, and maintainability guidelines.

## Performance Optimization

### 1. Use `needs` for DAG-Based Execution

The single biggest performance win. Jobs start as soon as their dependencies complete, not when the entire previous stage finishes.

```yaml
# Slow: waits for ALL build jobs to finish
test-a:
  stage: test

test-b:
  stage: test

# Fast: starts as soon as build completes
test-a:
  stage: test
  needs: [build]

test-b:
  stage: test
  needs: [build]
```

### 2. Cache Dependencies Properly

```yaml
# GOOD: Key by lockfile + branch
cache:
  key:
    files:
      - package-lock.json
  paths:
    - node_modules/

# BAD: Key by commit SHA (no reuse)
cache:
  key: ${CI_COMMIT_SHA}
  paths:
    - node_modules/

# BAD: No key at all (uses ref name, can collide)
cache:
  paths:
    - node_modules/
```

**Cache strategies by language:**

| Language | Cache Key | Cache Paths |
|----------|-----------|-------------|
| Node.js | `package-lock.json` | `node_modules/`, `.npm/` |
| Python (pip) | `requirements.txt` | `.cache/pip/` |
| Python (poetry) | `poetry.lock` | `.cache/pypoetry/` |
| Go | `go.sum` | `.cache/go-mod/` |
| Rust | `Cargo.lock` | `target/` |
| Java (Maven) | `pom.xml` | `.m2/repository/` |
| Ruby | `Gemfile.lock` | `vendor/bundle/` |
| PHP | `composer.lock` | `vendor/`, `.composer/cache/` |

### 3. Use Alpine-Based Images

```yaml
# Fast (~50MB)
image: node:20-alpine

# Slow (~300MB+)
image: node:20
```

Smaller images = faster pulls = faster jobs.

### 4. Parallelize Independent Jobs

```yaml
# Run lint and test in parallel
lint:
  stage: test
  needs: [build]

unit-test:
  stage: test
  needs: [build]

integration-test:
  stage: test
  needs: [build]
```

### 5. Use `interruptible` for Long Jobs

```yaml
long-build:
  stage: build
  interruptible: true
  script:
    - ./build.sh
```

New commits cancel redundant running jobs instead of waiting.

### 6. Shallow Clone

```yaml
variables:
  GIT_DEPTH: "1"  # Shallow clone (default in GitLab 16.0+)
```

Reduces clone time significantly for large repos.

### 7. Pipeline-Level Auto-Cancel

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible
    on_job_failure: all
```

Stop wasting resources on obsolete pipelines.

## Security Best Practices

### 1. Pin Include References

```yaml
# GOOD: Pinned to specific SHA
include:
  - project: 'shared/ci-templates'
    ref: 'a1b2c3d4e5f6789012345678abcdef0123456789'
    file: '/templates/build.yml'

# BAD: Floating ref (can be modified)
include:
  - project: 'shared/ci-templates'
    file: '/templates/build.yml'
```

### 2. Use Integrity Checks for Remote Includes

```yaml
include:
  - remote: 'https://example.com/template.yml'
    integrity: 'sha256-L3/GAoKaw0Arw6hDCKeKQlV1QPEgHYxGBHsH4zG1IY8='
```

### 3. Never Hardcode Secrets

```yaml
# BAD
deploy:
  script:
    - docker login -u admin -p mypassword registry.example.com

# GOOD — Use CI/CD variables (Settings > CI/CD > Variables)
deploy:
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
```

### 4. Use `rules` Instead of `only/except`

`rules` is more expressive, doesn't have the branching logic bugs of `only/except`, and is the future.

### 5. Limit Artifact Retention

```yaml
artifacts:
  paths:
    - dist/
  expire_in: 1 week  # Prevents storage bloat
```

### 6. Use Protected Variables for Production

Store production secrets as protected variables (only available on protected branches/tags).

## Maintainability

### 1. Split Large Pipelines with `include`

```yaml
# .gitlab-ci.yml
include:
  - local: '/ci/build.yml'
  - local: '/ci/test.yml'
  - local: '/ci/deploy.yml'
  - local: '/ci/security.yml'

workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

### 2. Use Hidden Jobs for Templates

```yaml
# .base-job (hidden — not executed)
.base-job:
  image: node:20-alpine
  cache:
    paths:
      - node_modules/

# Actual jobs inherit from template
build:
  extends: .base-job
  stage: build
  script:
    - npm ci
    - npm run build

test:
  extends: .base-job
  stage: test
  script:
    - npm test
```

Jobs starting with `.` are not executed — they're templates.

### 3. Document Pipeline with Comments

```yaml
# ── Build Stage ───────────────────────────────────────────────────
# Builds the application and caches dependencies

# ── Test Stage ────────────────────────────────────────────────────
# Runs linting, unit tests, and integration tests in parallel

# ── Deploy Stage ──────────────────────────────────────────────────
# Deploys to staging on main, production on tags (manual)
```

### 4. Use Components for Cross-Project Reuse

```yaml
# Component (in shared repo)
spec:
  inputs:
    node_version:
      default: "20"

# Usage (in consuming project)
include:
  - component: '$CI_SERVER_FQDN/shared/ci/node-build@1.0'
    inputs:
      node_version: "22"
```

### 5. Set Reasonable Timeouts

```yaml
default:
  timeout: 30m  # Prevents hung jobs from running forever

long-test:
  timeout: 1h   # Override for known long jobs
```

## Common Anti-Patterns

### ❌ Using `latest` Tags

```yaml
# BAD
image: node:latest

# GOOD
image: node:20-alpine
```

### ❌ Downloading Artifacts from All Jobs

```yaml
# BAD — downloads ALL artifacts from ALL previous jobs
deploy:
  dependencies: []  # Empty = all jobs

# GOOD — specify exactly what you need
deploy:
  needs:
    - build
      artifacts: true
```

### ❌ No `expire_in` on Artifacts

```yaml
# BAD — artifacts stored forever
artifacts:
  paths:
    - dist/

# GOOD
artifacts:
  paths:
    - dist/
  expire_in: 1 week
```

### ❌ Running Everything in One Stage

```yaml
# BAD — all jobs block each other
stages:
  - everything

# GOOD — parallel execution within stages
stages:
  - build
  - test
  - deploy
```

### ❌ Using `cache` for Build Outputs

```yaml
# BAD — cache is not guaranteed, may be evicted
cache:
  paths:
    - dist/

# GOOD — use artifacts for build outputs
artifacts:
  paths:
    - dist/
  expire_in: 1 hour
```

## Debugging Tips

### 1. Trace Pipeline Execution

Use CI Lint (Settings > CI/CD > CI Lint) to validate before pushing.

### 2. Check Variable Expansion

```yaml
debug-variables:
  stage: .pre
  script:
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "Tag: $CI_COMMIT_TAG"
    - echo "Pipeline source: $CI_PIPELINE_SOURCE"
    - echo "MR ID: $CI_MERGE_REQUEST_ID"
    - env | sort
  when: manual
```

### 3. Verify Rules Evaluation

```yaml
debug-rules:
  stage: .pre
  script:
    - echo "This job ran!"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: always
    - when: never
  when: manual  # Override to run manually for testing
```

### 4. Check Cache Hits

Look for cache download/upload messages in job logs:
- `Downloading cache...` — Cache found
- `Uploading cache...` — Cache saved
- No cache messages — Cache key mismatch or no cache configured

---

## Source URLs

| Topic | URL |
|-------|-----|
| Pipeline efficiency guide | https://docs.gitlab.com/ci/pipelines/pipeline_efficiency/ |
| Caching in GitLab CI/CD | https://docs.gitlab.com/ci/caching/ |
| Visual guide to caching | https://about.gitlab.com/blog/a-visual-guide-to-gitlab-ci-caching/ |
| `needs` keyword (DAG optimization) | https://docs.gitlab.com/ci/yaml/#needs |
| `cache` keyword | https://docs.gitlab.com/ci/yaml/#cache |
| `artifacts` keyword | https://docs.gitlab.com/ci/yaml/#artifacts |
| `interruptible` keyword | https://docs.gitlab.com/ci/yaml/#interruptible |
| `workflow:auto_cancel` | https://docs.gitlab.com/ci/yaml/#workflowauto_cancel |
| Auto-cancel redundant pipelines | https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines |
| Shallow clones / GIT_DEPTH | https://docs.gitlab.com/ci/yaml/#clone-options |
| Include with integrity check | https://docs.gitlab.com/ci/yaml/#includeintegrity |
| CI/CD variables (secrets management) | https://docs.gitlab.com/ci/variables/ |
| Protected variables | https://docs.gitlab.com/ci/variables/#protect-a-cicd-variable |
| `rules` vs deprecated `only/except` | https://docs.gitlab.com/ci/yaml/#rules |
| Deprecated keywords | https://docs.gitlab.com/ci/yaml/deprecated_keywords/ |
| Docker executor | https://docs.gitlab.com/ci/runners/docker/ |
| Runner tags | https://docs.gitlab.com/ci/yaml/#tags |
| Pipeline performance optimization | https://oneuptime.com/blog/post/2026-01-27-gitlab-ci-performance/view |
| GitLab shared runners turbo mode | https://docs.gitlab.com/ee/ci/runners/index.md |
| GitLab CI Lint | https://docs.gitlab.com/ci/yaml/lint/ |
| GitLab's own .gitlab-ci.yml | https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml |
