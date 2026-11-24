import java.io.File;
import java.io.OutputStream;
import java.security.KeyStore;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.Locale;
import java.util.jar.JarFile;
import javax.naming.ldap.LdapName;

class VerifyBundleSigning {
    public static void main(String[] args) throws Exception {
        var store = KeyStore.getInstance(
                new File(System.getenv("BLOOD_RELEASE_KEYSTORE")),
                System.getenv("KEYSTORE_PASSWORD").toCharArray());
        var certificate = store.getCertificate(System.getenv("KEY_ALIAS"));
        if (!(certificate instanceof X509Certificate expected)) {
            throw new IllegalStateException("Release signing certificate is missing");
        }
        expected.checkValidity();
        var subject = new LdapName(expected.getSubjectX500Principal().getName());
        if (subject.getRdns().stream().anyMatch(
                part -> part.getType().equalsIgnoreCase("CN")
                        && "Android Debug".equalsIgnoreCase(part.getValue().toString()))) {
            throw new IllegalStateException("The configured signing key is an Android debug key");
        }

        try (var bundle = new JarFile(args[0], true)) {
            if (bundle.getJarEntry("base/manifest/AndroidManifest.xml") == null) {
                throw new IllegalStateException("Android App Bundle manifest is missing");
            }
            var entries = bundle.entries();
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                if (entry.isDirectory() || isSignatureMetadata(entry.getName())) {
                    continue;
                }
                try (var contents = bundle.getInputStream(entry)) {
                    contents.transferTo(OutputStream.nullOutputStream());
                }
                var signers = entry.getCodeSigners();
                if (signers == null || !Arrays.stream(signers).anyMatch(signer ->
                        expected.equals(signer.getSignerCertPath().getCertificates().getFirst()))) {
                    throw new IllegalStateException("An AAB entry lacks the configured release signature");
                }
            }
        }
        System.out.println("AAB signature verified against the configured upload certificate.");
    }

    private static boolean isSignatureMetadata(String path) {
        String name = path.toUpperCase(Locale.ROOT);
        if (!name.startsWith("META-INF/")) {
            return false;
        }
        String leaf = name.substring("META-INF/".length());
        return !leaf.contains("/") && (leaf.equals("MANIFEST.MF")
                || leaf.endsWith(".SF") || leaf.endsWith(".RSA")
                || leaf.endsWith(".DSA") || leaf.endsWith(".EC"));
    }
}
