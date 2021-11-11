#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

./gradlew createMacInstaller --no-daemon -Penv=mac