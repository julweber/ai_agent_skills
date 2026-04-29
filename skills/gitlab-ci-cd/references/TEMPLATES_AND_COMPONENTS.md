# Templates and Components Guide

Creating reusable, versioned CI/CD configurations.

## Templates vs Components

| Feature | Template | Component |
|---------|----------|-----------|
| Syntax | Standard YAML with `include:` | YAML with `spec:inputs` |
| Inputs | None (static) | Parameterized via `spec:inputs` |
| Versioning | Manual (ref/SHA pinning) | Built-in version in component address |
| Reusability | Same instance | Cross-instance |
| Complexity | Simple | Advanced |
| GitLab Version | All | 17.0+ |

## Template Design

### Basic Template

Create a file in your repo (e.g., `ci/templates/build.yml`):

```yaml
# ci/templates/build.yml

build:
  stage: build
  image: node:20-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
```

Use it in any project:

```yaml
include:
  - local: '/ci/templates/build.yml'
```

### Template with Customization via Variables

```yaml
# ci/templates/test.yml

unit-test:
  stage: test
  image: node:${NODE_VERSION:-20}-alpine
  script:
    - npm ci
    - ${TEST_COMMAND:-npm test}
  artifacts:
    reports:
      junit: ${JUNIT_REPORT:-junit.xml}
    expire_in: 1 week
```

Set variables in the consuming project:

```yaml
variables:
  NODE_VERSION: "22"
  TEST_COMMAND: "jest --ci --coverage"

include:
  - local: '/ci/templates/test.yml'
```

### Multi-Job Template

```yaml
# ci/templates/node-full.yml

.node-base:
  image: node:${NODE_VERSION:-20}-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/

install:
  extends: .node-base
  stage: build
  script:
    - npm ci
  artifacts:
    paths:
      - node_modules/
    expire_in: 1 hour

lint:
  extends: .node-base
  stage: test
  script:
    - npm run lint
  allow_failure: true
  needs: [install]

test:
  extends: .node-base
  stage: test
  script:
    - npm test
  needs: [install]
```

## Component Design

### Basic Component

Components live in a dedicated GitLab project. Each component is a single `.yml` file.

```yaml
# components/node-build.yml

spec:
  inputs:
    node_version:
      default: "20"
      type: string
    test_command:
      default: "npm test"
      type: string
    lint_command:
      default: "npm run lint"
      type: string
    coverage_enabled:
      default: true
      type: boolean

install:
  stage: build
  image: node:${INPUTS_NODE_VERSION}-alpine
  cache:
    key:
      files:
        - package-lock.json
    paths:
      - node_modules/
  script:
    - npm ci
  artifacts:
    paths:
      - node_modules/
    expire_in: 1 hour

lint:
  stage: test
  image: node:${INPUTS_NODE_VERSION}-alpine
  script:
    - ${INPUTS_LINT_COMMAND}
  allow_failure: true
  needs: [install]

test:
  stage: test
  image: node:${INPUTS_NODE_VERSION}-alpine
  script:
    - ${INPUTS_TEST_COMMAND}
  artifacts:
    reports:
      junit: junit.xml
    expire_in: 1 week
  needs: [install]
```

### Using a Component

```yaml
include:
  - component: '$CI_SERVER_FQDN/my-org/ci-components/node-build@1.2.0'
    inputs:
      node_version: "22"
      test_command: "jest --ci --coverage"
      coverage_enabled: true
```

### Component with Multiple Input Types

```yaml
spec:
  inputs:
    # String input
    deploy_region:
      default: us-east-1
      type: string
      options:
        - us-east-1
        - eu-west-1
        - ap-southeast-1

    # Boolean input
    run_security_scan:
      default: true
      type: boolean

    # Number input
    test_parallelism:
      default: 4
      type: number

    # String with no default (required)
    app_name:
      type: string
```

**Input variable naming:** Input `node_version` → `$INPUTS_NODE_VERSION` (uppercase, underscores)

## Versioning Strategy

### For Templates

1. Store templates in a dedicated project: `shared/ci-templates`
2. Tag releases: `git tag ci-templates/v1.2.0 && git push origin ci-templates/v1.2.0`
3. Consume with pinned ref:

```yaml
include:
  - project: 'shared/ci-templates'
    ref: 'ci-templates/v1.2.0'
    file: '/node-build.yml'
```

### For Components

1. Version is part of the component address
2. Tag the component project: `git tag v1.2.0 && git push origin v1.2.0`
3. Use: `component: '$CI_SERVER_FQDN/my-org/node-build@1.2.0'`

## Component Project Structure

```
ci-components/
├── .gitlab-ci.yml          # Tests for the components themselves
├── node-build.yml          # Component file
├── python-test.yml         # Component file
├── docker-push.yml         # Component file
└── README.md               # Documentation
```

### Testing Components

```yaml
# .gitlab-ci.yml in the component project

test-node-build-component:
  stage: test
  script:
    - |
      cat > test-pipeline.yml << 'EOF'
      include:
        - local: 'node-build.yml'
          inputs:
            node_version: "20"
      stages:
        - build
        - test
      EOF
    - gitlab-ci-lint test-pipeline.yml
```

## Migration: Template → Component

### Before (Template)

```yaml
# Template uses variables for customization
variables:
  NODE_VERSION: "22"

include:
  - project: 'shared/templates'
    ref: v1.0
    file: '/node-build.yml'
```

### After (Component)

```yaml
include:
  - component: '$CI_SERVER_FQDN/shared/ci-components/node-build@1.0'
    inputs:
      node_version: "22"
```

**Benefits of migration:**
- Type-safe inputs with validation
- Documented parameters
- Versioned in the address
- Cross-instance sharing

## Conditional Includes

Include different configurations based on conditions:

```yaml
include:
  # Only on main branch
  - local: '/ci/deploy-production.yml'
    rules:
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

  # Only for merge requests
  - local: '/ci/mr-checks.yml'
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"

  # Only when Dockerfile exists
  - local: '/ci/docker-build.yml'
    rules:
      - exists:
          - Dockerfile

  # Only when source files changed
  - local: '/ci/full-build.yml'
    rules:
      - changes:
          - src/**/*
          - package.json
```

## Include Merging

When the same job name appears in multiple includes, configurations merge:

```yaml
# included.yml
build:
  stage: build
  image: node:20-alpine
  script:
    - npm ci

# .gitlab-ci.yml
include:
  - local: '/included.yml'

build:
  # Merges with included build job
  script:
    - npm ci
    - npm run build  # Overrides the script from include
```

**Merge behavior:**
- `script`, `before_script`, `after_script` — **replaced** (not appended)
- `tags`, `variables` — **merged**
- Other keywords — **replaced**

To append scripts, use `extends` instead of name collision.

---

## Source URLs

| Topic | URL |
|-------|-----|
| CI/CD components overview | https://docs.gitlab.com/ci/components/ |
| Use a CI/CD component | https://docs.gitlab.com/ci/components/#use-a-component |
| `spec:inputs` keyword | https://docs.gitlab.com/ci/yaml/#specinputs |
| `spec:inputs:type` | https://docs.gitlab.com/ci/yaml/#specinputstype |
| `spec:inputs:options` | https://docs.gitlab.com/ci/yaml/#specinputsoptions |
| `include:component` | https://docs.gitlab.com/ci/yaml/#includecomponent |
| `include:inputs` | https://docs.gitlab.com/ci/yaml/#includeinputs |
| CI/CD input parameters | https://docs.gitlab.com/ci/inputs/ |
| Set input values with include | https://docs.gitlab.com/ci/inputs/#for-configuration-added-with-include |
| `include:local` | https://docs.gitlab.com/ci/yaml/#includelocal |
| `include:project` | https://docs.gitlab.com/ci/yaml/#includeproject |
| `include:rules` (conditional includes) | https://docs.gitlab.com/ci/yaml/#includerules |
| Include with rules:if | https://docs.gitlab.com/ci/yaml/includes/#include-with-rulesif |
| Include with rules:changes | https://docs.gitlab.com/ci/yaml/includes/#include-with-ruleschanges |
| Include with rules:exists | https://docs.gitlab.com/ci/yaml/includes/#include-with-rulesexists |
| Nested includes | https://docs.gitlab.com/ci/yaml/includes/#use-nested-includes |
| Include merging behavior | https://docs.gitlab.com/ci/yaml/includes/#merge-included-configuration |
| `extends` keyword | https://docs.gitlab.com/ci/yaml/#extends |
| Component vs template blog post | https://about.gitlab.com/blog/refactoring-a-ci-cd-template-to-a-ci-cd-component/ |
| GitLab built-in templates | https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates |
| Maximum includes limit | https://docs.gitlab.com/ci/yaml/#include |
| Protected branches/tags for includes | https://docs.gitlab.com/user/project/repository/branches/protected/ |
