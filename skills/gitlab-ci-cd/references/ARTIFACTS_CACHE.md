# Artifacts vs Cache vs Dependencies — Explained

Understanding when to use each mechanism to pass data between jobs and pipelines.

## Quick Reference

| Feature | Artifacts | Cache | Dependencies |
|---------|-----------|-------|--------------|
| Purpose | Pass build outputs between jobs | Reuse dependency files between runs | Control artifact download |
| Storage | GitLab server | Runner local + optional S3 | N/A |
| Guaranteed | Yes (reliable) | No (may be evicted) | N/A |
| Scope | Single pipeline | Cross-pipeline | N/A |
| Download Speed | Slower | Fast | N/A |
| Best For | Build outputs, reports | Dependencies, node_modules | N/A |

## Artifacts

### When to Use
- Build outputs that downstream jobs need
- Test reports (JUnit, coverage)
- Compiled binaries
- Files that must be reliable and complete

### Artifacts Configuration

```yaml
build-job:
  artifacts:
    paths:
      - dist/
      - build/
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    expire_in: 1 week
    when: on_success  # on_success (default) or always
    exclude:
      - dist/**/*.map
```

### Key Points
- Artifacts are uploaded **after** the job completes
- Artifacts are downloaded **before** the job runs (based on `needs`)
- Artifacts expire based on `expire_in` (default: 30 days)
- Artifacts are **not** shared between pipelines

## Cache

### When to Use
- Dependency directories (`node_modules/`, `.m2/`)
- Package manager caches (`.npm/`, `.cache/pip/`)
- Build tool caches (`target/`, `.cache/go-mod/`)
- Anything that speeds up repeated runs

### Cache Configuration

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: npm-${CI_COMMIT_REF_SLUG}
  paths:
    - node_modules/
    - .npm/
  policy: pull-push  # pull-push (default), pull, push
  when: on_success
```

### Cache Policies

| Policy | Pull | Push | Use Case |
|--------|------|------|----------|
| `pull-push` (default) | Yes | Yes | Most cases |
| `pull` | Yes | No | Read-only cache |
| `push` | No | Yes | Write-only cache |

### Key Points
- Cache is **not guaranteed** — may be evicted or unavailable
- Cache is **shared between pipelines** on the same branch
- Cache keys should be stable (use `package-lock.json` or `go.sum`)
- Cache is **fast** — stored on runner locally

## Dependencies

### When to Use
- Control which jobs' artifacts to download
- Reduce download time by only fetching needed artifacts
- Fine-tune artifact transfer in `needs` DAG pipelines

### Dependencies Configuration

```yaml
deploy:
  dependencies:
    - build-job
    - package-job
  # Only downloads artifacts from build-job and package-job
```

### Dependencies vs Needs

| Keyword | Controls | Respects Stage Order |
|---------|----------|---------------------|
| `dependencies` | Artifact download only | Yes |
| `needs` | Execution order AND artifacts | No (DAG) |

### Example

```yaml
# Without dependencies — downloads ALL artifacts from ALL previous jobs
deploy:
  stage: deploy
  script:
    - deploy.sh

# With dependencies — only downloads what you need
deploy:
  stage: deploy
  dependencies:
    - build-job
  script:
    - deploy.sh

# With needs (DAG) — best for parallel execution
deploy:
  stage: deploy
  needs:
    - build-job
      artifacts: true
    - test-job
      artifacts: false
  script:
    - deploy.sh
```

## Decision Matrix

```
Need to pass data between jobs?
├── Is it a build output? → Use ARTIFACTS
├── Is it a dependency? → Use CACHE
└── Do you want to control which artifacts to download? → Use DEPENDENCIES

Need to speed up repeated runs?
└── Use CACHE

Need reliable data transfer?
└── Use ARTIFACTS

Need cross-pipeline data sharing?
└── Use CACHE
```

## Common Mistakes

### ❌ Using Cache for Build Outputs

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

### ❌ Downloading All Artifacts

```yaml
# BAD — downloads ALL artifacts from ALL previous jobs
deploy:
  dependencies: []

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

---

## Source URLs

| Topic | URL |
|-------|-----|
| `artifacts` keyword | https://docs.gitlab.com/ci/yaml/#artifacts |
| `cache` keyword | https://docs.gitlab.com/ci/yaml/#cache |
| `dependencies` keyword | https://docs.gitlab.com/ci/yaml/#dependencies |
| `needs` keyword | https://docs.gitlab.com/ci/yaml/#needs |
| Caching guide | https://docs.gitlab.com/ci/caching/ |
| Visual guide to caching | https://about.gitlab.com/blog/a-visual-guide-to-gitlab-ci-caching/ |
| Artifact storage limits | https://docs.gitlab.com/ci/caching/#artifact-storage-limits |
