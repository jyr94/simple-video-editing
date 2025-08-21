plugins {
    id("com.android.application") version "8.6.0"
    id("org.jetbrains.kotlin.android") version "2.1.0"
    // Flutter plugin harus setelah Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

repositories {
    google()
    mavenCentral()
    maven(url = "https://storage.googleapis.com/download.flutter.io")
}

android {
    namespace = "com.example.simple_video_editing"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.2.12479018"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    defaultConfig {
        applicationId = "com.example.simple_video_editing"
        minSdk = maxOf(24, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // TEMPORER untuk unblocking: samakan hash dengan ABI yang muncul di dependency graph kamu
    debugImplementation("io.flutter:flutter_embedding_debug:1.0.0-1e9a811bf8e70466596bcf0ea3a8b5adb5f17f7f")
    profileImplementation("io.flutter:flutter_embedding_profile:1.0.0-1e9a811bf8e70466596bcf0ea3a8b5adb5f17f7f")
    releaseImplementation("io.flutter:flutter_embedding_release:1.0.0-1e9a811bf8e70466596bcf0ea3a8b5adb5f17f7f")
}

flutter { source = "../.." }
