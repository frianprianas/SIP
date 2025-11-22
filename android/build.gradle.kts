buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1") // Sesuaikan versi Gradle Anda
        // Tidak perlu menambahkan classpath 'com.google.gms:google-services' di sini untuk Kotlin DSL
    }
}

plugins {
    id("com.android.application") version "8.7.0" apply false // Contoh, versi mungkin beda
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false // Keep original Kotlin version
    // Temporarily disabled google-services plugin
    // id("com.google.gms.google-services") version "4.4.1"  // <--- TAMBAHKAN BARIS INI (TANPA apply false)
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
