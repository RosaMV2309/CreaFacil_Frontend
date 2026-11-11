import 'estado_api.dart';

/// Contrato para consultar el estado de la API.
abstract interface class EstadoApiRepository {
  /// Consulta `GET /health`.
  ///
  /// Lanza `ApiException` si no hay conexión o la respuesta no es válida.
  Future<EstadoApi> consultar();
}
