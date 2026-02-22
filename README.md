# Linear Release - CircleCI Orb

<!---
[![CircleCI Build Status](https://circleci.com/gh/mishchief/linear-release-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/mishchief/linear-release-orb) [![CircleCI Orb Version](https://badges.circleci.com/orbs/mishchief/linear-release.svg)](https://circleci.com/developer/orbs/orb/mishchief/linear-release) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/mishchief/linear-release-orb/main/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)
--->

Integrate your CircleCI pipelines with [Linear's release management](https://linear.app) to automatically track which issues ship in each release and to each environment.

This unofficial orb wraps the [linear-release CLI](https://github.com/linear/linear-release) to provide seamless integration between your CI/CD workflow and Linear's release tracking.

---

> [!IMPORTANT]
> **This is an unofficial community-maintained orb** and is not affiliated with Linear or CircleCI.
>
> Linear Release feature is in **closed beta**. Contact [Linear support](https://linear.app/contact) or your account manager to request access. APIs and commands may change.

---

## Features

- **Automatic Issue Detection** - Scans commits for Linear issue identifiers (e.g., `ENG-123`)
- **PR Reference Detection** - Detects pull request numbers from commit messages
- **Multi-Environment Tracking** - Support for staging, production, and custom pipelines
- **Monorepo Support** - Filter commits by file paths using glob patterns
- **Zero Configuration** - Works out of the box with sensible defaults
- **Flexible** - Use pre-built jobs or compose your own with the release command

## Prerequisites

- A [Linear](https://linear.app) account with release pipelines configured
- Linear pipeline access keys (Settings → API → Pipeline Keys)
- A CircleCI project

## Quick Start

### 1. Set Up Linear Pipelines

In Linear, navigate to **Settings → Releases** and create pipelines for your environments:

- **Continuous pipelines** (for frequent deployments): Create separate pipelines for staging and production
- **Scheduled pipelines** (for planned releases): Create a single pipeline with custom stages

Generate an access key for each pipeline.

### 2. Configure CircleCI Context

Store your Linear access keys as environment variables in CircleCI:

1. Go to **Organization Settings → Contexts**
2. Create a context (e.g., `linear-release`)
3. Add environment variable: `LINEAR_ACCESS_KEY` with your pipeline access key

For multiple environments, create separate contexts with the same variable name:
- Context: `linear-release-stage` → `LINEAR_ACCESS_KEY` = staging pipeline key
- Context: `linear-release-prod` → `LINEAR_ACCESS_KEY` = production pipeline key

### 3. Use the Orb

Add to your `.circleci/config.yml`:

```yaml
version: 2.1

orbs:
  linear-release: mishchief/linear-release@1.0.0

workflows:
  deploy:
    jobs:
      - build-and-test
      - linear-release/deploy:
          name: sync-release
          context: linear-release
          requires:
            - build-and-test
          filters:
            branches:
              only: main
```

## Usage

### Jobs

#### `deploy`

Simple job that syncs a release with Linear after deployment.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `access_key` | `env_var_name` | `LINEAR_ACCESS_KEY` | Environment variable containing Linear pipeline access key |
| `command` | `enum` | `sync` | Command to run: `sync`, `complete`, or `update` |
| `release_name` | `string` | `""` | Custom release name (e.g., "Production Deploy - v1.2.3") |
| `version` | `string` | `""` | Release version identifier (e.g., "v1.2.3" or "${CIRCLE_SHA1:0:7}") |
| `stage` | `string` | `""` | Deployment stage (required for `update` command) |
| `include_paths` | `string` | `""` | Filter commits by file paths (comma-separated globs) |
| `cli_version` | `string` | `latest` | Linear Release CLI version to install |

**Example:**

```yaml
workflows:
  deploy:
    jobs:
      - build
      - linear-release/deploy:
          context: linear-release
          version: "${CIRCLE_SHA1:0:7}"
          requires:
            - build
```

#### `deploy_on_tag`

Automatically syncs a release using the git tag as version. Perfect for production deployments.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `access_key` | `env_var_name` | `LINEAR_ACCESS_KEY` | Environment variable containing Linear pipeline access key |
| `release_name` | `string` | `""` | Custom release name prefix |
| `stage` | `string` | `production` | Deployment stage to mark in Linear |
| `include_paths` | `string` | `""` | Filter commits by file paths |
| `cli_version` | `string` | `latest` | Linear Release CLI version to install |

**Example:**

```yaml
workflows:
  release:
    jobs:
      - build-and-deploy:
          filters:
            tags:
              only: /^v.*/
            branches:
              ignore: /.*/
      - linear-release/deploy_on_tag:
          context: linear-release
          requires:
            - build-and-deploy
          filters:
            tags:
              only: /^v.*/
            branches:
              ignore: /.*/
```

### Commands

#### `release`

Core command to sync, update, or complete Linear releases. Use this to build custom jobs.

**Parameters:** See job parameters above.

**Example:**

```yaml
jobs:
  custom-deploy:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - linear-release/release:
          command: sync
          version: "v1.2.3"
          name: "Custom Release"
```

## Configuration

### Continuous vs Scheduled Pipelines

**Continuous Pipelines** (recommended for CD workflows):
- Create separate pipelines for each environment (staging, production)
- Each release appears in the pipeline immediately after deployment
- No manual stage management needed

**Scheduled Pipelines** (for planned releases):
- Single pipeline with custom stages
- Use `update` command to move releases through stages
- Support for freezing stages and release planning

### Multi-Environment Setup

For tracking deployments to multiple environments, create separate pipelines in Linear:

**In Linear:**
1. Create pipeline: "my-app-staging" (Continuous) → Generate access key
2. Create pipeline: "my-app-production" (Continuous) → Generate access key

**In CircleCI:**
1. Create context: `linear-release-stage` with `LINEAR_ACCESS_KEY` = staging key
2. Create context: `linear-release-prod` with `LINEAR_ACCESS_KEY` = production key

**In config.yml:**
```yaml
workflows:
  deploy:
    jobs:
      - test
      - deploy-staging:
          context: linear-release-stage
          requires:
            - test
      - deploy-production:
          context: linear-release-prod
          requires:
            - deploy-staging
          filters:
            branches:
              only: main
```

### Monorepo Support

Filter commits by file paths to only include relevant changes:

```yaml
- linear-release/release:
    include_paths: "packages/api/**,packages/shared/**"
```

This ensures only commits affecting the specified paths are included in the release.

## Examples

See the [src/examples](./src/examples) directory for complete usage examples:

- **[basic_sync.yml](./src/examples/basic_sync.yml)** - Simple sync on every main branch commit
- **[deploy_production.yml](./src/examples/deploy_production.yml)** - Production deployment triggered by git tags
- **[deploy_staging.yml](./src/examples/deploy_staging.yml)** - Staging deployment with custom parameters

## Advanced Usage

### Custom Version Naming

Use CircleCI environment variables to create meaningful version identifiers:

```yaml
# Short commit SHA
version: "${CIRCLE_SHA1:0:7}"

# Branch name + SHA
version: "${CIRCLE_BRANCH}-${CIRCLE_SHA1:0:7}"

# Git tag
version: "${CIRCLE_TAG}"

# Timestamp
version: "$(date +%Y%m%d-%H%M%S)"
```

### Conditional Releases

Only sync releases for specific branches:

```yaml
workflows:
  deploy:
    jobs:
      - linear-release/deploy:
          context: linear-release
          filters:
            branches:
              only:
                - main
                - develop
```

### Sequential Stage Updates (Scheduled Pipelines)

For scheduled pipelines with stages:

```yaml
jobs:
  deploy-to-staging:
    steps:
      - linear-release/release:
          command: sync
          version: "v1.2.3"
      - linear-release/release:
          command: update
          version: "v1.2.3"
          stage: "staging"
```

## Development

### Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes using [Conventional Commits](https://conventionalcommits.org/)
4. Push to your branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CHANGELOG.md](./CHANGELOG.md) for version history.

### Testing Locally

Test the orb locally using CircleCI's local CLI:

```bash
circleci orb validate src/@orb.yml
```

### Publishing Updates

This orb follows [Semantic Versioning](https://semver.org/):

1. Merge PRs to main branch
2. Create a new [GitHub Release](https://github.com/mishchief/linear-release-orb/releases/new)
3. Choose a semantic version tag (e.g., `v1.0.1`)
4. Auto-generate release notes
5. Publish release (triggers CircleCI publishing pipeline)

## Resources

- [CircleCI Orb Registry](https://circleci.com/developer/orbs/orb/mishchief/linear-release) - Official registry page
- [Linear Release CLI](https://github.com/linear/linear-release) - Underlying CLI tool
- [CircleCI Orb Docs](https://circleci.com/docs/orb-intro/) - General orb documentation
- [Linear Releases Documentation](https://linear.app/docs/releases) - Linear's release feature
- [CHANGELOG](./CHANGELOG.md) - Version history and changes

## Support

- [Issues](https://github.com/mishchief/linear-release-orb/issues) - Report bugs or request features
- [Discussions](https://github.com/mishchief/linear-release-orb/discussions) - Ask questions and share ideas
- [CircleCI Community](https://discuss.circleci.com/c/ecosystem/orbs) - General orb support

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
