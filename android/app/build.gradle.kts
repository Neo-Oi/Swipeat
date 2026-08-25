plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val configuredApplicationId = System.getenv("SWIPEAT_APPLICATION_ID")
val admobAppId = System.getenv("ADMOB_APP_ID")
val keystoreFile = System.getenv("ANDROID_KEYSTORE_FILE")
val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
val keyAlias = System.getenv("ANDROID_KEY_ALIAS")
val keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
val releaseSigningConfigured = listOf(
    keystoreFile,
    keystorePassword,
    keyAlias,
    keyPassword,
).all { !it.isNullOrBlank() }

if (releaseBuildRequested && configuredApplicationId.isNullOrBlank()) {
    throw GradleException("SWIPEAT_APPLICATION_ID must be set for release builds")
}
if (releaseBuildRequested && !releaseSigningConfigured) {
    throw GradleException(
        "ANDROID_KEYSTORE_FILE, ANDROID_KEYSTORE_PASSWORD, " +
            "ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD must be set for release builds",
    )
}
if (releaseBuildRequested && admobAppId.isNullOrBlank()) {
    throw GradleException("ADMOB_APP_ID must be set for release builds")
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
        // Debug は既存のID、Release は公開用IDをビルド環境から注入する。
        applicationId = configuredApplicationId ?: "com.example.swipeat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Debug は Google のテスト App ID。Release は ADMOB_APP_ID 環境変数で
        // 本番 App ID を注入し、Dart ソースへ秘密値を置かない。
        manifestPlaceholders["ADMOB_APP_ID"] =
            admobAppId
                ?: "ca-app-pub-3940256099942544~3347511713"
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = file(keystoreFile!!)
                storePassword = keystorePassword
                keyAlias = keyAlias
                keyPassword = keyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseSigningConfigured) {
                signingConfigs.getByName("release")
            } else {
                // Debugビルドの構成評価だけを通すフォールバック。Releaseタスクは上で停止する。
                signingConfigs.getByName("debug")
            }
            manifestPlaceholders["ADMOB_APP_ID"] =
                admobAppId
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
