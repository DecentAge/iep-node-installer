#!/bin/bash
# Build the linux, macOS, and windows installer artifacts inside a containerised
# gradle 8.12 / JDK 21 image. The build.gradle loads `${env}.properties` once at
# configuration time, so each platform must be its own gradle invocation.
set -o errexit
set -o pipefail
set -o nounset

export BASE_DIR=$(cd "$(dirname "$BASH_SOURCE")" && pwd -P);
export BASE_PARENT_DIR=$(dirname "$BASE_DIR")
echo "BASE_DIR=${BASE_DIR}"
echo "BASE_PARENT_DIR=${BASE_PARENT_DIR}"

# Precondition: iep-wallet-ui must already be built (its build-docker.sh produces
# build/iep-wallet-ui.zip). iep-node's build.gradle unpacks that into html/www/wallet/
# as part of distZip — without it the desktop wallet UI is missing and the
# /wallet/index.html service check in test-installer.sh will fail.
WALLET_ZIP="$BASE_PARENT_DIR/iep-wallet-ui/build/iep-wallet-ui.zip"
if [[ ! -f "$WALLET_ZIP" ]]; then
    cat >&2 <<EOF
ERROR: $WALLET_ZIP not found.
Build iep-wallet-ui first:
    ( cd $BASE_PARENT_DIR/iep-wallet-ui && ./build-docker.sh )
Then re-run this script.
EOF
    exit 1
fi

docker run --rm -u gradle \
    -v "$BASE_DIR":/home/gradle/iep-node-installer \
    -v "$BASE_PARENT_DIR/iep-node":/home/gradle/iep-node \
    -v "$BASE_PARENT_DIR/iep-wallet-ui":/home/gradle/iep-wallet-ui \
    -v gradle_cache:/home/gradle/.gradle \
    -w /home/gradle/iep-node-installer \
    gradle:8.12-jdk21 \
    sh -euxc '
        # 1. Build iep-node dist (distZip — bundles iep-wallet-ui.zip into html/www/wallet/
        #    via build.gradle, then mirrors the zip to build/iep-node.zip for install.xml).
        (cd /home/gradle/iep-node && ./gradlew distZip --no-daemon)
        # 2. Clean the installer build dir once, then run each platform wrapper.
        #    The wrappers no longer clean themselves, so artifacts from earlier
        #    platforms survive across calls.
        ./gradlew clean --no-daemon
        ./create-linux-installer.sh
        ./create-mac-installer.sh
        ./create-win-installer.sh
    '