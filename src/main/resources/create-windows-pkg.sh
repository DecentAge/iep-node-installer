#!/bin/bash
set -o errexit
set -o nounset

export BUILD_DIR=$(cd "$(dirname "$0")/../.." && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"

cp -f  windows/7zz ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe
chmod u+x ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe

cp -f windows/7zSD.sfx ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe/7zS.sfx

(cd ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe && \
python3 izpack2exe.py \
	--file ${BUILD_DIR}/distributions/iep-node-installer.jar \
	--output ${BUILD_DIR}/distributions/iep-node-installer.exe \
	--with-7z=${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe/7zz \
	--no-upx \
	--name xin \
	--with-jdk ${HOME}/jre/openlogic-openjdk-jre-11.0.9.1+1-windows-x64)
	
#--with-upx=${PROJECT_DIR}/build/izpack-utils/utils/wrappers/izpack2exe/UPX \
#--launch-args="-logfile /home/korax/git/iep-node-installer/iep-node-installer.log" \
#--with-jdk=/home/korax/jre/openlogic-openjdk-jre-11.0.9.1+1-windows-x64)
#--with-jdk=..\jdk