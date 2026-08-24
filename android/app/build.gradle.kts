plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.swipeat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.swipeat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Debug は Google のテスト App ID。Release は ADMOB_APP_ID 環境変数で
        // 本番 App ID を注入し、Dart ソースへ秘密値を置かない。
        manifestPlaceholders["ADMOB_APP_ID"] =
            System.getenv("ADMOB_APP_ID")
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            val releaseAdmobAppId = System.getenv("ADMOB_APP_ID")
            if (
                releaseAdmobAppId.isNullOrBlank() &&
                    gradle.startParameter.taskNames.any {
                        it.contains("release", ignoreCase = true)
                    }
            ) {
                throw GradleException("ADMOB_APP_ID must be set for release builds")
            }
            manifestPlaceholders["ADMOB_APP_ID"] =
                releaseAdmobAppId
                    ?: "ca-app-pub-3940256099942544~3347511713"
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
