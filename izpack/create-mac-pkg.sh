#!/bin/bash
set -o errexit
set -o nounset

export BASE_DIR=$(cd "$(dirname "$0")/.." && pwd -P);
export BUILD_DIR=$(cd "$(dirname "$0")/../build" && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"

CONTENTS_TEMPLATE_DIR=${BASE_DIR}/izpack/mac/iep-node-installer/Contents

#rm -rf ${BUILD_DIR}/build/distributions/iep-node.app

export JAVA_HOME="$(cd $(dirname $(readlink -f $(which java)))/..; pwd)"
echo JAVA_HOME=$JAVA_HOME

mkdir -p ${BUILD_DIR}/distributions/iep-node-installer.app
cp -rf ${CONTENTS_TEMPLATE_DIR} ${BUILD_DIR}/distributions/iep-node-installer.app

mkdir -p ${BUILD_DIR}/distributions/iep-node-installer.app/Contents/Java
cp -rvf ${BUILD_DIR}/distributions/iep-node-installer.jar ${BUILD_DIR}/distributions/iep-node-installer.app/Contents/Java

mkdir -p ${BUILD_DIR}/distributions/iep-node-installer.app/Contents/PlugIns/jre
cp -rf ${BASE_DIR}/downloads/mac_unpack/jdk-11.0.12+7-jre/* ${BUILD_DIR}/distributions/iep-node-installer.app/Contents/PlugIns/jre

#(cd ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2app && \
#python3 izpack2app.py \
#${BUILD_DIR}/distributions/iep-node-installer.jar \
#${BUILD_DIR}/distributions/iep-node.app)
#sed -i 's/1.4\+/11/' ${BUILD_DIR}/distributions/iep-node.app/Contents/Info.plist