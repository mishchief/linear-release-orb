# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Usage examples for common deployment scenarios (basic-sync, deploy-production, deploy-staging)
- Two ready-to-use jobs: `deploy` and `deploy-on-tag` for simplified workflows
- Orb categorization for better discoverability in CircleCI Orb Registry
- Comprehensive parameter descriptions with examples and best practices
- This CHANGELOG file to track version history

### Changed
- Default `cli_version` parameter changed from "v0.2.0" to "latest" to ensure users get the most recent CLI version
- Enhanced all parameter descriptions with detailed documentation and usage examples

## [0.1.0] - 2026-02-21

### Added
- Initial release of linear-release CircleCI orb
- `release` command to sync, update, or complete Linear releases
- Support for custom release names and versions
- Monorepo support via `include_paths` parameter
- Automatic installation of linear-release CLI
- Integration with CircleCI environment variables for secure access key management

[Unreleased]: https://github.com/mishchief/linear-release-orb/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mishchief/linear-release-orb/releases/tag/v0.1.0
