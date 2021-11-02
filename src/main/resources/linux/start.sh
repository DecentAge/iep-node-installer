#!/bin/sh

export INSTALL_DIR=$(cd "$(dirname "$0")/.." && pwd -P);
export JAVA_HOME=${INSTALL_DIR}/jre


echo "INSTALL_DIR=${INSTALL_DIR}"
echo "JAVA_HOME=${JAVA_HOME}"

echo "***********************************************"
echo "** DEPRECATED: Use 'run.sh --desktop' instead **"
echo "***********************************************"
sleep 1
if [ -e ~/.xin/%{xin.app.name}.pid ]; then
    PID=`cat ~/.xin/%{xin.app.name}.pid`
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
export IEP_NODE_OPTS="-Dxin.runtime.mode=desktop"
nohup bin/%{xin.app.name}  > logs/console.log 2>&1 &
echo $! > ~/.xin/%{xin.app.name}.pid
cd - > /dev/null
