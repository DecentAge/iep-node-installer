#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

./gradlew createWindowsInstaller --no-daemon -Penv=windows