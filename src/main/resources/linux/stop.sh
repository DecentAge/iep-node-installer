#!/bin/sh
if [ -e ~/.xin/%{xin.app.name}.pid ]; then
    PID=`cat ~/.xin/%{xin.app.name}.pid`
    ps -p $PID > /dev/null
    STATUS=$?
    echo "stopping"
    while [ $STATUS -eq 0 ]; do
        kill `cat ~/.xin/%{xin.app.name}.pid` > /dev/null
        sleep 5
        ps -p $PID > /dev/null
        STATUS=$?
    done
    rm -f ~/.xin/%{xin.app.name}.pid
    echo "Xin server stopped"
fi