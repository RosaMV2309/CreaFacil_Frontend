import 'package:dio/dio.dart';

import '../../../core/network/red.dart';
import '../domain/estado_api.dart';
import '../domain/estado_api_repository.dart';
import 'estado_api_model.dart';

/// Repositorio que consulta `GET /health` a través del [ApiClient].
class EstadoApiRepositoryImpl implements EstadoApiRepository {
  EstadoApiRepositoryImpl(this._api);

  static const ruta = '/health';

  final ApiClient _api;

  @override
  Future<EstadoApi> consultar() async {
    // El 503 se acepta aquí: con cuerpo de health significa «API disponible,
    // base de datos con problemas», no una desconexión total.
    final respuesta = await _api.get(
      ruta,
      opciones: Options(validateStatus: (s) => s == 200 || s == 503),
    );
    final cuerpo = respuesta.data;

    if (EstadoApiModel.esRespuestaDeSalud(cuerpo)) {
      return EstadoApiModel.fromJson(cuerpo);
    }
    if (respuesta.statusCode == 503) {
      throw ConversorErrores.desdeRespuesta(503, cuerpo);
    }
    throw ApiException(
      tipo: TipoErrorApi.desconocido,
      codigo: 'RESPUESTA_INVALIDA',
      mensaje: 'La API respondió con un formato inesperado.',
      estadoHttp: respuesta.statusCode,
    );
  }
}
