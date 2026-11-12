import 'package:creafacil_app/core/network/red.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DetalleErrorApi', () {
    test('toString incluye el campo cuando lo hay', () {
      const conCampo = DetalleErrorApi(
        campo: 'correo',
        ubicacion: 'body',
        mensaje: 'El correo no es válido.',
      );
      const sinCampo = DetalleErrorApi(mensaje: 'Datos no válidos.');

      expect(conCampo.toString(), 'correo: El correo no es válido.');
      expect(sinCampo.toString(), 'Datos no válidos.');
    });

    test('desdeJson ignora lo que no es un mapa o no tiene mensaje', () {
      expect(DetalleErrorApi.desdeJson('texto'), isNull);
      expect(DetalleErrorApi.desdeJson({'campo': 'x'}), isNull);
      expect(DetalleErrorApi.desdeJson({'mensaje': '   '}), isNull);

      final d = DetalleErrorApi.desdeJson({
        'mensaje': 'Obligatorio',
        'campo': 1,
      });
      expect(d?.mensaje, 'Obligatorio');
      expect(d?.campo, isNull);
      expect(d?.ubicacion, isNull);
    });
  });

  group('ApiException', () {
    test('toString muestra el código, el estado HTTP y el mensaje', () {
      const conEstado = ApiException(
        tipo: TipoErrorApi.prohibido,
        codigo: 'PROHIBIDO',
        mensaje: 'No tienes permiso.',
        estadoHttp: 403,
      );
      const sinEstado = ApiException(
        tipo: TipoErrorApi.sinConexion,
        codigo: 'SIN_CONEXION',
        mensaje: 'Sin conexión.',
      );

      expect(
        conEstado.toString(),
        'ApiException(PROHIBIDO, 403): No tienes permiso.',
      );
      expect(
        sinEstado.toString(),
        'ApiException(SIN_CONEXION, sin estado): Sin conexión.',
      );
    });

    test('erroresPorCampo omite los detalles sin campo', () {
      const e = ApiException(
        tipo: TipoErrorApi.validacion,
        codigo: 'VALIDACION',
        mensaje: 'Revisa los datos.',
        estadoHttp: 400,
        detalles: [
          DetalleErrorApi(campo: 'nombre', mensaje: 'Obligatorio'),
          DetalleErrorApi(mensaje: 'General'),
        ],
      );

      expect(e.erroresPorCampo, {'nombre': 'Obligatorio'});
    });
  });
}
