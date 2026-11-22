#!/usr/bin/env bash
set -euo pipefail
adb shell svc wifi disable
adb shell svc data disable
flutter test integration_test
