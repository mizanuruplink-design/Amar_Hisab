plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // ১. ফায়ারবেস প্লাগইনটি এখানে অবশ্যই যোগ করতে হবে
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.amar_hisab"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ২. কোর লাইব্রেরি ডি-সুগারিং এনাবল করুন (নোটিফিকেশনের জন্য)
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.amar_hisab"

        // ৩. রিমাইন্ডার ফিচারের জন্য minSdk কমপক্ষে ২১ বা তার বেশি হতে হবে
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // ৪. ডি-সুগারিং লাইব্রেরিটি এখানে যোগ করা হয়েছে
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
