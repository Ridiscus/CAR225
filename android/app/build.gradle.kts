// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.Robinson.car225"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // ✅ CORRECTION (Syntaxe Kotlin) : il faut "is..." et un "="
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.Robinson.car225"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ✅ CONSEILLÉ (Syntaxe Kotlin) : active le multidex avec un "="
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Note: Si "$kotlin_version" ne marche pas, remplace par ta version (ex: "1.9.0")
    // Mais l'important ici est l'utilisation des parenthèses ()

    // ✅ CORRECTION (Syntaxe Kotlin) : Parenthèses obligatoires
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}