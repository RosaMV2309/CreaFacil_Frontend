import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/features/estado_api/data/estado_api_model.dart';
import 'package:creafacil_app/features/estado_api/data/estado_api_repository_impl.dart';
import 'package:creafacil_app/features/estado_api/domain/estado_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';

void main() {
  group('EstadoApiModel.fromJson', () {
    test('lee la respuesta real de /health (sin baseDatos)', () {
      final e = EstadoApiModel.fromJson(cuerpoHealth());
      expect(e.estado, EstadoServicio.ok);
      expect(e.servicio, 'CreaFácil API');
      expect(e.version, '0.1.0');
      expect(e.entorno, 'development');
      expect(e.marcaTiempo, DateTime.utc(2026, 11, 10, 12));
      expect(e.tiempoActividadSegundos, 42);
      expect(e.baseDatos, isNull);
      expect(e.baseDatosConProblemas, isFalse);
    });

    test('baseDatos "ok" y "error" (subfase 0.4)', () {
      final ok = EstadoApiModel.fromJson(cuerpoHealth(baseDatos: 'ok'));
      expect(ok.baseDatos, EstadoBaseDatos.ok);
      expect(ok.baseDatosConProblemas, isFalse);

      final mal = EstadoApiModel.fromJson(
        cuerpoHealth(estado: 'degradado', baseDatos: 'error'),
      );
      expect(mal.estado, EstadoServicio.degradado);
      expect(mal.baseDatos, EstadoBaseDatos.error);
      expect(mal.baseDatosConProblemas, isTrue);
    });

    test('tolera campos ausentes o de otro tipo', () {
      final e = EstadoApiModel.fromJson({
        'estado': 'ok',
        'tiempoActividadSegundos': 12.7,
        'marcaTiempo': 'no es fecha',
        'baseDatos': 'raro',
        'extra': true,
      });
      expect(e.servicio, 'CreaFácil API');
      expect(e.version, 'desconocida');
      expect(e.entorno, 'desconocido');
      expect(e.tiempoActividadSegundos, 12);
      expect(e.marcaTiempo, isNull);
      expect(e.baseDatos, isNull);
    });

    test('rechaza lo que no es una respuesta de health', () {
      expect(() => EstadoApiModel.fromJson('texto'), throwsFormatException);
      expect(() => EstadoApiModel.fromJson({'a': 1}), throwsFormatException);
    });
  });

  group('EstadoApiRepositoryImpl con Dio simulado', () {
    late AdaptadorHttpFalso adaptador;

    EstadoApiRepositoryImpl repositorio() {
      final dio = Dio()..httpClientAdapter = adaptador;
      return EstadoApiRepositoryImpl(
        ApiClient(
          baseUrl: 'http://localhost:3100/api/v1',
          proveedorToken: const ProveedorTokenSinSesion(),
          dio: dio,
        ),
      );
    }

    test('200 ok → conectado', () async {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(200, cuerpoHealth(baseDatos: 'ok')),
      );
      final e = await repositorio().consultar();

      expect(e.estado, EstadoServicio.ok);
      expect(e.baseDatos, EstadoBaseDatos.ok);
      final peticion = adaptador.peticiones.single;
      expect(peticion.method, 'GET');
      expect(peticion.uri.path, '/api/v1/health');
    });

    test('503 con cuerpo de health → degradado (no desconexión)', () async {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(
          503,
          cuerpoHealth(estado: 'degradado', baseDatos: 'error'),
        ),
      );
      final e = await repositorio().consultar();

      expect(e.estado, EstadoServicio.degradado);
      expect(e.baseDatosConProblemas, isTrue);
      expect(e.version, '0.1.0');
    });

    test('503 con formato de error → ApiException servidor', () {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(503, {
          'error': {'codigo': 'NO_DISPONIBLE', 'mensaje': 'En mantenimiento.'},
        }),
      );
      expect(
        repositorio().consultar(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.tipo, 'tipo', TipoErrorApi.servidor)
              .having((e) => e.mensaje, 'mensaje', 'En mantenimiento.'),
        ),
      );
    });

    test('500 → ApiException servidor', () {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(500, {
          'error': {'codigo': 'ERROR_INTERNO', 'mensaje': 'Falló.'},
        }),
      );
      expect(
        repositorio().consultar(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.codigo,
            'codigo',
            'ERROR_INTERNO',
          ),
        ),
      );
    });

    test('sin conexión → ApiException sinConexion', () {
      adaptador = AdaptadorHttpFalso(sinConexion);
      expect(
        repositorio().consultar(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.tipo, 'tipo', TipoErrorApi.sinConexion)
              .having(
                (e) => e.mensaje,
                'mensaje',
                ConversorErrores.mensajeSinConexion,
              ),
        ),
      );
    });

    test('200 con otro formato → ApiException RESPUESTA_INVALIDA', () {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(200, {'hola': 'mundo'}),
      );
      expect(
        repositorio().consultar(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.codigo,
            'codigo',
            'RESPUESTA_INVALIDA',
          ),
        ),
      );
    });
  });
}
