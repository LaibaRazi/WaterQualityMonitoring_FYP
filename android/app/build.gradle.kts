plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // use the Kotlin plugin defined in settings.gradle.kts
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // version controlled in settings.gradle.kts
}

android {
    namespace = "com.example.waterqualitymonitoring"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.waterqualitymonitoring"
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        minSdk = 23
        targetSdk = 34
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
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation("com.google.firebase:firebase-analytics")

    // Add other Firebase products as needed
    // https://firebase.google.com/docs/android/setup#available-libraries
}
