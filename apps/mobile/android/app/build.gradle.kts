import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(::load)
    }
}

val isWindows = System.getProperty("os.name").contains("Windows", ignoreCase = true)
val flutterSdk = localProperties.getProperty("flutter.sdk") ?: System.getenv("FLUTTER_ROOT")
val flutterExecutable = when {
    !flutterSdk.isNullOrBlank() && isWindows -> "$flutterSdk\\bin\\flutter.bat"
    !flutterSdk.isNullOrBlank() -> "$flutterSdk/bin/flutter"
    isWindows -> "flutter.bat"
    else -> "flutter"
}
val flutterProjectDir = rootProject.projectDir.parentFile

val analyzeFlutterBeforeBuild = tasks.register<Exec>("analyzeFlutterBeforeBuild") {
    group = "verification"
    description = "Runs flutter analyze before Android builds."
    workingDir = flutterProjectDir
    commandLine(flutterExecutable, "analyze", "--no-fatal-infos", "--no-fatal-warnings")
}

tasks.named("preBuild") {
    dependsOn(analyzeFlutterBeforeBuild)
}

android {
    namespace = "com.example.recursor_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.recursor_mobile"
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
