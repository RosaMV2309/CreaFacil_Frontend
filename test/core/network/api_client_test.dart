import 'package:creafacil_app/core/network/red.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';

class _TokenFijo implements ProveedorToken {
  _TokenFijo(this.token);
  final String? token;
  int rechazos = 0;
  @override
  Future<String?> obtenerToken() async => token;
  @override
  void tokenRechazado() => rechazos++;
}

class _TokenQueFalla implements ProveedorToken {
  @override
  Future<String?> obtenerToken() => Future.error(StateError('almacén'));
  @override
  void tokenRechazado() {}
}

void main() {
  late AdaptadorHttpFalso adaptador;

  ApiClient cliente({ProveedorToken token = const ProveedorTokenSinSesion()}) {
    final dio = Dio()..httpClientAdapter = adaptador;
    return ApiClient(
      baseUrl: 'http://localhost:3100/api/v1',
      proveedorToken: token,
      tiempoConexion: const Duration(seconds: 3),
      tiempoRespuesta: const Duration(seconds: 4),
      dio: dio,
    );
  }

  setUp(() {
    adaptador = AdaptadorHttpFalso(
      (o) async => respuestaJson(200, {'ok': true}),
    );
  });

  test('configura baseUrl, tiempos y Accept JSON', () async {
    final api = cliente();
    final r = await api.get('/health');

    expect(r.data, {'ok': true});
    final peticion = adaptador.peticiones.single;
    expect(peticion.uri.toString(), 'http://localhost:3100/api/v1/health');
    expect(peticion.headers['Accept'], 'application/json');
    expect(peticion.connectTimeout, const Duration(seconds: 3));
    expect(peticion.receiveTimeout, const Duration(seconds: 4));
  });

  test('sin sesión no envía la cabecera Authorization', () async {
    await cliente().get('/health');
    expect(
      adaptador.peticiones.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('con token envía Authorization: Bearer', () async {
    await cliente(token: _TokenFijo('abc.def.ghi')).post('/x');
    expect(
      adaptador.peticiones.single.headers['Authorization'],
      'Bearer abc.def.ghi',
    );
  });

  group('401 en una petición autenticada [RF-01]', () {
    Map<String, Object> cuerpo401(String codigo) => {
      'error': {'codigo': codigo, 'mensaje': 'Tu sesión ha expirado.'},
    };

    test('con token: avisa al proveedor y lanza noAutorizado', () async {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(401, cuerpo401('TOKEN_EXPIRADO')),
      );
      final token = _TokenFijo('abc');
      await expectLater(
        cliente(token: token).get('/auth/perfil'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.codigo,
            'codigo',
            'TOKEN_EXPIRADO',
          ),
        ),
      );
      expect(token.rechazos, 1);
    });

    test('sin token (p. ej. login fallido): no avisa', () async {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(401, cuerpo401('CREDENCIALES_INVALIDAS')),
      );
      final token = _TokenFijo(null);
      await expectLater(
        cliente(token: token).post('/auth/login'),
        throwsA(isA<ApiException>()),
      );
      expect(token.rechazos, 0);
    });

    test('otros errores con token (403) no avisan', () async {
      adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(403, {
          'error': {'codigo': 'PROHIBIDO', 'mensaje': 'No'},
        }),
      );
      final token = _TokenFijo('abc');
      await expectLater(
        cliente(token: token).get('/admin'),
        throwsA(isA<ApiException>()),
      );
      expect(token.rechazos, 0);
    });

    test('ProveedorTokenSinSesion.tokenRechazado no hace nada', () async {
      const ProveedorTokenSinSesion().tokenRechazado();
      expect(await const ProveedorTokenSinSesion().obtenerToken(), isNull);
    });
  });

  test('si el proveedor de token falla, lanza ApiException noAutorizado', () {
    expect(
      cliente(token: _TokenQueFalla()).get('/x'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.tipo, 'tipo', TipoErrorApi.noAutorizado)
            .having((e) => e.codigo, 'codigo', 'TOKEN_NO_DISPONIBLE'),
      ),
    );
  });

  test('los errores del backend llegan como ApiException', () async {
    adaptador = AdaptadorHttpFalso(
      (o) async => respuestaJson(404, {
        'error': {
          'codigo': 'RUTA_NO_ENCONTRADA',
          'mensaje': 'No existe la ruta GET /api/v1/nada',
        },
      }),
    );
    for (final llamada in <Future<Object?> Function(ApiClient)>[
      (a) => a.get('/nada'),
      (a) => a.post('/nada', datos: {'a': 1}),
      (a) => a.put('/nada'),
      (a) => a.patch('/nada'),
      (a) => a.delete('/nada'),
    ]) {
      await expectLater(
        llamada(cliente()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.tipo, 'tipo', TipoErrorApi.noEncontrado)
              .having((e) => e.estadoHttp, 'estado', 404)
              .having(
                (e) => e.mensaje,
                'mensaje',
                'No existe la ruta GET /api/v1/nada',
              ),
        ),
      );
    }
    expect(adaptador.peticiones.map((p) => p.method), [
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
    ]);
  });

  test('API apagada → ApiException sinConexion', () {
    adaptador = AdaptadorHttpFalso(sinConexion);
    expect(
      cliente().get('/health'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.tipo,
          'tipo',
          TipoErrorApi.sinConexion,
        ),
      ),
    );
  });

  test('apiClientProvider usa la URL y el proveedor de token', () {
    final contenedor = ProviderContainer(
      overrides: [apiUrlProvider.overrideWithValue('http://api.prueba/api/v1')],
    );
    addTearDown(contenedor.dispose);

    final api = contenedor.read(apiClientProvider);
    expect(api.dio.options.baseUrl, 'http://api.prueba/api/v1');
    expect(api.dio.interceptors.whereType<InterceptorToken>(), hasLength(1));
    expect(
      contenedor.read(proveedorTokenProvider),
      isA<ProveedorTokenSinSesion>(),
    );
  });
}
