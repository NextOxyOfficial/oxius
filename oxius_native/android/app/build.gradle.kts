import java.util.Properties
import java.io.FileInputStream
import java.io.StringReader

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
    val bytes = keystorePropertiesFile.readBytes()
    val content = when {
        bytes.size >= 2 && bytes[0] == 0xFF.toByte() && bytes[1] == 0xFE.toByte() -> String(bytes, Charsets.UTF_16LE)
        bytes.size >= 2 && bytes[0] == 0xFE.toByte() && bytes[1] == 0xFF.toByte() -> String(bytes, Charsets.UTF_16BE)
        else -> String(bytes, Charsets.UTF_8)
    }

    keystoreProperties.load(StringReader(content))
}

fun keystoreProp(name: String): String? {
    return keystoreProperties.getProperty(name)
        ?: keystoreProperties.getProperty("\uFEFF$name")
}

val hasReleaseSigning =
    !keystoreProp("keyAlias").isNullOrBlank() &&
        !keystoreProp("keyPassword").isNullOrBlank() &&
        !keystoreProp("storePassword").isNullOrBlank() &&
        !keystoreProp("storeFile").isNullOrBlank()

android {
    namespace = "com.oxius.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
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
            if (!hasReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Please create android/key.properties with storeFile, storePassword, keyAlias, keyPassword."
                )
            }

            keyAlias = keystoreProp("keyAlias")
            keyPassword = keystoreProp("keyPassword")
            storeFile = file(keystoreProp("storeFile")!!)
            storePassword = keystoreProp("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Enable minification and obfuscation for Play Console
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // Disable native debug symbol stripping to avoid build issues
            ndk {
                debugSymbolLevel = "FULL"
            }
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

    implementation("androidx.camera:camera-core:1.4.0")
    implementation("androidx.camera:camera-camera2:1.4.0")
    implementation("androidx.camera:camera-lifecycle:1.4.0")
}
