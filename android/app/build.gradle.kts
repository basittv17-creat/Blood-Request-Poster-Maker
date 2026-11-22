import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingFile = rootProject.file("key.properties")
val releaseKeys = Properties().apply {
    if (signingFile.isFile) signingFile.inputStream().use { load(it) }
}

android {
    namespace = "org.basittv.blood_request"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    if (signingFile.isFile) {
        signingConfigs {
            create("ownerRelease") {
                storeFile = rootProject.file(requireNotNull(releaseKeys.getProperty("storeFile")))
                storePassword = requireNotNull(releaseKeys.getProperty("storePassword"))
                keyAlias = requireNotNull(releaseKeys.getProperty("keyAlias"))
                keyPassword = requireNotNull(releaseKeys.getProperty("keyPassword"))
            }
        }
        buildTypes {
            release {
                signingConfig = signingConfigs.getByName("ownerRelease")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.basittv.blood_request"
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
