#!/bin/bash

export INSTALLER_DIR=$(cd "$(dirname "$BASH_SOURCE")/.." && pwd -P);
echo "INSTALLER_DIR=${INSTALLER_DIR}"

dos2unix ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2run/linux_stub

java -Dfile.encoding=UTF-8 -cp ${INSTALLER_DIR}/build/izpack-utils utils.wrappers.izpack2run.Merge2In1 ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2run/linux_stub ${INSTALLER_DIR}/build/distributions/iep-node-installer.jar ${INSTALLER_DIR}/build/distributions/iep-node-installer.run