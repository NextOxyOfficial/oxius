plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Flutter 3.44 tooling defaults Kotlin to JVM target 21 while older plugins
// (flutter_facebook_auth etc.) still compile their Java at 1.8 — Gradle then
// fails with "Inconsistent JVM-target compatibility". Normalize every
// subproject to Java/Kotlin 17.
subprojects {
    // plugins.withId fires immediately when the plugin is already applied,
    // so this works even though :app forces early evaluation
    // (afterEvaluate would throw "project is already evaluated" here).
    listOf("com.android.library", "com.android.application").forEach { pluginId ->
        plugins.withId(pluginId) {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
                ?.apply {
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
        }
    }
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java)
        .configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
