import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:creafacil_app/features/estado_api/domain/estado_api.dart';
import 'package:creafacil_app/features/estado_api/domain/estado_api_repository.dart';
import 'package:creafacil_app/features/estado_api/presentation/estado_api_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/misc.dart';

/// Adaptador HTTP falso para Dio: registra las peticiones y responde con
/// [responder] sin tocar la red.
class AdaptadorHttpFalso implements HttpClientAdapter {
  AdaptadorHttpFalso(this.responder);

  final Future<ResponseBody> Function(RequestOptions opciones) responder;
  final peticiones = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    peticiones.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Respuesta JSON con el código [estado].
ResponseBody respuestaJson(int estado, Object cuerpo) {
  return ResponseBody.fromString(
    jsonEncode(cuerpo),
    estado,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Simula que la API está apagada (conexión rechazada).
Future<ResponseBody> sinConexion(RequestOptions opciones) {
  throw DioException.connectionError(
    requestOptions: opciones,
    reason: 'Connection refused',
  );
}

/// Cuerpo real de `GET /health` del backend (subfase 0.3).
Map<String, Object?> cuerpoHealth({String estado = 'ok', String? baseDatos}) =>
    {
      'estado': estado,
      'servicio': 'CreaFácil API',
      'version': '0.1.0',
      'entorno': 'development',
      'marcaTiempo': '2026-11-10T12:00:00.000Z',
      'tiempoActividadSegundos': 42,
      'baseDatos': ?baseDatos,
    };

const estadoConectado = EstadoApi(
  estado: EstadoServicio.ok,
  servicio: 'CreaFácil API',
  version: '0.1.0',
  entorno: 'development',
);

const estadoDegradado = EstadoApi(
  estado: EstadoServicio.degradado,
  servicio: 'CreaFácil API',
  version: '0.1.0',
  entorno: 'development',
  baseDatos: EstadoBaseDatos.error,
);

/// Repositorio falso del estado de la API para las pruebas de widgets.
class RepositorioEstadoApiFalso implements EstadoApiRepository {
  RepositorioEstadoApiFalso(this.respuesta);

  /// Se puede cambiar entre llamadas (por ejemplo, para probar «Reintentar»).
  Future<EstadoApi> Function() respuesta;
  int llamadas = 0;

  @override
  Future<EstadoApi> consultar() {
    llamadas++;
    return respuesta();
  }
}

/// Overrides para montar la app con la API «conectada» sin red.
List<Override> apiConectada() => [
  estadoApiRepositoryProvider.overrideWithValue(
    RepositorioEstadoApiFalso(() async => estadoConectado),
  ),
];
