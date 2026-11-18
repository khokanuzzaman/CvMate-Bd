plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.khokan.careermatebd"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.khokan.careermatebd"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// A release build must never ship the canned mock AI: refuse to build it when
// the project's .env (bundled as an asset) has USE_MOCK_AI=true. A missing .env
// or key is fine. Debug and profile builds are not checked. The iOS twin is
// scripts/check_release_env.sh.
val checkReleaseEnv = tasks.register("checkReleaseEnv") {
    val envFile = rootProject.file("../.env")
    doLast {
        if (!envFile.isFile) return@doLast
        val keyLine = Regex("""^(export\s+)?USE_MOCK_AI\s*=(.*)$""")
        val value = envFile.readLines()
            .map { it.trim() }
            .filter { !it.startsWith("#") }
            .mapNotNull { keyLine.find(it)?.groupValues?.get(2) }
            .lastOrNull()
            ?.replace(Regex("""\s#.*$"""), "")
            ?.trim()
            ?.trim('"', '\'')
            ?.trim()
            ?.lowercase()
        if (value in setOf("true", "1", "yes")) {
            throw GradleException(
                "Release build refused: .env has USE_MOCK_AI=true. " +
                    "Set it to false or remove it.",
            )
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(checkReleaseEnv)
}
