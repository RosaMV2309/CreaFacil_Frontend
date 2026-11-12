# CreaFacil_Frontend

[![CI](https://github.com/RosaMV2309/CreaFacil_Frontend/actions/workflows/ci.yml/badge.svg?branch=develop)](https://github.com/RosaMV2309/CreaFacil_Frontend/actions/workflows/ci.yml)

Aplicación móvil del cliente de **CreaFácil**: aplicación multiplataforma para la gestión de pedidos,
cotizaciones y planificación de trabajos personalizados (manualidades, decoraciones y murales).

- Tecnología: Flutter 3.47 / Dart 3.13 (Android y web; iOS posible)
- Estado: Riverpod · Navegación: go_router · HTTP: Dio · Sesión: flutter_secure_storage
- Especificación: DERCAS v1.0 (Rosa Virginia Moreira Vidal, Sexto B)

## Requisitos

- Flutter 3.47 (canal stable)
- Android SDK 36, NDK 28.2.13676358, CMake 3.22.1 y un emulador o teléfono Android
- Java 17 o superior (sirve el JBR de Android Studio)
- Google Chrome para la versión web
- La API de `CreaFacil_Backend` en ejecución

## Ejecutar

```sh
flutter pub get

# Navegador (la API solo admite CORS desde http://localhost:5000 y :5001)
flutter run -d web-server --web-port 5000 --dart-define=API_URL=http://localhost:3000/api/v1

# Emulador Android (el emulador ve el PC en 10.0.2.2)
flutter emulators --launch CreaFacil_Pixel
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3000/api/v1
```

| Variable (`--dart-define`) | Por defecto | Descripción |
|---|---|---|
| `API_URL` | `http://localhost:3000/api/v1` | Dirección de la API |
| `WHATSAPP_NUMERO` | vacío (botón deshabilitado) | Número del negocio, solo dígitos con el prefijo del país (`593…`) |

## Comandos

| Comando | Qué hace |
|---|---|
| `flutter analyze` | Análisis estático |
| `dart format lib test tool` | Formatea el código |
| `flutter test` | Pruebas |
| `flutter test --coverage` | Pruebas con informe de cobertura en `coverage/lcov.info` |
| `dart run tool/cobertura.dart` | Comprueba el umbral de cobertura (80 %) |
| `flutter build web --release` | Compila la versión web en `build/web` |
| `flutter build apk --debug` | Compila el APK de pruebas |
| `flutter build apk --release` | Compila el APK release |

## Pruebas y cobertura

```sh
flutter test --coverage
dart run tool/cobertura.dart            # falla (código 1) si la cobertura de lib/ es menor del 80 %
dart run tool/cobertura.dart --detalle  # además, la cobertura de cada archivo
```

- `tool/cobertura.dart` lee `coverage/lcov.info` sin dependencias externas (funciona igual en Windows y en la CI).
- Cuenta las líneas de `lib/` y solo excluye código generado (`*.g.dart`, `*.freezed.dart`, `generated/`…).
- Opciones: `--minimo=<porcentaje>` y `--lcov=<ruta>`.
- `coverage/` no se sube al repositorio.

## Integración continua (GitHub Actions)

`.github/workflows/ci.yml` se ejecuta en cada push a `develop` y `main` y en cada Pull Request:

| Job | Pasos |
|---|---|
| Análisis, pruebas y build web | `flutter pub get` · `dart format --set-exit-if-changed` · `flutter analyze` · `flutter test --coverage` · umbral del 80 % · paleta oficial (`git grep` de colores fuera de `app_colors.dart`) · `flutter build web --release` |
| APK de Android | Java 17 (Temurin) · `flutter build apk --debug` (con `API_URL=http://10.0.2.2:3000/api/v1`) · `flutter build apk --release` |

Artefactos de cada ejecución (pestaña **Actions** → la ejecución → **Artifacts**): `cobertura-lcov`,
`creafacil-web`, `creafacil-apk-debug` y `creafacil-apk-release`. Se guardan 14 días.

## Compilación

### Web

```sh
flutter build web --release --dart-define=API_URL=https://<api>/api/v1
```

### Android (APK)

- Identificador: `com.creafacil.creafacil_app` · Nombre visible: **CreaFácil** · `minSdk` 24 (Android 7.0) · `targetSdk` 36.
- La URL de la API y el WhatsApp se fijan **al compilar** con `--dart-define`:

```sh
# Emulador con el backend local
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:3000/api/v1 --dart-define=WHATSAPP_NUMERO=593000000000

# Producción (API publicada con HTTPS)
flutter build apk --release --dart-define=API_URL=https://<api>/api/v1 --dart-define=WHATSAPP_NUMERO=593000000000
```

| Variante | HTTP sin cifrar | Uso |
|---|---|---|
| `debug` | Solo hacia `10.0.2.2`, `localhost` y `127.0.0.1` (`src/debug/res/xml/network_security_config.xml`) | Pruebas con el backend local |
| `release` | No: exige HTTPS [RNF-02] | Entrega; se firma con la clave de depuración hasta tener una propia |

El APK queda en `build/app/outputs/flutter-apk/` (`app-debug.apk` o `app-release.apk`). Para instalarlo:
`flutter install` o `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

**Teléfono real.** Con el cable USB, `adb reverse tcp:3000 tcp:3000` hace que el teléfono vea la API del PC
en `http://localhost:3000/api/v1` (permitido en debug). Por Wi-Fi con la IP del PC (`http://192.168.x.x:3000`)
el APK debug **no** puede conectar: esa IP no está en `network_security_config.xml` y el backend tendría que
escuchar en `0.0.0.0`.

**Antivirus en Windows.** Si `flutter build apk` falla en `:jni:configureCMake…` con
«está siendo utilizado por otro proceso», el antivirus está bloqueando los archivos temporales de CMake.
El plugin `jni` escribe en `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\jni-*\android\.cxx`: añade
`%LOCALAPPDATA%\Pub` a las exclusiones del antivirus o usa una caché de Pub en una carpeta excluida
(`$env:PUB_CACHE="C:\Proyectos\CreaFacil\.trabajo\pub-cache"` antes de `flutter pub get` y `flutter build apk`).

## Estructura

```
lib/
├── main.dart
├── app.dart                    # MaterialApp.router, tema e idioma español
├── core/
│   ├── config/app_config.dart  # configuración por --dart-define
│   ├── router/app_router.dart  # rutas (go_router)
│   ├── theme/                  # paleta oficial (app_colors.dart) y tema
│   ├── network/                # cliente HTTP (subfase 0.8)
│   ├── design_system/          # componentes Cf* al estilo PrimeNG (subfase 0.7)
│   └── widgets/                # diseño adaptable
└── features/<funcionalidad>/
    ├── data/                   # modelos y repositorios que llaman a la API
    ├── domain/                 # entidades y contratos
    └── presentation/           # pantallas, widgets y providers
tool/
└── cobertura.dart              # umbral de cobertura (CI y local)
```

## Identidad visual

Solo se usan los colores de la paleta oficial, definidos en `lib/core/theme/app_colors.dart`:
primario `#E95778`, secundario `#F7B8CE`, terciario `#E8B94F`, complementario `#244A68`,
fondo `#FFF8F5`, texto `#51434A`, blanco `#FFFFFF` y bordes `#EADCE1`.

## Ramas

- `main`: versiones estables.
- `develop`: integración. Todo cambio entra por Pull Request desde `feature/*`, `fix/*` o `refactor/*`.
