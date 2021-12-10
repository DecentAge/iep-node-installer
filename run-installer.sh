#!/bin/bash
set -o errexit
set -o nounset

$HOME/IEP/bin/stop.sh 2>/dev/null || (pkill -9 -ef "xin.runtime.mode=desktop" ||  echo "Could not kill running node")


rm -rf $HOME/IEP;
rm -rf $HOME/.iep;

java -jar build/distributions/iep-node-installer.jar