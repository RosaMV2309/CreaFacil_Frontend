plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.creafacil.creafacil_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identificador único de CreaFácil en Android (no cambiarlo: Android lo
        // usa para distinguir la app y sus actualizaciones).
        applicationId = "com.creafacil.creafacil_app"
        // minSdk 24 (Android 7.0) y targetSdk 36, los valores por defecto de Flutter 3.47.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // versionCode y versionName salen de `version:` en pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // El nombre visible («CreaFácil») está en src/main/AndroidManifest.xml.
        // La URL de la API y el WhatsApp se pasan al compilar, por ejemplo:
        //   flutter build apk --release --dart-define=API_URL=https://... --dart-define=WHATSAPP_NUMERO=593...
    }

    buildTypes {
        release {
            // Todavía no hay una clave de firma propia: el APK release se firma con la
            // clave de depuración para poder instalarlo en pruebas. Antes de publicar en
            // una tienda hay que crear un keystore propio y configurarlo aquí.
            signingConfig = signingConfigs.getByName("debug")
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
