#!/bin/sh

export INSTALL_DIR=$(cd "$(dirname "$0")/.." && pwd -P);
echo "INSTALL_DIR=${INSTALL_DIR}"
echo "***********************************************"
echo "** DEPRECATED: Use 'run.sh --desktop' instead **"
echo "***********************************************"
sleep 1
if [ -e ~/.xin/xin.pid ]; then
    PID=`cat ~/.xin/xin.pid`
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
nohup bin/iep-node  > logs/console.log 2>&1 &
echo $! > ~/.xin/xin.pid
cd - > /dev/null
