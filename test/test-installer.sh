#!/usr/bin/env bash
#
# End-to-end smoke test for the iep-node Linux/macOS installer package.
# Builds (if needed), installs, starts the node, polls a few APIs, stops, uninstalls.
# CI-friendly: exits non-zero on any failure; cleans up via trap.
# Local-friendly: just run `./test/test-installer.sh` from the project root or this dir.
#
# Env overrides (all optional):
#   TEST_ENV         testnet | mainnet            (default: testnet)
#   API_PORT         override polled port         (default: 9876 for testnet, 23457 for mainnet)
#   API_HOST         host the API binds to        (default: 127.0.0.1)
#   READY_TIMEOUT_S  wait for /api up             (default: 90)
#   ADMIN_PASSWORD   admin password for install   (default: Smoketest123!)
#   REBUILD          force rebuild before test    (default: 0; set to 1 to force)
#   KEEP             skip cleanup, leave install  (default: 0; set to 1 to inspect)

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
INSTALLER_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P)
INSTALLER_JAR="$INSTALLER_DIR/build/distributions/iep-node-installer.jar"

TEST_ENV="${TEST_ENV:-mainnet}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Smoketest123!}"
API_HOST="${API_HOST:-127.0.0.1}"
READY_TIMEOUT_S="${READY_TIMEOUT_S:-90}"
REBUILD="${REBUILD:-0}"
KEEP="${KEEP:-0}"

# Default ports per environment (matches iep-node/conf/{mainnet,testnet}.properties:
#   xin.apiServerPort + xin.peerServerPort).
case "$TEST_ENV" in
    testnet) DEFAULT_API_PORT=9876 ; DEFAULT_PEER_PORT=8776  ;;
    mainnet) DEFAULT_API_PORT=23457; DEFAULT_PEER_PORT=23456 ;;
    *) echo "Unknown TEST_ENV=$TEST_ENV (expected testnet|mainnet)" >&2; exit 2 ;;
esac
API_PORT="${API_PORT:-$DEFAULT_API_PORT}"
PEER_PORT="${PEER_PORT:-$DEFAULT_PEER_PORT}"

TEST_ROOT=$(mktemp -d -t iep-installer-test-XXXXXX)
INSTALL_PATH="$TEST_ROOT/install"
OPTIONS_FILE="$TEST_ROOT/options.txt"
NODE_HOME_DIR="$HOME/.iep"     # iep-node always writes here (Java's user.home is from passwd, not $HOME)
NODE_PID=""

# Safety: refuse to run if the user already has an iep-node data dir in their home.
# Running the test would either fail on a stale DB (unique-key violation on genesis)
# or, worse, scribble into a real wallet's database. Override only if you know it's empty:
#   CLOBBER_HOME=1 ./test/test-installer.sh
if [[ -e "$NODE_HOME_DIR" && "${CLOBBER_HOME:-0}" != "1" ]]; then
    cat >&2 <<EOF
[test-installer][FAIL] $NODE_HOME_DIR already exists.
iep-node always writes its data dir to ~/.iep (Java user.home from passwd, not \$HOME),
so this test would either crash on a stale DB or pollute a real wallet's data.

Either:
  - back it up + remove it, then re-run; or
  - re-run with CLOBBER_HOME=1 to allow the test to delete it on cleanup.
EOF
    exit 2
fi

log()  { printf '\n[test-installer] %s\n' "$*"; }
fail() { printf '\n[test-installer][FAIL] %s\n' "$*" >&2; exit 1; }

# Cleanup runs only on success (rc=0) OR if KEEP=1 was explicitly set.
# On failure (or interrupt), the node, install dir, and ~/.iep are left intact
# so console.log + xin.log can be inspected. Print a manual-cleanup hint.
cleanup() {
    local rc=$?
    set +e
    if [[ $rc -ne 0 ]]; then
        cat >&2 <<EOF

[test-installer] preserving artifacts for analysis (rc=$rc):
  install root: $TEST_ROOT
    install:    $INSTALL_PATH
    install.log $TEST_ROOT/install.log
    start.log:  $TEST_ROOT/start.log
  node home:    $NODE_HOME_DIR
    console:    $NODE_HOME_DIR/logs/console.log
    xin.log:    $NODE_HOME_DIR/logs/xin.log

  node may still be running (pid=${NODE_PID:-?}); inspect with: ps -fp ${NODE_PID:-?}
  to clean up manually after analysis:
    [[ -x $INSTALL_PATH/bin/stop.sh ]] && $INSTALL_PATH/bin/stop.sh
    [[ -f $INSTALL_PATH/Uninstaller/uninstaller.jar ]] && \\
      $INSTALL_PATH/jre/bin/java -jar $INSTALL_PATH/Uninstaller/uninstaller.jar -c -f
    rm -rf $TEST_ROOT $NODE_HOME_DIR
EOF
        return $rc
    fi
    if [[ "$KEEP" == "1" ]]; then
        log "KEEP=1 set; leaving $TEST_ROOT and $NODE_HOME_DIR for inspection (rc=$rc)"
        return $rc
    fi
    # Success path: stop node, run uninstaller, remove dirs.
    if [[ -n "$NODE_PID" ]] && kill -0 "$NODE_PID" 2>/dev/null; then
        log "stopping node (pid=$NODE_PID via bin/stop.sh)"
        [[ -x "$INSTALL_PATH/bin/stop.sh" ]] && "$INSTALL_PATH/bin/stop.sh" >/dev/null 2>&1
        sleep 2
        kill "$NODE_PID" 2>/dev/null || true
        sleep 1
        kill -9 "$NODE_PID" 2>/dev/null || true
    fi
    pkill -f "$INSTALL_PATH" 2>/dev/null || true
    if [[ -f "$INSTALL_PATH/Uninstaller/uninstaller.jar" ]]; then
        log "running izpack uninstaller"
        "$INSTALL_PATH/jre/bin/java" -jar "$INSTALL_PATH/Uninstaller/uninstaller.jar" -c -f >/dev/null 2>&1 || true
    fi
    rm -rf "$TEST_ROOT"
    if [[ -d "$NODE_HOME_DIR" ]]; then
        log "removing test-created node home: $NODE_HOME_DIR"
        rm -rf "$NODE_HOME_DIR"
    fi
    log "cleaned $TEST_ROOT (rc=$rc)"
    return $rc
}
trap cleanup EXIT INT TERM

# port_in_use <port> — exit 0 if something is listening on it, 1 otherwise.
port_in_use() {
    if command -v ss >/dev/null 2>&1; then
        ss -ltn 2>/dev/null | awk '{print $4}' | grep -E ":${1}\$" -q
    else
        netstat -ltn 2>/dev/null | awk '{print $4}' | grep -E ":${1}\$" -q
    fi
}

# 0. Pre-flight: refuse if anything will collide with the node we're about to start.
log "preflight: checking ports $API_PORT (api) and $PEER_PORT (peer) are free, no stale iep-node processes"
if port_in_use "$API_PORT"; then
    fail "API port $API_PORT is already in use. Free it before running:
  ss -ltnp 2>/dev/null | grep ':$API_PORT '
  (the test cannot tell if a passing API check came from our node or an existing one)"
fi
if port_in_use "$PEER_PORT"; then
    fail "peer port $PEER_PORT is already in use. Free it before running:
  ss -ltnp 2>/dev/null | grep ':$PEER_PORT '"
fi
existing_node_pids=$(pgrep -f 'xin\.Xin' 2>/dev/null | tr '\n' ' ' || true)
if [[ -n "$existing_node_pids" ]]; then
    fail "an iep-node process is already running (pids: $existing_node_pids). Stop it first:
  for p in $existing_node_pids; do kill \$p; done"
fi

# 1. Build the linux installer. Always run create-linux-installer.sh — gradle's
#    UP-TO-DATE checks make it cheap if nothing changed, and this guarantees
#    iep-node-installer.jar is the LINUX-flavoured one. (build-docker.sh builds
#    all three platforms in sequence and overwrites this jar with the windows
#    variant last; running on Linux against that jar fails on `chmod bin/java`.)
log "ensuring installer is linux-flavoured (create-linux-installer.sh)"
(cd "$INSTALLER_DIR" && ./create-linux-installer.sh) > "$TEST_ROOT/build.log" 2>&1 \
    || { tail -30 "$TEST_ROOT/build.log"; fail "installer build failed"; }
[[ -f "$INSTALLER_JAR" ]] || fail "installer jar not found at $INSTALLER_JAR"
log "using installer: $INSTALLER_JAR ($(du -h "$INSTALLER_JAR" | cut -f1))"

# 2. Generate options file (consumed by `java -jar installer.jar -options ...`).
cat > "$OPTIONS_FILE" <<EOF
INSTALL_PATH=$INSTALL_PATH
iep.installer.targetEnv=$TEST_ENV
xin.installer.startAfterInstallation=false
iep.installer.xin.adminPassword=$ADMIN_PASSWORD
EOF

# 3. Install (unattended). Redirect stdin from /dev/null: izpack 5's console mode
#    prompts for language confirmation when stdin is a tty, even with -options.
#    With /dev/null it auto-selects the default (English).
log "installing to $INSTALL_PATH (env=$TEST_ENV)"
java -jar "$INSTALLER_JAR" -options "$OPTIONS_FILE" < /dev/null > "$TEST_ROOT/install.log" 2>&1 \
    || { tail -30 "$TEST_ROOT/install.log"; fail "install failed"; }
grep -q '\[ Console installation done \]' "$TEST_ROOT/install.log" \
    || { tail -30 "$TEST_ROOT/install.log"; fail "install did not complete"; }

# 4. Verify install layout + bundled JRE.
for d in bin jre lib scripts; do
    [[ -d "$INSTALL_PATH/$d" ]] || fail "missing $d/ in install"
done
[[ -x "$INSTALL_PATH/jre/bin/java" ]] || fail "bundled JRE binary not present"
JRE_VERSION=$("$INSTALL_PATH/jre/bin/java" -version 2>&1 | head -1)
echo "$JRE_VERSION" | grep -q '21\.' || fail "bundled JRE is not JDK 21: $JRE_VERSION"
log "bundled JRE: $JRE_VERSION"
# Since 0.4.3 the H2 1.4 engine is no longer shipped (critical CVEs).
[[ ! -e "$INSTALL_PATH/legacy_libs/h2-1.4.191.jar" ]] \
    || fail "the H2 1.4 jar (critical CVEs) is still shipped"

# 5. Start node. `start.sh` is a wrapper that nohups bin/iep-node and exits;
#    the actual daemon pid is written by start.sh to $NODE_HOME_DIR/iep-node.pid.
log "starting node via bin/start.sh"
nohup "$INSTALL_PATH/bin/start.sh" > "$TEST_ROOT/start.log" 2>&1 &
PID_FILE="$NODE_HOME_DIR/iep-node.pid"
for _ in $(seq 1 15); do
    [[ -f "$PID_FILE" ]] && NODE_PID=$(cat "$PID_FILE") && break
    sleep 1
done
[[ -n "$NODE_PID" ]] || fail "iep-node.pid not written by start.sh within 15s"
log "node daemon pid=$NODE_PID; polling http://$API_HOST:$API_PORT"

# 6. Wait for the API server to be reachable. While waiting, also tail console.log
#    for bind errors — if our node failed to bind the port, fail fast instead of
#    waiting for the timeout (and instead of being fooled by something else
#    answering on the same port).
deadline=$(( $(date +%s) + READY_TIMEOUT_S ))
console_log="$NODE_HOME_DIR/logs/console.log"
xin_log="$NODE_HOME_DIR/logs/xin.log"
bcs_response=""
while :; do
    # Fail fast on bind errors visible in either log.
    for f in "$console_log" "$xin_log"; do
        if [[ -f "$f" ]] && grep -qE 'BindException|Address already in use|Failed to start|java\.net\.BindException' "$f"; then
            echo "---bind error detected in $f ---" >&2
            grep -E 'BindException|Address already in use|Failed to start|java\.net\.BindException' "$f" | head -5 >&2
            fail "node failed to bind ports — aborting (test root + node home preserved)"
        fi
    done
    # Confirm the node we started owns the API port (refuse a positive answer
    # from somebody else's listener — this is what bit us before).
    if bcs_response=$(curl -sf --max-time 5 \
        "http://$API_HOST:$API_PORT/api?requestType=getBlockchainStatus" 2>/dev/null); then
        if [[ -n "$NODE_PID" ]] && kill -0 "$NODE_PID" 2>/dev/null; then
            break
        fi
        fail "API responded but node parent pid $NODE_PID is gone — somebody else is on $API_PORT"
    fi
    if [[ $(date +%s) -ge $deadline ]]; then
        echo "---last 40 lines of $console_log---" >&2
        tail -40 "$console_log" 2>/dev/null || tail -40 "$TEST_ROOT/start.log" 2>/dev/null
        fail "API never came up within ${READY_TIMEOUT_S}s"
    fi
    sleep 2
done
log "API responded; sample of getBlockchainStatus:"
echo "$bcs_response" | head -c 400; echo

# 7. Service checks.

# 7a. Peer service — peer port must be in LISTEN state.
if ! port_in_use "$PEER_PORT"; then
    fail "peer service not listening on port $PEER_PORT"
fi
log "peer service listening on $PEER_PORT ✓"

# 7b. getBlockchainStatus content (the main blockchain subsystem).
echo "$bcs_response" | grep -q '"application":"XIN"' \
    || fail "getBlockchainStatus did not report application=XIN"
echo "$bcs_response" | grep -q '"numberOfBlocks"' \
    || fail "getBlockchainStatus missing numberOfBlocks"
echo "$bcs_response" | grep -q '"version":"' \
    || fail "getBlockchainStatus missing version"

# 7c. getTime — simplest API sanity check.
time_response=$(curl -sf --max-time 5 \
    "http://$API_HOST:$API_PORT/api?requestType=getTime") \
    || fail "getTime failed"
echo "$time_response" | grep -qE '"time":[0-9]+' \
    || fail "getTime did not return a numeric time field"

# 7d. getPeers — verifies the peer subsystem is initialised and queryable.
peers_response=$(curl -sf --max-time 10 \
    "http://$API_HOST:$API_PORT/api?requestType=getPeers") \
    || fail "getPeers failed"
echo "$peers_response" | grep -q '"peers"' \
    || fail "getPeers did not return a peers array"

# 7d.bis. /wallet/index.html — the desktop opens this URL on launch.
#         iep-node serves /wallet/* from <install>/html/www/. Without the wallet
#         UI bundled there, jetty's DefaultServlet returns 404 and the desktop
#         shows "HTTP ERROR 404 Not Found". The Docker build of iep-node
#         (Dockerfile lines 7-10) copies iep-wallet-ui.zip into html/www/wallet/;
#         the installer build path needs an equivalent step.
wallet_status=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 \
    "http://$API_HOST:$API_PORT/wallet/index.html" 2>/dev/null || echo "000")
if [[ "$wallet_status" != "200" ]]; then
    fail "/wallet/index.html returned HTTP $wallet_status (expected 200) — wallet UI is not bundled. \
Expected at: $INSTALL_PATH/html/www/wallet/index.html. \
Fix: bundle iep-wallet-ui.zip into iep-node's distZip (mirror Dockerfile lines 7-10)."
fi
log "/wallet/index.html responds 200 (desktop wallet UI bundled) ✓"

# 7e. getState — heavier (counts assets/orders/etc.); best-effort only.
if state_response=$(curl -sf --max-time 15 \
    "http://$API_HOST:$API_PORT/api?requestType=getState" 2>/dev/null); then
    echo "$state_response" | grep -q '"numberOfPeers"' \
        || fail "getState response missing numberOfPeers"
    log "getState excerpt:"
    echo "$state_response" | head -c 400; echo
else
    log "getState did not respond within 15s — non-fatal, continuing"
fi

log "all checks passed"
exit 0
