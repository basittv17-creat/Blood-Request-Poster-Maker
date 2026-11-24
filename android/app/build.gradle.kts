import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val ciKeystore = providers.environmentVariable("BLOOD_RELEASE_KEYSTORE").orNull
val signingFile = rootProject.file("key.properties")
val releaseKeys = Properties().apply {
    if (signingFile.isFile) signingFile.inputStream().use { load(it) }
}

val useOwnerSigning = ciKeystore != null || signingFile.isFile

android {
    namespace = "com.awasigogera.blood"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    if (useOwnerSigning) {
        signingConfigs {
            create("ownerRelease") {
                if (ciKeystore != null) {
                    storeFile = rootProject.file(ciKeystore)
                    check(storeFile!!.isFile) { "CI release keystore is missing" }
                    storePassword = requireNotNull(providers.environmentVariable("KEYSTORE_PASSWORD").orNull)
                    keyAlias = requireNotNull(providers.environmentVariable("KEY_ALIAS").orNull)
                    keyPassword = requireNotNull(providers.environmentVariable("KEY_PASSWORD").orNull)
                } else {
                    storeFile = rootProject.file(requireNotNull(releaseKeys.getProperty("storeFile")))
                    storePassword = requireNotNull(releaseKeys.getProperty("storePassword"))
                    keyAlias = requireNotNull(releaseKeys.getProperty("keyAlias"))
                    keyPassword = requireNotNull(releaseKeys.getProperty("keyPassword"))
                }
            }
        }
    }
    buildTypes {
        release {
            // The debug key is used only for local and CI phone-testing builds.
            signingConfig = if (useOwnerSigning) {
                signingConfigs.getByName("ownerRelease")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.awasigogera.blood"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core:1.15.0")
}
