#!/usr/bin/env bash
set -euo pipefail

for name in KEYSTORE_BASE64 KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required signing secret: $name" >&2
    exit 1
  fi
done

umask 077
signing_dir="$(mktemp -d "${RUNNER_TEMP:?}/blood-release.XXXXXXXX")"
trap 'rm -rf -- "$signing_dir"' EXIT
export BLOOD_RELEASE_KEYSTORE="$signing_dir/upload.keystore"

printf '%s' "$KEYSTORE_BASE64" | base64 --decode > "$BLOOD_RELEASE_KEYSTORE"
unset KEYSTORE_BASE64
export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false"

flutter build appbundle --release
java scripts/VerifyBundleSigning.java build/app/outputs/bundle/release/app-release.aab
