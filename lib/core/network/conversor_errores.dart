import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Traduce los errores de Dio y el formato de error del backend a
/// [ApiException] [RNF-02].
///
/// Formato del backend:
/// `{"error": {"codigo": "…", "mensaje": "…", "detalles": [ … ]}}`.
/// Los mensajes del servidor tienen prioridad; si no hay, se usa uno propio.
abstract final class ConversorErrores {
  static const mensajeSinConexion =
      'No pudimos conectar con el servidor de CreaFácil. Revisa tu conexión '
      'a internet o inténtalo de nuevo en unos minutos.';
  static const mensajeTiempoAgotado =
      'El servidor tardó demasiado en responder. Inténtalo de nuevo.';
  static const mensajeServidor =
      'El servidor tuvo un problema al atender la petición. Inténtalo más '
      'tarde.';
  static const mensajeNoAutorizado =
      'Tu sesión no es válida o ha caducado. Inicia sesión de nuevo.';
  static const mensajeProhibido =
      'No tienes permiso para realizar esta acción.';
  static const mensajeNoEncontrado = 'No encontramos lo que buscabas.';
  static const mensajeValidacion =
      'Hay datos que no son válidos. Revísalos e inténtalo de nuevo.';
  static const mensajeDesconocido =
      'Ocurrió un error inesperado. Inténtalo de nuevo.';
  static const mensajeCancelado = 'La petición se canceló.';
  static const mensajeCertificado =
      'No se pudo establecer una conexión segura con el servidor.';

  /// Convierte cualquier [DioException] en [ApiException].
  static ApiException desdeDio(DioException error) {
    final interno = error.error;
    if (interno is ApiException) {
      return interno;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return _sinRespuesta(TipoErrorApi.tiempoAgotado);
      case DioExceptionType.connectionError:
        return _sinRespuesta(TipoErrorApi.sinConexion);
      case DioExceptionType.badCertificate:
        return const ApiException(
          tipo: TipoErrorApi.sinConexion,
          codigo: 'CERTIFICADO_INVALIDO',
          mensaje: mensajeCertificado,
        );
      case DioExceptionType.cancel:
        return const ApiException(
          tipo: TipoErrorApi.desconocido,
          codigo: 'CANCELADO',
          mensaje: mensajeCancelado,
        );
      case DioExceptionType.badResponse:
        final respuesta = error.response;
        return desdeRespuesta(respuesta?.statusCode, respuesta?.data);
      case DioExceptionType.unknown:
        // Algunos fallos de red llegan sin tipo (p. ej. SocketException).
        final texto = '${error.error ?? ''} ${error.message ?? ''}';
        if (_pareceFalloDeRed(texto)) {
          return _sinRespuesta(TipoErrorApi.sinConexion);
        }
        return _sinRespuesta(TipoErrorApi.desconocido);
    }
  }

  /// Convierte una respuesta de error (código HTTP y cuerpo) en
  /// [ApiException], leyendo el formato de error del backend si existe.
  static ApiException desdeRespuesta(int? estadoHttp, Object? cuerpo) {
    final tipo = tipoPorEstado(estadoHttp);
    final error = cuerpo is Map ? cuerpo['error'] : null;

    String? codigoServidor;
    String? mensajeServidor;
    var detalles = const <DetalleErrorApi>[];
    if (error is Map) {
      final codigo = error['codigo'];
      final mensaje = error['mensaje'];
      final lista = error['detalles'];
      if (codigo is String && codigo.trim().isNotEmpty) {
        codigoServidor = codigo;
      }
      if (mensaje is String && mensaje.trim().isNotEmpty) {
        mensajeServidor = mensaje;
      }
      if (lista is List) {
        detalles = lista
            .map(DetalleErrorApi.desdeJson)
            .whereType<DetalleErrorApi>()
            .toList(growable: false);
      }
    }

    return ApiException(
      tipo: tipo,
      codigo: codigoServidor ?? codigoPorTipo(tipo),
      mensaje: mensajeServidor ?? mensajePorTipo(tipo),
      estadoHttp: estadoHttp,
      detalles: detalles,
    );
  }

  /// Tipo de error según el código HTTP.
  static TipoErrorApi tipoPorEstado(int? estadoHttp) {
    return switch (estadoHttp) {
      401 => TipoErrorApi.noAutorizado,
      403 => TipoErrorApi.prohibido,
      404 => TipoErrorApi.noEncontrado,
      400 || 413 || 422 => TipoErrorApi.validacion,
      408 || 504 => TipoErrorApi.tiempoAgotado,
      final int e when e >= 500 => TipoErrorApi.servidor,
      _ => TipoErrorApi.desconocido,
    };
  }

  /// Mensaje propio en español para cada tipo de error.
  static String mensajePorTipo(TipoErrorApi tipo) {
    return switch (tipo) {
      TipoErrorApi.sinConexion => mensajeSinConexion,
      TipoErrorApi.tiempoAgotado => mensajeTiempoAgotado,
      TipoErrorApi.servidor => mensajeServidor,
      TipoErrorApi.noAutorizado => mensajeNoAutorizado,
      TipoErrorApi.prohibido => mensajeProhibido,
      TipoErrorApi.noEncontrado => mensajeNoEncontrado,
      TipoErrorApi.validacion => mensajeValidacion,
      TipoErrorApi.desconocido => mensajeDesconocido,
    };
  }

  /// Código propio del cliente cuando el servidor no envía uno.
  static String codigoPorTipo(TipoErrorApi tipo) {
    return switch (tipo) {
      TipoErrorApi.sinConexion => 'SIN_CONEXION',
      TipoErrorApi.tiempoAgotado => 'TIEMPO_AGOTADO',
      TipoErrorApi.servidor => 'ERROR_SERVIDOR',
      TipoErrorApi.noAutorizado => 'NO_AUTORIZADO',
      TipoErrorApi.prohibido => 'PROHIBIDO',
      TipoErrorApi.noEncontrado => 'NO_ENCONTRADO',
      TipoErrorApi.validacion => 'VALIDACION',
      TipoErrorApi.desconocido => 'DESCONOCIDO',
    };
  }

  static ApiException _sinRespuesta(TipoErrorApi tipo) => ApiException(
    tipo: tipo,
    codigo: codigoPorTipo(tipo),
    mensaje: mensajePorTipo(tipo),
  );

  static bool _pareceFalloDeRed(String texto) {
    final t = texto.toLowerCase();
    return t.contains('socketexception') ||
        t.contains('failed host lookup') ||
        t.contains('connection refused') ||
        t.contains('network is unreachable') ||
        t.contains('xmlhttprequest');
  }
}
