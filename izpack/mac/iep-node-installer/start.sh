#!/bin/sh

export INSTALL_DIR=$(cd "$(dirname "$0")/.." && pwd -P);
export JAVA_HOME=${INSTALL_DIR}/jre/Home


echo "INSTALL_DIR=${INSTALL_DIR}"
echo "JAVA_HOME=${JAVA_HOME}"

echo "***********************************************"
echo "** DEPRECATED: Use 'run.sh --desktop' instead **"
echo "***********************************************"
sleep 1
if [ -e ~/.xin/iep-node.pid ]; then
    PID=`cat ~/.xin/iep-node.pid`
    ps -p $PID > /dev/null
    STATUS=$?
    if [ $STATUS -eq 0 ]; then
        echo "Nxt server already running"
        exit 1
    fi
fi

mkdir -p ~/.xin/
cd "${INSTALL_DIR}"
mkdir -p logs
echo "Starting node in ${PWD}"
export IEP_NODE_OPTS="--module-path ${INSTALL_DIR}/javafx-sdk/lib --add-modules javafx.controls,javafx.web --add-exports javafx.web/com.sun.javafx.webkit=ALL-UNNAMED -Dxin.runtime.mode=desktop"
bin/iep-node
echo $! > ~/.xin/iep-node.pid
cd - > /dev/null
