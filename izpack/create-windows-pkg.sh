#!/bin/bash
set -o errexit
set -o nounset

export BUILD_DIR=$(cd "$(dirname "$0")/../build" && pwd -P);
echo "BUILD_DIR=${BUILD_DIR}"

cp -f  windows/7zz ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe
chmod u+x ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe

cp -f windows/7zS.sfx ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe/7zS.sfx
#cp -f windows/izpack2exe.py ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe/izpack2exe.py

(cd ${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe && \
python3 izpack2exe.py \
	--file ${BUILD_DIR}/distributions/iep-node-installer.jar \
	--output ${BUILD_DIR}/distributions/iep-node-installer.exe \
	--with-7z=${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe/7zz \
	--no-upx \
	--name xin \
	--with-jdk ${BUILD_DIR}/../downloads/win_unpack/jdk-11.0.12+7-jre)
#	--with-upx=${BUILD_DIR}/izpack-utils/utils/wrappers/izpack2exe/UPX)
