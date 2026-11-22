# Getting started

Use Flutter 3.50.1, Java 21, and Android command-line tools. Run `bash scripts/setup-ubuntu.sh`, then `flutter run` with an Android device connected. For installable test builds use `flutter build apk --debug`.

Set `--dart-define=APP_DOWNLOAD_URL=https://...` only after verifying a public official HTTPS landing page or listing. Without that setting the image-only sharing option is available. A release build is unsigned until the owner configures signing.

For owner-signed builds, put the private keystore outside the checkout and place an ignored `android/key.properties` file with `storeFile` (absolute path), `storePassword`, `keyAlias`, and `keyPassword`. In secured CI, materialize both files from owner-managed secrets. Run `flutter build apk --release` or `flutter build appbundle --release` and independently check the signer certificate. Keep this workflow's test packages separate from production distribution.
