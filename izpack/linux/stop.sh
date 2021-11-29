#!/bin/sh

export WORK_DIR=$(readlink -f  ~/.iep)
echo "WORK_DIR=${WORK_DIR}"

if [ -e ${WORK_DIR}/%{xin.app.name}.pid ]; then
    PID=`cat ${WORK_DIR}/%{xin.app.name}.pid`
    ps -p $PID > /dev/null
    STATUS=$?
    echo "stopping"
    while [ $STATUS -eq 0 ]; do
        kill `cat ${WORK_DIR}/%{xin.app.name}.pid` > /dev/null
        sleep 5
        ps -p $PID > /dev/null
        STATUS=$?
    done
    rm -f ${WORK_DIR}/%{xin.app.name}.pid
    echo "Xin server stopped"
fi