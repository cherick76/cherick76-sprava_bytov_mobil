import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigning = mapOf(
    "keystore" to (System.getenv("CM_KEYSTORE") ?: System.getenv("CM_KEYSTORE_PATH")),
    "keystorePassword" to System.getenv("CM_KEYSTORE_PASSWORD"),
    "keyAlias" to System.getenv("CM_KEY_ALIAS"),
    "keyPassword" to System.getenv("CM_KEY_PASSWORD"),
)
val releaseSigningRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val missingReleaseSigningValues = releaseSigning
    .filterValues { it.isNullOrBlank() }
    .keys
    .toMutableSet()
if (
    releaseSigningRequested &&
    releaseSigning["keystore"]?.let { file(it).isFile } != true
) {
    missingReleaseSigningValues += "keystore file"
}

if (releaseSigningRequested && missingReleaseSigningValues.isNotEmpty()) {
    throw GradleException(
        "Release signing is not configured. Missing environment variables for: " +
            missingReleaseSigningValues.joinToString(),
    )
}

android {
    namespace = "sk.samospravabytov.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "sk.samospravabytov.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            releaseSigning["keystore"]?.let { storeFile = file(it) }
            releaseSigning["keystorePassword"]?.let { storePassword = it }
            releaseSigning["keyAlias"]?.let { keyAlias = it }
            releaseSigning["keyPassword"]?.let { keyPassword = it }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
