plugins {
  id("com.android.application")
  id("org.jetbrains.kotlin.android")
}

android {
  namespace = "org.x07.deviceapp"
  compileSdk = 34

  defaultConfig {
    applicationId = "io.x07.crewops.android.dev"
    minSdk = 24
    targetSdk = 34
    versionCode = 1
    versionName = "0.6.0"
  }

  buildTypes {
    release {
      isMinifyEnabled = false
    }
  }

  compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
  }
  kotlinOptions {
    jvmTarget = "17"
  }
}

dependencies {
  implementation("androidx.appcompat:appcompat:1.6.1")
  implementation("androidx.webkit:webkit:1.9.0")
}

