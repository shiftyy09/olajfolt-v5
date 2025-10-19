plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.car_maintenance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ================= JAVÍTÁS 1. RÉSZ =================
        // Desugaring bekapcsolása
        isCoreLibraryDesugaringEnabled = true
        // ====================================================

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.car_maintenance_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // ================= JAVÍTÁS 2. RÉSZ =================
        // MultiDex bekapcsolása (fontos a desugaring-hoz)
        multiDexEnabled = true
        // ====================================================
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

// ================= JAVÍTÁS 3. RÉSZ =================
// A hiányzó `dependencies` blokk hozzáadása a desugaring könyvtárral
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
// ====================================================

