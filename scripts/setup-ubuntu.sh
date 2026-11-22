#!/usr/bin/env bash
set -euo pipefail
command -v flutter
command -v java
command -v sdkmanager
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "ndk;28.2.13676358"
flutter doctor -v
flutter pub get
