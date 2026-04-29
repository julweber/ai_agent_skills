# GitLab CI/CD YAML Syntax Reference

Complete reference for `.gitlab-ci.yml` keywords, syntax, and usage patterns.

## File Structure

```yaml
# Global keywords (pipeline-level)
stages: [...]
default: {...}
include: [...]
variables: {...}
workflow: {...}

# Job definitions
job-name:
  stage: build
  script: [...]
  # ... job keywords
```

## Global Keywords

### `stages`

Define execution order. Jobs in the same stage run in parallel.

```yaml
stages:
  - build
  - test
  - deploy
```

**Default stages** (when not defined): `.pre`, `build`, `test`, `deploy`, `.post`

**Special stages:**
- `.pre` — Runs before all other stages
- `.post` — Runs after all other stages

### `default`

Set default values applied to every job that doesn't override them.

```yaml
default:
  image: ubuntu:22.04
  retry: 2
  timeout: 30m
  before_script:
    - echo "Starting job..."
  after_script:
    - echo "Job finished"
  cache:
    paths:
      - node_modules/
```

**Supported default keywords:** `after_script`, `artifacts`, `before_script`, `cache`, `hooks`, `id_tokens`, `image`, `interruptible`, `retry`, `services`, `tags`

### `include`

Import external YAML configurations.

```yaml
include:
  # Local file in same repo
  - local: '/ci/templates/build.yml'

  # From another project (pinned to tag)
  - project: 'shared/ci-templates'
    ref: v1.2.0
    file: '/templates/security.yml'

  # GitLab built-in template
  - template: Security/Secret-Detection.gitlab-ci.yml

  # Remote URL with integrity check
  - remote: 'https://example.com/template.yml'
    integrity: 'sha256-xxxxx='

  # CI/CD component
  - component: '$CI_SERVER_FQDN/my-org/node-build@1.0'
    inputs:
      node_version: "20"

  # Conditional include
  - local: '/ci/e2e.yml'
    rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

**Include types:**
| Type | Source | Auth |
|------|--------|------|
| `local` | Same repo | No |
| `project` | Same GitLab instance | Yes (user must have access) |
| `remote` | Any HTTP URL | No (public only) |
| `template` | GitLab built-in | No |
| `component` | Any GitLab project | Yes |

**Limits:** 150 includes per pipeline (including nested). 30-second timeout for resolution.

### `variables` (global)

Define default variables for all jobs.

```yaml
variables:
  NODE_ENV: production
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE
  DEPLOY_TIMEOUT: "300"
```

### `workflow`

Control when pipelines run.

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

  name: 'Pipeline for $CI_COMMIT_BRANCH'

  auto_cancel:
    on_new_commit: interruptible
    on_job_failure: all
```

## Job Keywords

### Core Keywords

| Keyword | Required | Description |
|---------|----------|-------------|
| `script` | Yes* | Commands to execute |
| `stage` | No | Stage assignment (default: `test`) |
| `image` | No | Docker image |
| `services` | No | Docker service containers |
| `tags` | No | Runner selection |

*At least one job must have `script`

### Execution Control

| Keyword | Description |
|---------|-------------|
| `before_script` | Commands before `script` |
| `after_script` | Commands after `script` (runs even on failure) |
| `timeout` | Job timeout (e.g., `30m`, `1h`, `1h30m`) |
| `retry` | Retry count or retry rules |
| `allow_failure` | Job failure doesn't fail pipeline |
| `interruptible` | Allow cancellation on new pipeline |
| `when` | `always`, `manual`, `delayed`, `never`, `on_success`, `on_failure` |
| `start_in` | Delay execution (with `when: delayed`) |
| `parallel` | Run multiple instances |
| `manual_confirmation` | Custom message for manual jobs |

### Conditional Execution (`rules`)

```yaml
rules:
  # Variable conditions
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $DEPLOY_ENV == "production"

  # Regex matching
  - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/

  # File changes
  - changes:
      - src/**/*.js
      - package.json

  # File existence
  - exists:
      - Dockerfile

  # Set variables when rule matches
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    variables:
      DEPLOY_TARGET: staging

  # When action
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    when: always
  - if: $CI_MERGE_REQUEST_ID
    when: manual
  - when: never  # Exclude condition

  # Delayed execution
  - if: $SCHEDULED_DEPLOY
    when: delayed
    start_in: 1 hour 30 minutes
```

**Rule evaluation:** First matching rule wins. Rules are evaluated in order.

**`when` values:**
- `always` — Always run (default)
- `manual` — Requires manual click to run
- `delayed` — Shows countdown before running
- `never` — Don't create the job (equivalent to excluding)
- `on_success` — Run only if previous stage passed
- `on_failure` — Run only if previous stage failed

### Dependencies & Artifacts

#### `artifacts`

```yaml
artifacts:
  paths:
    - dist/
    - build/
  reports:
    junit: junit.xml
    coverage_report:
      coverage_format: cobertura
      path: coverage.xml
    dotenv: report.env
    gitlab_yaml_artifacts: generated.yml
  expire_in: 1 week
  when: on_success  # on_success (default) or always
  exclude:
    - dist/**/*.map
```

#### `cache`

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

**Cache vs Artifacts:**
| | Cache | Artifacts |
|---|-------|-----------|
| Purpose | Dependencies (fast reuse) | Build outputs (reliable passing) |
| Storage | Runner local + optional S3 | GitLab server |
| Guaranteed | No (may be evicted) | Yes |
| Cross-pipeline | Yes | No (single pipeline only) |
| Download speed | Fast | Slower |

#### `needs` (DAG)

```yaml
unit-test:
  stage: test
  needs:
    - build
      artifacts: true
  script:
    - npm test

deploy:
  stage: deploy
  needs:
    - unit-test
    - integration-test
      artifacts: false
```

**Benefits:** Jobs start as soon as dependencies complete (not waiting for entire stage).

#### `dependencies`

```yaml
deploy:
  dependencies:
    - build-job
    - package-job
```

**Difference from `needs`:** `dependencies` only controls artifact download (respects stage order). `needs` controls both execution order AND artifacts.

### Inheritance

#### `extends`

```yaml
.docker-job:
  image: docker:24-dind
  services:
    - docker:24-dind

build:
  extends: .docker-job
  script:
    - docker build -t app .
```

#### `inherit`

Control which defaults a job inherits:

```yaml
my-job:
  inherit:
    default: true        # inherit from `default:` block
    before_script: true  # inherit before_script
    after_script: false  # don't inherit after_script
    variables: true      # inherit global variables
    cache: false         # don't inherit cache
    services: true       # inherit services
```

### Environments

```yaml
deploy-staging:
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop-staging
    action: start  # start (default), stop, prepare

stop-staging:
  environment:
    name: staging
    action: stop
  when: manual
```

### Parallel Execution

```yaml
test:
  stage: test
  parallel:
    matrix:
      - NODE_VERSION: ["18", "20", "22"]
        OS: ["ubuntu-latest", "windows-latest"]

# Or simple count
test:
  parallel: 4
  script:
    - echo "Chunk $CI_NODE_INDEX of $CI_NODE_TOTAL"
```

### Downstream Pipelines (`trigger`)

```yaml
deploy-infra:
  stage: deploy
  trigger:
    project: 'group/infrastructure'
    branch: main
    strategy: depend  # depend (default) or no_dependency
  forward:
    pipeline_variables: true
    branch: false
```

### Advanced Keywords

| Keyword | Description |
|---------|-------------|
| `coverage` | Regex to extract coverage % |
| `pages` | GitLab Pages config |
| `release` | Create GitLab release |
| `resource_group` | Limit concurrent execution |
| `dast_configuration` | DAST profile reference |
| `identity` | Identity federation config |
| `secrets` | CI/CD secrets access |
| `run` | Run configuration |

## CI/CD Components

Modern reusable pipeline units with inputs.

### Component Definition

```yaml
spec:
  inputs:
    node_version:
      default: "20"
      type: string
    test_command:
      default: "npm test"
    lint_enabled:
      default: true
      type: boolean
    max_instances:
      default: 4
      type: number
    deploy_region:
      default: us-east-1
      options:
        - us-east-1
        - eu-west-1
        - ap-southeast-1

lint-and-test:
  image: node:${INPUTS_NODE_VERSION}
  stage: test
  script:
    - npm ci
    - npm run lint
    - ${INPUTS_TEST_COMMAND}
```

### Using a Component

```yaml
include:
  - component: '$CI_SERVER_FQDN/my-org/node-build@2.1.0'
    inputs:
      node_version: "22"
      test_command: "jest --ci"
      deploy_region: eu-west-1
```

**Input variable syntax:** `INPUTS_<NAME>` (uppercase, underscores)

## Predefined Variables (Key Subset)

| Variable | Example | When Available |
|----------|---------|----------------|
| `$CI_COMMIT_BRANCH` | `feature/login` | Branch pipelines |
| `$CI_COMMIT_TAG` | `v1.2.3` | Tag pipelines |
| `$CI_DEFAULT_BRANCH` | `main` | Always |
| `$CI_PIPELINE_SOURCE` | `push`, `merge_request_event` | Always |
| `$CI_MERGE_REQUEST_ID` | `42` | MR pipelines only |
| `$CI_MERGE_REQUEST_IID` | `7` | MR pipelines only |
| `$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME` | `feature/login` | MR pipelines only |
| `$CI_MERGE_REQUEST_TARGET_BRANCH_NAME` | `main` | MR pipelines only |
| `$CI_MERGE_REQUEST_LABELS` | `ready,frontend` | MR pipelines only |
| `$CI_PROJECT_DIR` | `/builds/group/project` | Job execution |
| `$CI_PROJECT_NAME` | `my-app` | Always |
| `$CI_PROJECT_PATH` | `group/my-app` | Always |
| `$CI_SERVER_FQDN` | `gitlab.example.com` | Always |
| `$CI_REGISTRY` | `registry.gitlab.example.com` | Always |
| `$CI_REGISTRY_IMAGE` | `$CI_REGISTRY/group/my-app` | Always |
| `$CI_PIPELINE_ID` | `12345` | Always |
| `$CI_JOB_ID` | `67890` | Job execution |
| `$CI_JOB_NAME` | `unit-test` | Job execution |
| `$CI_JOB_STAGE` | `test` | Job execution |
| `$CI_COMMIT_SHA` | `a1b2c3d4...` | Always |
| `$CI_COMMIT_SHORT_SHA` | `a1b2c3d4` | Always |
| `$CI_COMMIT_REF_SLUG` | `feature-login` | Always |
| `$CI_NODE_INDEX` | `1` | Parallel jobs |
| `$CI_NODE_TOTAL` | `3` | Parallel jobs |

## Deprecated Keywords

- **`only` / `except`** — Use `rules` instead
- **`when: on_success` / `on_failure` in job level** — Use `rules`
- **`kubernetes`** — Use `services`
- **`artifacts:reports:dotenv`** — Merged into `artifacts:reports`

## YAML Syntax Notes

- Use 2-space indentation
- Quote strings with special characters: `"value with spaces"`
- Multi-line strings with `|` (literal) or `>` (folded)
- Comments with `#`
- Boolean values: `true`/`false` (lowercase)
- Numbers without quotes are integers/floats
- Use `$VARIABLE` syntax for CI/CD variables
- Use `\${VARIABLE}` to escape in certain contexts

---

## Source URLs

| Topic | URL |
|-------|-----|
| Full YAML syntax reference | https://docs.gitlab.com/ci/yaml/ |
| Global keywords (stages, default, include, variables, workflow) | https://docs.gitlab.com/ci/yaml/#global-keywords |
| Job keywords | https://docs.gitlab.com/ci/yaml/#job-keywords |
| `include` keyword (local, project, remote, template, component) | https://docs.gitlab.com/ci/yaml/#include |
| `include:component` | https://docs.gitlab.com/ci/yaml/#includecomponent |
| `include:local` | https://docs.gitlab.com/ci/yaml/#includelocal |
| `include:project` | https://docs.gitlab.com/ci/yaml/#includeproject |
| `include:remote` | https://docs.gitlab.com/ci/yaml/#includeremote |
| `include:template` | https://docs.gitlab.com/ci/yaml/#includetemplate |
| `include:inputs` | https://docs.gitlab.com/ci/yaml/#includeinputs |
| `include:rules` | https://docs.gitlab.com/ci/yaml/#includerules |
| `include:integrity` | https://docs.gitlab.com/ci/yaml/#includeintegrity |
| `rules` keyword (if, changes, exists, when) | https://docs.gitlab.com/ci/yaml/#rules |
| `needs` keyword (DAG pipelines) | https://docs.gitlab.com/ci/yaml/#needs |
| `artifacts` keyword | https://docs.gitlab.com/ci/yaml/#artifacts |
| `cache` keyword | https://docs.gitlab.com/ci/yaml/#cache |
| `workflow` keyword | https://docs.gitlab.com/ci/yaml/workflow/ |
| `workflow:rules` | https://docs.gitlab.com/ci/yaml/workflow/#workflow-rules-examples |
| `workflow:auto_cancel` | https://docs.gitlab.com/ci/yaml/#workflowauto_cancel |
| `spec:inputs` (components) | https://docs.gitlab.com/ci/yaml/#specinputs |
| CI/CD components | https://docs.gitlab.com/ci/components/ |
| CI/CD input parameters | https://docs.gitlab.com/ci/inputs/ |
| Predefined variables | https://docs.gitlab.com/ci/variables/predefined_variables/ |
| `extends` keyword | https://docs.gitlab.com/ci/yaml/#extends |
| `inherit` keyword | https://docs.gitlab.com/ci/yaml/#inherit |
| `environment` keyword | https://docs.gitlab.com/ci/yaml/#environment |
| `parallel` keyword | https://docs.gitlab.com/ci/yaml/#parallel |
| `trigger` keyword (downstream pipelines) | https://docs.gitlab.com/ci/yaml/#trigger |
| Deprecated keywords | https://docs.gitlab.com/ci/yaml/deprecated_keywords/ |
| Nested includes | https://docs.gitlab.com/ci/yaml/includes/#use-nested-includes |
| Variables with include | https://docs.gitlab.com/ci/yaml/includes/#use-variables-with-include |
| `default` keyword | https://docs.gitlab.com/ci/yaml/#default |
| `retry` keyword | https://docs.gitlab.com/ci/yaml/#retry |
| `timeout` keyword | https://docs.gitlab.com/ci/yaml/#timeout |
| `when` keyword | https://docs.gitlab.com/ci/yaml/#when |
| `dependencies` keyword | https://docs.gitlab.com/ci/yaml/#dependencies |
| `.pre` and `.post` stages | https://docs.gitlab.com/ci/yaml/#stage-pre |
| CI Lint tool | https://docs.gitlab.com/ci/yaml/lint/ |
| GitLab CI/CD examples | https://docs.gitlab.com/ci/examples/ |
| Quick start tutorial | https://docs.gitlab.com/ci/quick_start/tutorial/ |
