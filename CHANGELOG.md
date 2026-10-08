# Changelog

## [Unreleased]
### Removed
- `legacy_libs/h2-1.4.191.jar` is no longer part of the installation (removed from the node distribution, critical CVEs); the install test now checks that it is absent. Upgrading from a release before 0.4.1 needs release 0.4.2 once first.


## [0.4.2] - 2026-10-05
### Changed
- Gate installer release behind finalize step (FINALIZE_RELEASE) and switch its token to GITLAB_TOKEN.

## [0.4.1] - 2026-07-06
### Changed
- Bundled JDK upgraded to Temurin 21.0.5 and OpenJFX 21.0.2 (Linux/Windows/macOS); Gradle wrapper 8.12.
- Start scripts enforce a minimum Java version.
- Added cross-platform end-to-end smoke tests; refreshed dependencies and build.
