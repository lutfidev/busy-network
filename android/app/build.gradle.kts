import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Kunci upload rilis: android/key.properties (tidak masuk git), isinya
// storeFile, storePassword, keyAlias, keyPassword. Tanpa file itu, build
// release ditandatangani kunci debug supaya `flutter run --release` tetap
// jalan; bundle seperti itu ditolak Play Console.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKey = keystorePropertiesFile.exists()
if (hasReleaseKey) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "dev.lutfidev.jaringansibuk"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // ID final di Play Store: tidak bisa diganti setelah rilis pertama.
        applicationId = "dev.lutfidev.jaringansibuk"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Diambil dari `version:` di pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                fun key(name: String): String =
                    keystoreProperties.getProperty(name)
                        ?: error("android/key.properties: '$name' belum diisi")
                storeFile = file(key("storeFile"))
                storePassword = key("storePassword")
                keyAlias = key("keyAlias")
                keyPassword = key("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(
                if (hasReleaseKey) "release" else "debug",
            )
        }
    }
}

// Peringatan hanya saat yang dibangun memang release.
if (!hasReleaseKey &&
    gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }
) {
    logger.warn("android/key.properties tidak ada: release ditandatangani kunci debug.")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
