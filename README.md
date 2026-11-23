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
| `MOSTRAR_HERRAMIENTAS_DEV` | `true` en debug (`flutter run`), `false` en release | Muestra el botón «Ver componentes» y la ruta `/dev/componentes` |

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
| APK de Android | Java 17 (Temurin) · `flutter build apk --debug` (con `API_URL=http://10.0.2.2:3000/api/v1`) · `flutter build apk --debug` para el teléfono por USB (con `API_URL=http://localhost:3000/api/v1`) · `flutter build apk --release` |

Artefactos de cada ejecución (pestaña **Actions** → la ejecución → **Artifacts**): `cobertura-lcov`,
`creafacil-web`, `creafacil-apk-debug` (emulador, `10.0.2.2`), `creafacil-apk-usb` (teléfono por cable,
`localhost` + `adb reverse`) y `creafacil-apk-release`. Se guardan 14 días.

El APK `creafacil-apk-usb` es el **APK de presentación**:

- Recibe el número de WhatsApp del negocio desde la **variable del repositorio** `WHATSAPP_NUMERO`
  (`--dart-define=WHATSAPP_NUMERO=${{ vars.WHATSAPP_NUMERO }}`). El número **no** está escrito en el código.
  Si la variable no existe o está vacía, el APK se compila igual y el botón de WhatsApp queda deshabilitado.
  El APK release también la recibe, porque es la configuración de producción.
- Se compila con `--dart-define=MOSTRAR_HERRAMIENTAS_DEV=false`: no muestra «Ver componentes» ni existe la ruta
  `/dev/componentes`. El APK del emulador (`creafacil-apk-debug`) y `flutter run` los siguen mostrando.

> El repositorio es público: cualquiera puede descargar los artefactos y el número queda dentro del APK.
> Es aceptable porque es el contacto público del negocio.

### Crear o cambiar el número de WhatsApp

Formato: código de país sin «+» ni espacios (por ejemplo, `5939XXXXXXXX`).

- **En la web:** repositorio → **Settings** → **Secrets and variables** → **Actions** → pestaña **Variables** →
  **New repository variable** (nombre `WHATSAPP_NUMERO`), o edita la existente con el lápiz.
- **Con GitHub CLI:**

  ```powershell
  gh variable set WHATSAPP_NUMERO -R RosaMV2309/CreaFacil_Frontend --body "<número>"
  ```

El cambio se aplica en la **siguiente ejecución** de la CI (un push, un PR o **Actions → CI → Run workflow**);
los APK ya descargados conservan el número anterior.

## Compilación

### Web

```sh
flutter build web --release --dart-define=API_URL=https://<api>/api/v1
```

### Android (APK)

- Identificador: `com.creafacil.creafacil_app` · Nombre visible: **CreaFácil** · `minSdk` 24 (Android 7.0) · `targetSdk` 36.
- Pantalla de carga (splash) nativa con `flutter_native_splash` (`flutter_native_splash.yaml`; regenerar con
  `dart run flutter_native_splash:create`): logotipo completo sobre crema `#FFF8F5` en Android ≤ 11 y en la web.
  **Android 12 o superior** recorta el icono del splash en un círculo, así que ahí se muestra la ilustración del
  icono de la app sobre rosa pastel `#F7B8CE`. Sin esperas: desaparece con el primer fotograma de Flutter.
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

## Instalar en mi teléfono (Android por cable USB) [RF-24]

Guía probada para un **Xiaomi Redmi Note 10S** (MIUI / HyperOS) con la **depuración USB activada y autorizada**.
Sirve para cualquier Android 7.0 o superior. Se usa el APK `creafacil-apk-usb` de la CI, que apunta a
`http://localhost:3000/api/v1`; con `adb reverse` ese `localhost` del teléfono es el backend de tu PC, por el cable.

> El APK es de **depuración**: no se publica en tiendas y solo sirve para pruebas y demostraciones.
> La versión firmada para entregar queda para la Fase 8.

Comandos para PowerShell (`adb` está en `%LOCALAPPDATA%\Android\Sdk\platform-tools`):

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
```

1. **Arranca el backend en el PC** (déjalo abierto en su ventana):

   ```powershell
   cd C:\Proyectos\CreaFacil\CreaFacil_Backend
   npm run dev          # escucha en http://localhost:3000
   ```

2. **Descarga el APK** de la última ejecución en verde de la CI (pestaña **Actions** → la ejecución →
   **Artifacts** → `creafacil-apk-usb`, y descomprime el zip en `apk\`), o con GitHub CLI:

   ```powershell
   cd C:\Proyectos\CreaFacil
   gh run list -R RosaMV2309/CreaFacil_Frontend -w CI -L 5          # copia el id de la ejecución
   gh run download <id> -R RosaMV2309/CreaFacil_Frontend -n creafacil-apk-usb -D apk
   ```

3. **Conecta el cable** (modo «Transferencia de archivos») y comprueba que el teléfono aparece como `device`:

   ```powershell
   & $adb devices
   ```

4. **Instala la app** (`-r` reinstala conservando los datos si ya estaba):

   ```powershell
   & $adb install -r apk\app-debug.apk       # debe terminar en «Success»
   ```

5. **Conecta el teléfono con la API del PC** (repítelo **cada vez** que desconectes el cable o reinicies `adb`):

   ```powershell
   & $adb reverse tcp:3000 tcp:3000
   ```

6. **Abre «CreaFácil»** en el teléfono (o `& $adb shell monkey -p com.creafacil.creafacil_app 1`). Verás la
   pantalla de carga con el logotipo y después el inicio con **«Conectado con la API»**.
   Las fotos del catálogo llegan como `http://localhost:3000/uploads/…`, así que también se cargan por el cable.
   En el inicio, el botón **WhatsApp** está activo y abre el chat del negocio (el número sale de la variable
   `WHATSAPP_NUMERO`; para cambiarlo, mira «Crear o cambiar el número de WhatsApp» en la sección de la CI).
   El botón «Ver componentes» **no** aparece: el APK de presentación tiene `MOSTRAR_HERRAMIENTAS_DEV=false`.

### Problemas frecuentes en Xiaomi

| Síntoma | Solución |
|---|---|
| `INSTALL_FAILED_USER_RESTRICTED` o «Instalación cancelada por el usuario» | Ajustes → Opciones de desarrollador → activa **«Instalar vía USB»** (MIUI pide iniciar sesión con la **cuenta Mi** y a veces tener una **SIM** insertada). También ayudan **«Depuración USB (ajustes de seguridad)»** y desactivar **«Optimización de MIUI»** (al final de la lista; reinicia el teléfono). Si durante la instalación aparece un aviso en el teléfono, pulsa **Instalar** antes de que pasen unos segundos. |
| `adb devices` muestra `unauthorized` | Desbloquea el teléfono y acepta «¿Permitir depuración USB?» (marca «Permitir siempre»). Si no aparece: Opciones de desarrollador → **Revocar autorizaciones de depuración USB**, desconecta y vuelve a conectar, o `& $adb kill-server; & $adb devices`. |
| `adb devices` sale vacío | Cambia el modo USB a «Transferencia de archivos», prueba otro cable o puerto (algunos cables solo cargan). |
| La app muestra **«Sin conexión con la API»** | Falta `adb reverse tcp:3000 tcp:3000` (se pierde al desconectar el cable) o el backend está apagado: comprueba que `npm run dev` sigue en marcha y vuelve a ejecutar el paso 5. Después pulsa reintentar o reabre la app. |

### Plan B: instalar copiando el APK

Si `adb install` sigue fallando:

1. Con el cable en modo **«Transferencia de archivos»**, copia `apk\app-debug.apk` a la carpeta `Download` del teléfono
   desde el Explorador de Windows.
2. En el teléfono, abre la app **«Archivos»** o **«Administrador de archivos»** y toca `app-debug.apk`.
3. Si lo pide, permite **«Instalar apps desconocidas»** para esa app y vuelve atrás.
4. Si aparece la protección de MIUI o **Google Play Protect**, elige **«Instalar de todas formas»**
   (es tu propio APK de depuración).
5. La app sigue necesitando el backend del PC: deja el cable conectado con la depuración USB activa y ejecuta
   igualmente `& $adb reverse tcp:3000 tcp:3000` (pasos 1 y 5).

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

## Acceso de clientes (Fase 1 · RF-01, RF-02, RNF-01)

La app permite **crear una cuenta, iniciar sesión y ver «Mi perfil»**. Código en
`lib/features/autenticacion/` (domain / data / presentation).

**Flujo**

1. Inicio (público): logo, estado de la API, WhatsApp y la tarjeta «Tu cuenta» con
   «Iniciar sesión» y «Crear cuenta». Con sesión muestra «Hola, `nombre`» y «Mi perfil».
2. `/registro`: nombre (2 a 120), correo, teléfono opcional (`+` opcional y de 7 a 15 dígitos;
   se aceptan espacios, guiones y paréntesis), contraseña de 8 a 72 caracteres y su confirmación
   (solo en la app; no se envía). Al registrarse, la sesión queda iniciada.
3. `/acceso`: correo y contraseña (con botón para mostrarla). No hay «¿Olvidaste tu contraseña?» en la v1.
4. `/perfil` (protegida): nombre, correo, teléfono y rol «Cliente», con «Editar perfil» y
   «Cerrar sesión» (pide confirmación).
5. `/perfil/editar` (protegida, subfase 1.3b · RF-01, RN-05): nombre y teléfono precargados con
   las mismas validaciones que el registro; el correo es de solo lectura («El correo no se puede
   cambiar»). «Borrar teléfono» vacía el campo y al guardar envía `telefono: null`.
   - Solo se envían los campos que cambiaron (`CambiosPerfil`); sin cambios, «Guardar cambios»
     queda deshabilitado y no se llama a la API. Enter en el teléfono guarda.
   - Los errores por campo del 400 aparecen en su campo; el resto, con `CfMessage`.
   - Tras el 200 se actualiza la sesión en memoria y en el almacenamiento seguro (el token no
     cambia), se vuelve a «Mi perfil» con el aviso «Tus datos se guardaron correctamente.» y el
     saludo «Hola, `nombre`» del inicio muestra el nombre nuevo.
   - Con cambios sin guardar, cualquier salida («Cancelar», volver del encabezado o «Atrás» de
     Android y del navegador) pide confirmación con `CfConfirmDialog` (`onExit` de la ruta y
     `ProteccionSalida`). Un 401 cierra la sesión sin preguntar.

API consumida: `POST /auth/registro`, `POST /auth/login`, `GET /auth/perfil` y `PATCH /auth/perfil`.

**Sesión y token**

- El token JWT, `expiraEn` y el usuario se guardan con `flutter_secure_storage`
  (Android Keystore; en web, cifrado con WebCrypto en el almacenamiento local) detrás de la
  abstracción `AlmacenSesion`, que las pruebas sustituyen por un almacén en memoria.
- `ProveedorTokenSesion` entrega el token al `ApiClient`. El JWT dura 8 horas y **no se renueva**.
- Al arrancar se restaura la sesión: si `expiraEn` ya pasó, se borra; si no, se valida con
  `GET /auth/perfil` y se borra si la API responde 401. Sin conexión se conserva y la API la
  verificará en la siguiente petición.
- Si caduca mientras se usa la app o la API responde **401 a una petición autenticada**
  (lo detecta `InterceptorToken`), se cierra la sesión, se vuelve a `/acceso` (recordando el destino)
  y se muestra «Tu sesión expiró, vuelve a iniciar sesión.».
- Cerrar sesión borra todo lo guardado.

**Errores**: los del servidor se muestran con `CfMessage` y con el mensaje de la API:
401 «Correo o contraseña incorrectos.», 403 cuenta desactivada, 409 «Ya existe una cuenta con ese
correo.» (con enlace para iniciar sesión), 429 demasiados intentos (con el tiempo de espera) y los
detalles por campo del 400 en su campo.

**Solo clientes**: la app móvil es para clientes. Si inicia sesión la administradora, la sesión
**no se guarda** y se muestra «Esta app es para clientes. Usa el panel administrativo.». Es una
comprobación de navegación: los permisos reales los verifica siempre el servidor (RNF-03, RN-05).

**Código compartido con CreaFacil_AdminWeb**: `lib/core/` y, en `features/autenticacion/`, el dominio,
los modelos, el repositorio, `AlmacenSesion`, el controlador de sesión, los providers y el
formulario de acceso son idénticos. Solo cambian `presentation/configuracion_acceso.dart` (rol
permitido, mensaje de rechazo y almacén), el almacén concreto y las pantallas.

## Identidad visual

Solo se usan los colores de la paleta oficial, definidos en `lib/core/theme/app_colors.dart`:
primario `#E95778`, secundario `#F7B8CE`, terciario `#E8B94F`, complementario `#244A68`,
fondo `#FFF8F5`, texto `#51434A`, blanco `#FFFFFF` y bordes `#EADCE1`.

## Ramas

- `main`: versiones estables.
- `develop`: integración. Todo cambio entra por Pull Request desde `feature/*`, `fix/*` o `refactor/*`.
