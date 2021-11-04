#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

export BASE_DIR=$(cd "$(dirname "$BASH_SOURCE")" && pwd -P);
export BASE_PARENT_DIR=$(cd "$(dirname "$BASE_DIR")/.." && pwd -P);
echo "BASE_DIR=${BASE_DIR}"
echo "BASE_PARENT_DIR=${BASE_PARENT_DIR}"

docker run --rm -u gradle \
-v "$BASE_DIR":/home/gradle/iep-node-installer \
-v "$BASE_PARENT_DIR/iep-node":/home/gradle/iep-node \
-v "$HOME/jre":/home/gradle/iep-node-installer/jre \
-v gradle_cache:/home/gradle/.gradle \
-w /home/gradle/iep-node-installer \
gradle:6.9-jdk11-alpine \
/bin/sh -c "ls -alt /home/gradle/iep-node" && gradle createInstallers --no-daemon --build-cache