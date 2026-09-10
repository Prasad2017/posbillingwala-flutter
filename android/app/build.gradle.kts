plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeyProperties = keystorePropertiesFile.exists()
if (hasKeyProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Prefer key.properties; fall back to -PRELEASE_* (same as WithTable / build-release.sh).
fun releaseProp(name: String, propertiesKey: String): String? {
    if (project.hasProperty(name)) {
        return project.property(name) as String
    }
    if (hasKeyProperties) {
        return keystoreProperties.getProperty(propertiesKey)
    }
    return null
}

val releaseStoreFilePath = releaseProp("RELEASE_STORE_FILE", "storeFile")
val releaseStorePassword = releaseProp("RELEASE_STORE_PASSWORD", "storePassword")
val releaseKeyAlias = releaseProp("RELEASE_KEY_ALIAS", "keyAlias")
val releaseKeyPassword = releaseProp("RELEASE_KEY_PASSWORD", "keyPassword")
val hasReleaseKeystore =
    !releaseStoreFilePath.isNullOrBlank() &&
        !releaseStorePassword.isNullOrBlank() &&
        !releaseKeyAlias.isNullOrBlank() &&
        !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "com.posbillingwala.pos_billingwala_v2"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Match WithTable Firebase Android app (google-services.json).
        applicationId = "com.pos_billingwala"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                // Paths in key.properties are relative to android/; -P paths match WithTable (from app/).
                val storePath = releaseStoreFilePath!!
                storeFile = if (project.hasProperty("RELEASE_STORE_FILE")) {
                    file(storePath)
                } else {
                    rootProject.file(storePath)
                }
                storePassword = releaseStorePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Local/dev fallback — add android/key.properties for Play upload.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
