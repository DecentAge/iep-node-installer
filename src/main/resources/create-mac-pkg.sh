#!/bin/bash
set -o errexit
set -o nounset

export BUILD_DIR=$(cd "$(dirname "$0")/../.." && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"

#rm -rf ${BUILD_DIR}/build/distributions/iep-node.app

(cd ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2app && \
python3 izpack2app.py \
${BUILD_DIR}/distributions/iep-node-installer.jar \
${BUILD_DIR}/distributions/iep-node.app)
sed -i 's/1.4\+/11/' ${BUILD_DIR}/distributions/iep-node.app/Contents/Info.plist