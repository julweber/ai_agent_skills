# CI/CD Components — Complete Guide

Creating, publishing, and consuming reusable CI/CD components with `spec:inputs`.

## Overview

CI/CD components (GitLab 16.8+) are versioned, parameterized pipeline units that can be
shared across projects and instances. They extend the template system with type-safe inputs.

## Component Structure

A component is a single YAML file with a `spec:inputs` section at the top.

### Component Definition

```yaml
spec:
  inputs:
    node_version:
      default: "20"
      type: string
    test_command:
      default: "npm test"
      type: string
    lint_enabled:
      default: true
      type: boolean
    max_instances:
      default: 4
      type: number
    deploy_region:
      default: us-east-1
      type: string
      options:
        - us-east-1
        - eu-west-1
        - ap-southeast-1

# Jobs use INPUTS_<NAME> (uppercase, underscores)
lint-and-test:
  image: node:${INPUTS_NODE_VERSION}
  stage: test
  script:
    - npm ci
    - ${INPUTS_LINT_ENABLED} && npm run lint || true
    - ${INPUTS_TEST_COMMAND}
  parallel: ${INPUTS_MAX_INSTANCES}
```

## Input Types

### String Input

```yaml
spec:
  inputs:
    image_tag:
      type: string
      default: "20-alpine"
```

### Boolean Input

```yaml
spec:
  inputs:
    enable_coverage:
      type: boolean
      default: true
```

### Number Input

```yaml
spec:
  inputs:
    parallel_count:
      type: number
      default: 4
```

### Enum (Options) Input

```yaml
spec:
  inputs:
    environment:
      type: string
      default: staging
      options:
        - staging
        - production
        - development
```

### Required Input (No Default)

```yaml
spec:
  inputs:
    app_name:
      type: string
      # No default — must be provided by consumer
```

## Consuming a Component

```yaml
include:
  - component: '$CI_SERVER_FQDN/my-org/ci-tools/node-build@1.2.0'
    inputs:
      node_version: "22"
      test_command: "jest --ci"
      lint_enabled: true
      deploy_region: eu-west-1
```

### Input Variable Syntax

| Input Name | Variable in YAML |
|------------|-----------------|
| `node_version` | `${INPUTS_NODE_VERSION}` |
| `test_command` | `${INPUTS_TEST_COMMAND}` |
| `lint_enabled` | `${INPUTS_LINT_ENABLED}` |

## Versioning

The version is part of the component address:

```
component: '$CI_SERVER_FQDN/org/component-name@MAJOR.MINOR.PATCH'
```

### Versioning Strategy

1. Tag the component project: `git tag v1.2.0 && git push origin v1.2.0`
2. Use the tag in the component address: `@1.2.0`
3. Update when making breaking or compatible changes

## Component Project Structure

```
ci-components/
├── .gitlab-ci.yml          # Tests for the components themselves
├── node-build.yml          # Component file
├── python-test.yml         # Component file
├── docker-push.yml         # Component file
└── README.md               # Documentation
```

## Testing Components

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

## Component vs Template

| Feature | Template | Component |
|---------|----------|-----------|
| Syntax | Standard YAML | YAML with `spec:inputs` |
| Inputs | None (static) | Parameterized via `spec:inputs` |
| Versioning | Manual (ref/SHA pinning) | Built-in version in address |
| Reusability | Same instance | Cross-instance |
| Complexity | Simple | Advanced |
| GitLab Version | All | 16.8+ |

## Publishing a Component

1. Store component in a GitLab project
2. Tag releases: `git tag v1.0.0 && git push origin v1.0.0`
3. Share the component address: `$CI_SERVER_FQDN/org/component-name@1.0.0`
4. Document the available inputs and their defaults

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
| Component vs template blog post | https://about.gitlab.com/blog/refactoring-a-ci-cd-template-to-a-ci-cd-component/ |
