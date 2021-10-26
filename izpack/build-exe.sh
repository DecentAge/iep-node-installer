#!/bin/bash

export INSTALLER_DIR=$(cd "$(dirname "$BASH_SOURCE")/.." && pwd -P);
echo "INSTALLER_DIR=${INSTALLER_DIR}"
cp -f  ${INSTALLER_DIR}/izpack/linux/7zz ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2exe
chmod u+x ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2exe
cp -f ${INSTALLER_DIR}/izpack/linux/7zSD.sfx ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2exe/7zS.sfx

(cd ${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2exe && \
python3 izpack2exe.py \
	--file ${INSTALLER_DIR}/build/distributions/iep-node-installer.jar \
	--output ${INSTALLER_DIR}/build/distributions/iep-node-installer.exe \
	--with-7z=${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2exe/7zz \
	--no-upx \
	--name xin)
	
#--with-upx=${INSTALLER_DIR}/build/izpack-utils/utils/wrappers/izpack2exe/UPX \
#--launch-args="-logfile /home/korax/git/iep-node-installer/iep-node-installer.log" \
#--with-jdk=/home/korax/jre/openlogic-openjdk-jre-11.0.9.1+1-windows-x64)
#--with-jdk=..\jdk