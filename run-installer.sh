#!/bin/bash
set -o errexit
set -o nounset

$HOME/XIN/bin/stop.sh || echo "Could not stop running node"
# pkill -9 "xin.runtime.mode=desktop"
rm -rf $HOME/XIN;
rm -rf $HOME/.xin;

java -jar build/distributions/iep-node-installer.jar