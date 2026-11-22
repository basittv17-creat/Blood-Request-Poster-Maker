# Test plan

Run `dart format --output=none --set-exit-if-changed lib test integration_test`, `flutter analyze`, and `flutter test`. Renderer tests write twelve fictional Urdu examples to `build/demo-posters`. Inspect the output for joining, line breaks, and safe margins. Emulators exercise native storage, language switching, and JPEG decoding with Wi-Fi and mobile data disabled on APIs 29, 35, and 36.

Manual gates remain: test long mixed-direction text, preview/export parity, TalkBack, keyboard/rotation/resume, low-memory retry, fresh installs, save/open/cancel, actual WhatsApp/Telegram/Gmail/Messages caption behavior, official link correctness, and production signing. Record device model, Android API, app versions, expected and actual behavior, and evidence before merge.
