#!/bin/bash
set -o errexit
set -o nounset

export BUILD_DIR=$(cd "$(dirname "$0")/../.." && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"

#rm -rf ${BUILD_DIR}/build/distributions/iep-node.app

export MACVERSION="10.16.4"
JAVA_HOME="$(cd $(dirname $(readlink -f $(which java)))/..; pwd)"
echo JAVA_HOME=$JAVA_HOME

javapackager -deploy -native dmg -v \
-outdir "${BUILD_DIR}/distributions/dmg" \
-outfile iep-node-installer-ws \
-name iep-node-installer \
-width 34 \
-height 43 \
-srcdir "${BUILD_DIR}/distributions" \
-srcfiles iep-node-installer.jar \
-appclass "com.izforge.izpack.installer.bootstrap.Installer" \
-Bmac.category=Business \
-Bmac.CFBundleIdentifier=xin.client.installer \
-Bmac.CFBundleName=iep-node-installer \
-Bmac.CFBundleVersion=${MACVERSION} \
-BappVersion=${MACVERSION} \
-Bicon=installer/AppIcon.icns
 


#(cd ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2app && \
#python3 izpack2app.py \
#${BUILD_DIR}/distributions/iep-node-installer.jar \
#${BUILD_DIR}/distributions/iep-node.app)
#sed -i 's/1.4\+/11/' ${BUILD_DIR}/distributions/iep-node.app/Contents/Info.plist