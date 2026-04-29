# GitLab CI/CD Troubleshooting Guide

Common failures, debugging strategies, and solutions.

## Pipeline-Level Issues

### Pipeline Doesn't Run

**Checklist:**
1. Is there a `.gitlab-ci.yml` in the repo root?
2. Is the file valid YAML? (Use CI Lint)
3. Does `workflow:rules` exclude this commit?
4. Are runners available with matching tags?

**Debug:**
```yaml
# Add this temporarily to see what's happening
debug:
  stage: .pre
  script:
    - echo "Pipeline running!"
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "Tag: $CI_COMMIT_TAG"
    - echo "Source: $CI_PIPELINE_SOURCE"
```

### Pipeline Runs But No Jobs Appear

**Causes:**
- All jobs have `rules` that evaluate to `when: never`
- `workflow:rules` created the pipeline but no jobs match
- Jobs are in `.pre` or `.post` only (pipeline won't run)

**Fix:** Ensure at least one job has `rules` with `when: always` (or no rules, which defaults to always).

### Jobs Show "Blocked" or "Pending" Forever

**Causes:**
- No runner available with matching `tags`
- Runner is offline
- Runner doesn't have required features (Docker executor, etc.)
- All runners are busy

**Debug:**
1. Check Admin > Overview > Runners for available runners
2. Verify job tags match runner tags
3. Check runner logs: `sudo journalctl -u gitlab-runner`

## Job-Level Issues

### Job Fails with "Script Failed"

**Check:**
1. Exit code of last command in `script`
2. Shell syntax errors
3. Missing dependencies (install them in `before_script`)

**Debug:**
```yaml
script:
  - set -ex  # Print each command and exit on error
  - your-command
```

### Job Times Out

**Fixes:**
1. Increase timeout: `timeout: 1h`
2. Optimize the script (caching, parallelism)
3. Check for hung processes (add `timeout` to long commands)

### Artifacts Not Available in Downstream Jobs

**Common causes:**
1. Upstream job failed (artifacts only saved on success by default)
2. `needs` doesn't include the job with artifacts
3. `artifacts:when: on_failure` needed if upstream can fail

**Fix:**
```yaml
# In the job that produces artifacts
build:
  artifacts:
    paths:
      - dist/
    when: always  # Save even on failure

# In the consumer
test:
  needs:
    - build
      artifacts: true  # Explicitly request artifacts
```

### Cache Not Working

**Checklist:**
1. Cache key matches between jobs/pipelines
2. Paths exist and are non-empty
3. Cache policy is correct (`pull-push`, `pull`, `push`)
4. Runner supports cache (shell executor doesn't support distributed cache)

**Debug:**
```yaml
cache:
  key: ${CI_COMMIT_REF_SLUG}-npm
  paths:
    - node_modules/
  before_script:
    - echo "Cache key: ${CI_COMMIT_REF_SLUG}-npm"
    - ls -la node_modules/ 2>/dev/null || echo "No cache found"
```

### `needs` Job Starts Before Dependency Completes

This shouldn't happen — `needs` guarantees ordering. If it does:
1. Check for typos in job names
2. Verify the dependency job actually exists
3. Check that `artifacts: false` isn't causing unexpected behavior

## Rules Issues

### Job Not Created When Expected

**Debug rules evaluation:**
```yaml
my-job:
  script:
    - echo "Running"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        DEBUG_RULE: "matched main branch"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      variables:
        DEBUG_RULE: "matched MR"
    - variables:
        DEBUG_RULE: "no match (fallback)"
```

**Common mistakes:**
- `$CI_COMMIT_BRANCH` is empty in tag pipelines → use `$CI_COMMIT_TAG`
- `$CI_MERGE_REQUEST_ID` is only set in MR pipelines
- String comparison needs quotes: `$VAR == "value"` not `$VAR == value`
- Regex needs forward slashes: `$VAR =~ /pattern/`

### Variable Not Set in Rules

**Rules variables only apply when the rule matches:**
```yaml
# WRONG — variable only set when rule matches
deploy:
  script:
    - echo $DEPLOY_URL  # May be empty if rule didn't match
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        DEPLOY_URL: "https://staging.example.com"

# RIGHT — set default variable separately
variables:
  DEPLOY_URL: "https://default.example.com"

deploy:
  script:
    - echo $DEPLOY_URL
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      variables:
        DEPLOY_URL: "https://staging.example.com"
```

## Include Issues

### "Not Found or Access Denied"

**Causes:**
1. File doesn't exist at the specified path
2. User running pipeline doesn't have access to the included project
3. `ref` doesn't exist in the target project

**Fix:**
1. Verify file path (must start with `/` for `include:project`)
2. Ensure user has at least Reporter role in included project
3. Check that `ref` exists (branch name, tag, or SHA)

### Include Merge Conflicts

When two includes define the same job:
```yaml
# include-a.yml
build:
  stage: build
  script:
    - echo "from A"

# include-b.yml
build:
  stage: build
  script:
    - echo "from B"  # Overwrites include-a's script!
```

**Fix:** Use unique job names or use `extends` for composition.

## Docker Issues

### "Cannot Connect to Docker Daemon"

**For `docker:dind` service:**
```yaml
services:
  - name: docker:dind
    alias: docker
    entrypoint: ['']  # Custom entrypoint for GitLab-managed auth

variables:
  DOCKER_TLS_CERTDIR: "/certs"  # Required for TLS
```

### Docker Build Fails with "No Space Left on Device"

**Fixes:**
1. Use smaller base images (`-alpine` variants)
2. Clean Docker cache between builds
3. Use buildx with cache mounting

```yaml
docker-build:
  before_script:
    - docker system prune -af  # Clean unused images
  script:
    - docker build -t app .
```

## Runner Issues

### Runner Picks Wrong Job

**Tags control runner selection:**
```yaml
# This job only runs on runners with "docker" tag
docker-job:
  tags:
    - docker
  script:
    - docker build -t app .

# This job runs on any runner
generic-job:
  script:
    - echo "hello"
```

### Shell Executor Limitations

Shell executor runs commands locally on the runner machine:
- No Docker isolation
- No `services` keyword
- Limited cache support
- Security risk (commands run as runner user)

**Recommendation:** Use Docker or Kubernetes executors for production.

## Debugging Checklist

1. **CI Lint** — Validate YAML before pushing
   - Settings > CI/CD > CI Lint
   - Or use API: `POST /api/v4/ci/lint`

2. **Check job logs** — Look for the actual error message
   - Expand the job in the pipeline view
   - Scroll to the bottom for the final error

3. **Verify variables** — Add a debug job to print all variables

4. **Test rules** — Use `when: manual` to test rule evaluation

5. **Check runner status** — Admin > Runners

6. **Review recent changes** — Compare with last working pipeline

7. **GitLab version** — Check if feature requires a specific version

---

## Source URLs

| Topic | URL |
|-------|-----|
| CI Lint tool | https://docs.gitlab.com/ci/yaml/lint/ |
| `workflow:rules` | https://docs.gitlab.com/ci/yaml/workflow/#workflow-rules-examples |
| `rules` keyword | https://docs.gitlab.com/ci/yaml/#rules |
| `rules:if` | https://docs.gitlab.com/ci/yaml/#rulesif |
| `rules:changes` | https://docs.gitlab.com/ci/yaml/#ruleschanges |
| `rules:exists` | https://docs.gitlab.com/ci/yaml/#rulesexists |
| Predefined variables | https://docs.gitlab.com/ci/variables/predefined_variables/ |
| CI/CD variable precedence | https://docs.gitlab.com/ci/variables/#cicd-variable-precedence |
| `artifacts` keyword | https://docs.gitlab.com/ci/yaml/#artifacts |
| `needs` keyword | https://docs.gitlab.com/ci/yaml/#needs |
| `cache` keyword | https://docs.gitlab.com/ci/yaml/#cache |
| Caching guide | https://docs.gitlab.com/ci/caching/ |
| Docker executor | https://docs.gitlab.com/ci/runners/docker/ |
| Docker-in-Docker service | https://docs.gitlab.com/ci/runners/docker/executors.md |
| Runner tags | https://docs.gitlab.com/ci/yaml/#tags |
| Runner management | https://docs.gitlab.com/ee/administration/runners/ |
| Runner troubleshooting | https://docs.gitlab.com/runner/ |
| Shell executor limitations | https://docs.gitlab.com/ci/runners/shell/index.md |
| `include` errors (access denied) | https://docs.gitlab.com/ci/yaml/#includeproject |
| Include merging | https://docs.gitlab.com/ci/yaml/includes/#merge-included-configuration |
| Pipeline efficiency | https://docs.gitlab.com/ci/pipelines/pipeline_efficiency/ |
| Auto-cancel pipelines | https://docs.gitlab.com/ci/pipelines/settings/#auto-cancel-redundant-pipelines |
| `timeout` keyword | https://docs.gitlab.com/ci/yaml/#timeout |
| `retry` keyword | https://docs.gitlab.com/ci/yaml/#retry |
| `when` keyword | https://docs.gitlab.com/ci/yaml/#when |
| `environment` keyword | https://docs.gitlab.com/ci/yaml/#environment |
| Downstream pipelines | https://docs.gitlab.com/ci/pipelines/downstream_pipelines/ |
| GitLab API CI Lint endpoint | https://docs.gitlab.com/ci/yaml/lint/#ci-lint-api |
