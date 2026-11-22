# Changelog

## [Unreleased]

## [0.4.5] - 2026-11-22
### Changed
- Pinned commons-io to 2.22.0 in the installer.

### Fixed
- Linux/macOS: the bundled JRE's `jspawnhelper` is now executable after install, so Java can start subprocesses again (the uninstaller failed with `posix_spawn failed, error: 13` and left the installation in place).

### Security
- Bundled JRE upgraded to Temurin 21.0.13+9 (Linux/Windows/macOS), picking up the Java SE security updates since 21.0.5.

## [0.4.4] - 2026-10-12
### Changed
- Maintenance and internal updates.

## [0.4.3] - 2026-10-08
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
