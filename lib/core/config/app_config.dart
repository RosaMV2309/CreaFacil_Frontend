/// Configuración que se inyecta al compilar con `--dart-define`.
///
/// Ejemplo: `flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1`
abstract final class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
}
