import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'conversor_errores.dart';
import 'proveedor_token.dart';

/// Cliente HTTP de CreaFácil sobre Dio [RNF-02][RNF-04].
///
/// - Todas las peticiones van a la API REST (nunca a la base de datos).
/// - Envía `Accept: application/json` y, si hay sesión, el token JWT.
/// - Cualquier fallo se lanza como [ApiException] con un mensaje en español.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required ProveedorToken proveedorToken,
    Duration tiempoConexion = const Duration(seconds: 10),
    Duration tiempoRespuesta = const Duration(seconds: 20),
    Dio? dio,
  }) : dio = dio ?? Dio() {
    this.dio.options
      ..baseUrl = baseUrl
      ..connectTimeout = tiempoConexion
      ..receiveTimeout = tiempoRespuesta
      ..responseType = ResponseType.json
      ..headers[Headers.acceptHeader] = Headers.jsonContentType;
    this.dio.interceptors.add(InterceptorToken(proveedorToken));
  }

  /// Instancia de Dio configurada. Se expone para casos especiales y pruebas.
  final Dio dio;

  Future<Response<dynamic>> get(
    String ruta, {
    Map<String, dynamic>? consulta,
    Options? opciones,
  }) => _ejecutar(
    () => dio.get<dynamic>(ruta, queryParameters: consulta, options: opciones),
  );

  Future<Response<dynamic>> post(
    String ruta, {
    Object? datos,
    Map<String, dynamic>? consulta,
    Options? opciones,
  }) => _ejecutar(
    () => dio.post<dynamic>(
      ruta,
      data: datos,
      queryParameters: consulta,
      options: opciones,
    ),
  );

  Future<Response<dynamic>> put(
    String ruta, {
    Object? datos,
    Map<String, dynamic>? consulta,
    Options? opciones,
  }) => _ejecutar(
    () => dio.put<dynamic>(
      ruta,
      data: datos,
      queryParameters: consulta,
      options: opciones,
    ),
  );

  Future<Response<dynamic>> patch(
    String ruta, {
    Object? datos,
    Map<String, dynamic>? consulta,
    Options? opciones,
  }) => _ejecutar(
    () => dio.patch<dynamic>(
      ruta,
      data: datos,
      queryParameters: consulta,
      options: opciones,
    ),
  );

  Future<Response<dynamic>> delete(
    String ruta, {
    Object? datos,
    Map<String, dynamic>? consulta,
    Options? opciones,
  }) => _ejecutar(
    () => dio.delete<dynamic>(
      ruta,
      data: datos,
      queryParameters: consulta,
      options: opciones,
    ),
  );

  Future<Response<dynamic>> _ejecutar(
    Future<Response<dynamic>> Function() peticion,
  ) async {
    try {
      return await peticion();
    } on DioException catch (error) {
      throw ConversorErrores.desdeDio(error);
    }
  }
}

/// Añade `Authorization: Bearer <token>` cuando hay sesión.
///
/// En la Fase 0 el [ProveedorToken] devuelve `null` y no se añade nada.
class InterceptorToken extends Interceptor {
  InterceptorToken(this._proveedor);

  final ProveedorToken _proveedor;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _proveedor.obtenerToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } on Object catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: const ApiException(
            tipo: TipoErrorApi.noAutorizado,
            codigo: 'TOKEN_NO_DISPONIBLE',
            mensaje: ConversorErrores.mensajeNoAutorizado,
          ),
          message: '$error',
        ),
      );
    }
  }
}
