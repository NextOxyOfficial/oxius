import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.oxius.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.oxius.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.containsKey("keyAlias")) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.containsKey("keyAlias")) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Temporarily disable minification to avoid symbol stripping issues
            isMinifyEnabled = false
            isShrinkResources = false
            // Disable native debug symbol stripping to avoid build issues
            ndk {
                debugSymbolLevel = "NONE"
            }
        }
    }

    packaging {
        jniLibs {
            keepDebugSymbols += listOf("**/*.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for image_cropper UCrop activity
    implementation("androidx.appcompat:appcompat:1.6.1")
    // Core library desugaring for flutter_local_notifications (requires 2.1.4+)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

tasks.matching { it.name.startsWith("stripReleaseDebugSymbols") }.configureEach {
    enabled = false
}

tasks.matching {
    it.name.contains("DebugSymbols", ignoreCase = true) &&
        it.name.contains("strip", ignoreCase = true) &&
        it.name.contains("Release", ignoreCase = true)
}.configureEach {
    enabled = false
}
