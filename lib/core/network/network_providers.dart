import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_client.dart';
import 'proveedor_token.dart';

/// URL base de la API (se puede sustituir en las pruebas).
final apiUrlProvider = Provider<String>((ref) => AppConfig.apiUrl);

/// Fuente del token JWT.
///
/// TODO(Fase 1, RF-01 y RF-02): sustituir por el proveedor de la sesión.
final proveedorTokenProvider = Provider<ProveedorToken>(
  (ref) => const ProveedorTokenSinSesion(),
);

/// Cliente HTTP único de la app.
final apiClientProvider = Provider<ApiClient>((ref) {
  final cliente = ApiClient(
    baseUrl: ref.watch(apiUrlProvider),
    proveedorToken: ref.watch(proveedorTokenProvider),
    tiempoConexion: AppConfig.tiempoConexion,
    tiempoRespuesta: AppConfig.tiempoRespuesta,
  );
  ref.onDispose(cliente.dio.close);
  return cliente;
});
