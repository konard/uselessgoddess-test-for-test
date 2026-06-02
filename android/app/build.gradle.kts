plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Issue #1 requires Android 6.0 (API 23). Flutter's MinSdkVersionMigration
// rewrites a literal `minSdk = 23` back to `flutter.minSdkVersion` (24) on every
// build, so the value is assigned through this property to keep API 23.
val issueMinSdk = 23

android {
    namespace = "com.example.native_geofence_test.native_geofence_test"
    // native_geofence -> androidx.work:work-runtime:2.10.2 requires compiling
    // against API 35+. This is independent of minSdk (still 23).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time APIs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.native_geofence_test.native_geofence_test"
        // Android 6.0 (API 23) is the minimum required by the issue.
        minSdk = issueMinSdk
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
