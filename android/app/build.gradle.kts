plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.hop_dong" // ✅ sửa nếu cần
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.hop_dong"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true // ✅ Bắt buộc dòng này
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    // 👇 Thêm đoạn này để ẩn cảnh báo về Java 8
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")}
    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
        }

    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.1.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.material:material:1.11.0")

}

