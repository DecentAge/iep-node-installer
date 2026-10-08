# Installer smoke tests

End-to-end tests for the `iep-node-installer` package: build → install → start → API checks → stop → uninstall.

Two scripts, one per platform family:

| Script | Platform | Build target |
|---|---|---|
| `test-installer.sh` | Linux & macOS | `createLinuxInstaller` (or `createMacInstaller`) |
| `test-installer.ps1` | Windows | `createWindowsInstaller` |

## What they do

1. Build the installer if `build/distributions/iep-node-installer.jar` is missing (or if forced).
2. Refuse to run if `~/.iep` (Unix) / `%USERPROFILE%\.iep` (Windows) already exists, so the test never clobbers a real wallet's data. Override with `CLOBBER_HOME=1` (env, Linux/macOS) or `$env:CLOBBER_HOME='1'` (PowerShell) if you know the dir is disposable. iep-node *always* writes its data dir under Java's `user.home` (read from the OS passwd entry, not from `$HOME`), so we can't sandbox it cleanly with env overrides — the trap/finally removes the data dir after the run instead.
3. Generate an unattended `-options` file with `INSTALL_PATH`, env (testnet by default), throwaway password, `startAfterInstallation=false`.
4. Run `java -jar iep-node-installer.jar -options <file>` and verify install completed.
5. Assert the install layout is correct: `bin/`, `jre/`, `lib/`, `scripts/`.
6. Assert the bundled JRE prints version `21.x` (the JDK 21 migration target).
7. Assert `legacy_libs/h2-1.4.191.jar` is **not** shipped any more (H2 1.4 engine removed in 0.4.3, critical CVEs).
8. Pre-flight: refuse if the API port (default 23457 mainnet / 9876 testnet) or peer port (23456 mainnet / 8776 testnet) is already bound, or if any `xin.Xin` java process is already running.
9. Start the node via `bin/start.sh` (or `bin/start.bat`).
10. Poll `GET /api?requestType=getBlockchainStatus` until it returns 200, up to a timeout (default 90s). Tail `console.log` + `xin.log` while waiting and **fail fast** on `BindException` / `Address already in use` / `Failed to start`. If the API answers but our `$NODE_PID` has died, fail with "somebody else is on this port" — protects against false positives from a pre-existing node.
11. Service checks (each must pass):
    - peer port is in `LISTEN` state
    - `getBlockchainStatus` returns `application=XIN`, `version`, `numberOfBlocks`
    - `getTime` returns a numeric `time` field
    - `getPeers` returns a `peers` array
    - **`/wallet/index.html` responds 200** (the URL the desktop opens on launch — fails today until iep-wallet-ui is bundled into iep-node's `html/www/`, mirroring `iep-node/Dockerfile` lines 7-10)
    - `getState` returns `numberOfPeers` (best-effort; non-fatal if it times out)
12. **On success**: stop the node via `bin/stop.sh` (or `bin/stop.bat`), run the izpack uninstaller, remove the test root and `~/.iep`. **On failure**: leave everything in place (node running, install dir, logs, node home) and print the manual cleanup command — the failure logs are precisely what you'll want to inspect.

Cleanup runs even on failure or interrupt (bash `trap`, PowerShell `try/finally`).

## Local usage

```bash
# Linux / macOS (from the iep-node-installer/ directory)
./test/test-installer.sh

# Windows (PowerShell, from the iep-node-installer\ directory)
.\test\test-installer.ps1
```

Useful overrides:

| Variable / parameter | Bash env | PowerShell param | Default |
|---|---|---|---|
| Target environment | `TEST_ENV=testnet` | `-TestEnv testnet` | `mainnet` |
| API port (override) | `API_PORT=9876` | `-ApiPort 9876` | 23457 mainnet / 9876 testnet |
| Ready timeout (s) | `READY_TIMEOUT_S=180` | `-ReadyTimeoutSec 180` | `90` |
| Admin password | `ADMIN_PASSWORD=...` | `-AdminPassword ...` | `Smoketest123!` |
| Force rebuild | `REBUILD=1` | `-Rebuild` | off |
| Keep test dir | `KEEP=1` | `-Keep` | off (cleanup on exit) |
| Allow ~/.iep to be deleted | `CLOBBER_HOME=1` | `$env:CLOBBER_HOME='1'` | off (refuse if pre-existing) |

## CI integration

The scripts are designed to drop into a job step. They:

- exit non-zero on any failure (the trap/finally still runs cleanup);
- write build/install/start logs to `$TEST_ROOT` so they can be uploaded as artifacts on failure;
- never touch any path outside `$TEST_ROOT` (work dir, install dir, options file all live there);
- need `java` on `PATH` (to launch the installer) and `curl` (Linux/macOS) / `Invoke-RestMethod` (Windows).

Example GitLab job (Linux runner):

```yaml
test-installer-linux:
  stage: test
  needs: [build-installer-linux]
  script:
    - ./iep-node-installer/test/test-installer.sh
  artifacts:
    when: on_failure
    paths:
      - /tmp/iep-installer-test-*/install.log
      - /tmp/iep-installer-test-*/start.log
```

(Adjust paths to your runner's `TMPDIR` if needed; on most Linux runners `/tmp/iep-installer-test-*` works.)

## What this does NOT cover

- The H2 1.4 → 2.x **migration** itself: that needs a pre-existing legacy `xin.h2.db` snapshot to migrate. Since 0.4.3 the H2 1.4 engine is no longer shipped; such a database has to go through release 0.4.2 first (or the operator supplies the jar). See `HANDOFF.md` §2 for the dry-run procedure.
- GUI / desktop mode: tests run in headless command-line mode (`xin.runtime.mode` defaults to `desktop`, but no display is required for the API to come up).
- Cross-network behavior: only checks that `getBlockchainStatus` returns; doesn't validate sync against peers.
