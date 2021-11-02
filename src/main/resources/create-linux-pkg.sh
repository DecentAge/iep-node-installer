#!/bin/bash
set -o errexit
set -o nounset

export BUILD_DIR=$(cd "$(dirname "$0")/../.." && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"
cp -f linux/linux_stub ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2run/linux_stub

chmod u+x linux/dos2unix
linux/dos2unix ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2run/linux_stub
java -Dfile.encoding=UTF-8 -cp ${BUILD_DIR}/izpack-utils utils.wrappers.izpack2run.Merge2In1 ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2run/linux_stub ${BUILD_DIR}/distributions/iep-node-installer.jar ${BUILD_DIR}/distributions/iep-node-installer.run