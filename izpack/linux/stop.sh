#!/bin/sh
if [ -e ~/.xin/xin.pid ]; then
    PID=`cat ~/.xin/xin.pid`
    ps -p $PID > /dev/null
    STATUS=$?
    echo "stopping"
    while [ $STATUS -eq 0 ]; do
        kill `cat ~/.xin/xin.pid` > /dev/null
        sleep 5
        ps -p $PID > /dev/null
        STATUS=$?
    done
    rm -f ~/.xin/xin.pid
    echo "Xin server stopped"
fi