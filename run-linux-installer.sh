#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset
export BASE_DIR=$(cd "$(dirname "$BASH_SOURCE")" && pwd -P);
${BASE_DIR}/build/distributions/iep-node-installer.run