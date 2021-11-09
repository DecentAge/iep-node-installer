#!/bin/bash
set -o errexit
set -o nounset

export BUILD_DIR=$(cd "$(dirname "$0")/../.." && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"

#rm -rf ${BUILD_DIR}/build/distributions/iep-node.app

which java

JAVA_HOME="$(cd $(dirname $(readlink -f $(which java)))/..; pwd)"
echo JAVA_HOME=$JAVA_HOME
$JAVA_HOME/bin/javapackager -deploy \
-outdir . \
-outfile ardor-client \
-name ardor-installer \
-width 34 \
-height 43 \
-native dmg \
-srcfiles iep-node.jar \
-appclass com.izforge.izpack.installer.bootstrap.Installer \
-v \
-Bmac.category=Business \
-Bmac.CFBundleIdentifier=org.ardor.client.installer \
-Bmac.CFBundleName=Ardor-Installer \
-Bmac.CFBundleVersion=${MACVERSION} \
-BappVersion=${MACVERSION} \
-Bicon=installer/AppIcon.icns > installer/javapackager.log 2>&1


#(cd ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2app && \
#python3 izpack2app.py \
#${BUILD_DIR}/distributions/iep-node-installer.jar \
#${BUILD_DIR}/distributions/iep-node.app)
#sed -i 's/1.4\+/11/' ${BUILD_DIR}/distributions/iep-node.app/Contents/Info.plist