# Release checklist

- Confirm all required tests on the proposed PR head, inspect the twelve sample outputs, and verify existing findings are resolved.
- Install/uninstall the test APK on supported Android devices and verify package ID, version, and the published checksum.
- Configure an owner-controlled release keystore through secure build secrets. Verify the certificate on signed artifacts.
- Verify the official download URL and share invitation on target apps.
- Obtain approval before publishing an APK release or listing. Merge only after mandatory acceptance gates pass.
