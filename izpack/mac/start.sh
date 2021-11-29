#!/bin/sh

export INSTALL_DIR=$(cd "$(dirname "$0")/.." && pwd -P);
export JAVA_HOME=${INSTALL_DIR}/jre
export WORK_DIR=$(readlink -f  ~/.xin)

sleep 1
if [ -e ${WORK_DIR}/%{xin.app.name}.pid ]; then
    PID=`cat ${WORK_DIR}/%{xin.app.name}.pid`
    ps -p $PID > /dev/null
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
        echo "IEP node already running"
        exit 1
    fi
fi

mkdir -p ${WORK_DIR}/
cd "${INSTALL_DIR}"
mkdir -p logs
echo "Starting node in ${PWD}"
export IEP_NODE_OPTS="--module-path ${INSTALL_DIR}/javafx-sdk/lib --add-modules javafx.controls,javafx.web --add-exports javafx.web/com.sun.javafx.webkit=ALL-UNNAMED -Dxin.workDir=${WORK_DIR} -Dxin.runtime.mode=desktop"
nohup bin/%{xin.app.name}  > ${WORK_DIR}/logs/console.log 2>&1 &
echo $! > ${WORK_DIR}/%{xin.app.name}.pid
cd - > /dev/null
