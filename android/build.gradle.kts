buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.1")
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🟢 1. ON PLACE LE CORRECTIF ICI D'ABORD (Avant l'évaluation)
subprojects {
    afterEvaluate {
        if (name == "blue_thermal_printer") {
            // Version ultra-sécurisée par réflexion pour éviter tout problème de type Kotlin
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                androidExt::class.java.getMethod("setNamespace", String::class.java)
                    .invoke(androidExt, "id.kakzaki.blue_thermal_printer")
            }
        }
    }
}

// 🛑 2. L'ÉVALUATION SE FAIT À LA FIN
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}