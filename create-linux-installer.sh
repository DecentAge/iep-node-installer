#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

./gradlew clean createLinuxInstaller --no-daemon -Penv=linux