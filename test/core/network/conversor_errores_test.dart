import 'package:creafacil_app/core/network/red.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException respuestaError(int estado, Object? cuerpo) {
  final opciones = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: estado,
    requestOptions: opciones,
    response: Response<dynamic>(
      requestOptions: opciones,
      statusCode: estado,
      data: cuerpo,
    ),
  );
}

Map<String, Object?> errorBackend(
  String codigo,
  String mensaje, [
  List<Object?>? detalles,
]) => {
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': ?detalles},
};

void main() {
  final opciones = RequestOptions(path: '/health');

  group('ConversorErrores.desdeDio sin respuesta', () {
    test('conexión rechazada → sinConexion con mensaje propio', () {
      final e = ConversorErrores.desdeDio(
        DioException.connectionError(
          requestOptions: opciones,
          reason: 'Connection refused',
        ),
      );
      expect(e.tipo, TipoErrorApi.sinConexion);
      expect(e.codigo, 'SIN_CONEXION');
      expect(e.mensaje, ConversorErrores.mensajeSinConexion);
      expect(e.estadoHttp, isNull);
      expect(e.detalles, isEmpty);
    });

    for (final tipo in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      test('$tipo → tiempoAgotado', () {
        final e = ConversorErrores.desdeDio(
          DioException(requestOptions: opciones, type: tipo),
        );
        expect(e.tipo, TipoErrorApi.tiempoAgotado);
        expect(e.codigo, 'TIEMPO_AGOTADO');
        expect(e.mensaje, ConversorErrores.mensajeTiempoAgotado);
      });
    }

    test('certificado inválido → sinConexion', () {
      final e = ConversorErrores.desdeDio(
        DioException(
          requestOptions: opciones,
          type: DioExceptionType.badCertificate,
        ),
      );
      expect(e.tipo, TipoErrorApi.sinConexion);
      expect(e.mensaje, ConversorErrores.mensajeCertificado);
    });

    test('cancelada → desconocido con mensaje de cancelación', () {
      final e = ConversorErrores.desdeDio(
        DioException(requestOptions: opciones, type: DioExceptionType.cancel),
      );
      expect(e.tipo, TipoErrorApi.desconocido);
      expect(e.mensaje, ConversorErrores.mensajeCancelado);
    });

    test('desconocido con SocketException → sinConexion', () {
      final e = ConversorErrores.desdeDio(
        DioException(
          requestOptions: opciones,
          error: 'SocketException: Failed host lookup',
        ),
      );
      expect(e.tipo, TipoErrorApi.sinConexion);
    });

    test('desconocido cualquiera → desconocido', () {
      final e = ConversorErrores.desdeDio(
        DioException(requestOptions: opciones, error: StateError('x')),
      );
      expect(e.tipo, TipoErrorApi.desconocido);
      expect(e.mensaje, ConversorErrores.mensajeDesconocido);
    });

    test('si Dio ya trae una ApiException, se devuelve tal cual', () {
      const original = ApiException(
        tipo: TipoErrorApi.noAutorizado,
        codigo: 'TOKEN_NO_DISPONIBLE',
        mensaje: 'm',
      );
      final e = ConversorErrores.desdeDio(
        DioException(requestOptions: opciones, error: original),
      );
      expect(identical(e, original), isTrue);
    });
  });

  group('ConversorErrores con respuesta del backend', () {
    final casos = <(int, String, TipoErrorApi)>[
      (400, 'JSON_INVALIDO', TipoErrorApi.validacion),
      (401, 'NO_AUTENTICADO', TipoErrorApi.noAutorizado),
      (401, 'NO_AUTORIZADO', TipoErrorApi.noAutorizado),
      (403, 'PROHIBIDO', TipoErrorApi.prohibido),
      (404, 'RUTA_NO_ENCONTRADA', TipoErrorApi.noEncontrado),
      (409, 'CONFLICTO', TipoErrorApi.desconocido),
      (413, 'CUERPO_DEMASIADO_GRANDE', TipoErrorApi.validacion),
      (500, 'ERROR_INTERNO', TipoErrorApi.servidor),
      (501, 'NO_IMPLEMENTADO', TipoErrorApi.servidor),
      (503, 'SERVICIO_NO_DISPONIBLE', TipoErrorApi.servidor),
      (504, 'PASARELA', TipoErrorApi.tiempoAgotado),
    ];
    for (final (estado, codigo, tipo) in casos) {
      test('$estado $codigo → $tipo con el mensaje del servidor', () {
        final e = ConversorErrores.desdeDio(
          respuestaError(estado, errorBackend(codigo, 'Mensaje de $codigo')),
        );
        expect(e.tipo, tipo);
        expect(e.codigo, codigo);
        expect(e.mensaje, 'Mensaje de $codigo');
        expect(e.estadoHttp, estado);
      });
    }

    test('VALIDACION 400 con detalles por campo', () {
      final e = ConversorErrores.desdeDio(
        respuestaError(
          400,
          errorBackend('VALIDACION', 'Los datos enviados no son válidos.', [
            {
              'campo': 'nombre',
              'ubicacion': 'body',
              'mensaje': 'El nombre es obligatorio.',
            },
            {
              'campo': 'items.0.cantidad',
              'ubicacion': 'body',
              'mensaje': 'Debe ser mayor que 0.',
            },
            {'mensaje': 'Error general.'},
            {'campo': 'sinMensaje'},
            'no es un objeto',
          ]),
        ),
      );
      expect(e.tipo, TipoErrorApi.validacion);
      expect(e.codigo, 'VALIDACION');
      expect(e.mensaje, 'Los datos enviados no son válidos.');
      expect(e.detalles, hasLength(3));
      expect(e.detalles.first.campo, 'nombre');
      expect(e.detalles.first.ubicacion, 'body');
      expect(e.detalles.first.mensaje, 'El nombre es obligatorio.');
      expect(e.detalles[2].campo, isNull);
      expect(e.erroresPorCampo, {
        'nombre': 'El nombre es obligatorio.',
        'items.0.cantidad': 'Debe ser mayor que 0.',
      });
    });

    test('sin cuerpo del backend se usa el mensaje y código propios', () {
      for (final (estado, tipo) in [
        (400, TipoErrorApi.validacion),
        (401, TipoErrorApi.noAutorizado),
        (403, TipoErrorApi.prohibido),
        (404, TipoErrorApi.noEncontrado),
        (500, TipoErrorApi.servidor),
        (418, TipoErrorApi.desconocido),
      ]) {
        final e = ConversorErrores.desdeDio(respuestaError(estado, '<html>'));
        expect(e.tipo, tipo, reason: '$estado');
        expect(e.mensaje, ConversorErrores.mensajePorTipo(tipo));
        expect(e.codigo, ConversorErrores.codigoPorTipo(tipo));
        expect(e.detalles, isEmpty);
      }
    });

    test('mensaje vacío del servidor → mensaje propio', () {
      final e = ConversorErrores.desdeRespuesta(
        403,
        errorBackend('PROHIBIDO', '   '),
      );
      expect(e.codigo, 'PROHIBIDO');
      expect(e.mensaje, ConversorErrores.mensajeProhibido);
    });

    test('todos los tipos tienen mensaje en español y código', () {
      for (final tipo in TipoErrorApi.values) {
        expect(ConversorErrores.mensajePorTipo(tipo), isNotEmpty);
        expect(ConversorErrores.codigoPorTipo(tipo), isNotEmpty);
      }
    });
  });
}
