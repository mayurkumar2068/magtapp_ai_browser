buildscript {
    // SDE 2 Tip: Pinned version ensures plugins like speech_to_text compile correctly
    val kotlinVersion = "1.9.10"
    extra.set("kotlin_version", kotlinVersion)

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Ensure this matches your Flutter version's requirements
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// --- Your existing build directory logic ---
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // EXTRA FIX: Ensure all subprojects use the correct SDK
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.compileSdkVersion(34) // SDK 34 is required for modern plugins
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}