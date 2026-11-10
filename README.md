# CreaFacil_Frontend

Aplicación móvil del cliente de **CreaFácil**: aplicación multiplataforma para la gestión de pedidos,
cotizaciones y planificación de trabajos personalizados (manualidades, decoraciones y murales).

- Tecnología: Flutter 3.47 / Dart 3.13 (Android y web; iOS posible)
- Estado: Riverpod · Navegación: go_router · HTTP: Dio · Sesión: flutter_secure_storage
- Especificación: DERCAS v1.0 (Rosa Virginia Moreira Vidal, Sexto B)

## Requisitos

- Flutter 3.47 (canal stable)
- Android SDK 36 y un emulador o teléfono Android
- Google Chrome para la versión web
- La API de `CreaFacil_Backend` en ejecución

## Ejecutar

```sh
flutter pub get

# Navegador
flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1

# Emulador Android (el emulador ve el PC en 10.0.2.2)
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3000/api/v1
```

| Variable (`--dart-define`) | Por defecto | Descripción |
|---|---|---|
| `API_URL` | `http://localhost:3000/api/v1` | Dirección de la API |

## Comandos

| Comando | Qué hace |
|---|---|
| `flutter analyze` | Análisis estático |
| `dart format lib test` | Formatea el código |
| `flutter test` | Pruebas |
| `flutter build web` | Compila la versión web en `build/web` |
| `flutter build apk --debug` | Compila el APK de Android |

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
```

## Identidad visual

Solo se usan los colores de la paleta oficial, definidos en `lib/core/theme/app_colors.dart`:
primario `#E95778`, secundario `#F7B8CE`, terciario `#E8B94F`, complementario `#244A68`,
fondo `#FFF8F5`, texto `#51434A`, blanco `#FFFFFF` y bordes `#EADCE1`.

## Ramas

- `main`: versiones estables.
- `develop`: integración. Todo cambio entra por Pull Request desde `feature/*`, `fix/*` o `refactor/*`.
