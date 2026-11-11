/// Configuración que se inyecta al compilar con `--dart-define`.
///
/// Ejemplo:
/// `flutter run -d chrome --dart-define=API_URL=http://localhost:3000/api/v1`
///
/// En el emulador de Android el PC se ve como `10.0.2.2`:
/// `--dart-define=API_URL=http://10.0.2.2:3000/api/v1`
abstract final class AppConfig {
  /// URL base de la API REST de CreaFácil, con la versión incluida.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Tiempo máximo para establecer la conexión con la API.
  static const Duration tiempoConexion = Duration(seconds: 10);

  /// Tiempo máximo de espera de la respuesta de la API.
  static const Duration tiempoRespuesta = Duration(seconds: 20);
}
