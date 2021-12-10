#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

./gradlew createLinuxInstaller --no-daemon -Penv=linux