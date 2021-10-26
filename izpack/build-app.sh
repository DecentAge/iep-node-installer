#!/bin/bash
export INSTALLER_DIR=$(cd "$(dirname "$0")/.." && pwd -P);
echo "INSTALLER_DIR=${INSTALLER_DIR}"

rm -rf ${INSTALLER_DIR}/build/distributions/iep-node.app

(cd ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2app && \
python3 izpack2app.py \
${INSTALLER_DIR}/build/distributions/iep-node-installer.jar \
${INSTALLER_DIR}/build/distributions/iep-node.app)
sed -i 's/1.4\+/11/' ${INSTALLER_DIR}/build/distributions/iep-node.app/Contents/Info.plist