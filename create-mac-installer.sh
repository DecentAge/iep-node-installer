#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

export DEFAULT_NODE_PROJECT_PATH=$(cd "$(dirname "$BASH_SOURCE")/../iep-node" && pwd -P); 
export NODE_PROJECT_PATH=${1:-$DEFAULT_NODE_PROJECT_PATH}
echo "NODE_PROJECT_PATH=${NODE_PROJECT_PATH}"
./gradlew clean createMacInstallerTar --no-daemon -PnodeProjectPath=${NODE_PROJECT_PATH} -Penv=mac