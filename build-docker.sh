#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

export INSTALLER_DIR=$(cd "$(dirname "$0")" && pwd -P);
echo "INSTALLER_DIR=${INSTALLER_DIR}"
docker run --rm -u gradle \
-v "$INSTALLER_DIR":/home/gradle/iep-node-installer \
-v "$INSTALLER_DIR/..":/home/gradle/iep-node \
-v "$HOME/jre":/home/gradle/iep-node-installer/jre \
-w /home/gradle/iep-node-installer \
gradle \
gradle createInstallers --no-daemon