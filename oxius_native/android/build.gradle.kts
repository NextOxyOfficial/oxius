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

// NOTE: Flutter 3.44 tooling defaults Kotlin to JVM target 21 while older
// plugins (flutter_facebook_auth etc.) still compile their Java at 1.8.
// Kotlin's per-task JVM-target validation is relaxed to "warning" in
// gradle.properties (kotlin.jvm.target.validation.mode) — the compatibility
// settings are finalized by the time the root project could rewrite them.

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
