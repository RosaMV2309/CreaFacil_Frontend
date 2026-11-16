import 'dart:convert';

import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/features/autenticacion/data/almacen_sesion.dart';
import 'package:creafacil_app/features/autenticacion/data/almacen_sesion_seguro.dart';
import 'package:creafacil_app/features/autenticacion/data/autenticacion_repository_impl.dart';
import 'package:creafacil_app/features/autenticacion/data/sesion_model.dart';
import 'package:creafacil_app/features/autenticacion/domain/autenticacion_repository.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/presentation/configuracion_acceso.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/sesion_falsa.dart';

Map<String, Object> _error(
  String codigo,
  String mensaje, [
  List<Map<String, String>>? detalles,
]) => {
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': ?detalles},
};

void main() {
  group('SesionModel', () {
    test('lee la respuesta real de la API', () {
      final sesion = SesionModel.desdeJson(cuerpoSesion());
      expect(sesion.token, startsWith('eyJ'));
      expect(sesion.expiraEn, DateTime.utc(2026, 11, 14, 20));
      expect(sesion.expiraEn.isUtc, isTrue);
      expect(sesion.usuario, clientePrueba);
    });

    test('ida y vuelta para guardarla', () {
      final sesion = sesionPrueba(usuario: adminPrueba);
      final json = jsonDecode(jsonEncode(SesionModel.aJson(sesion)));
      expect(SesionModel.desdeJson(json), sesion);
      final usuario = (json as Map<String, dynamic>)['usuario'] as Map;
      expect(usuario['telefono'], isNull);
    });

    test('teléfono vacío se lee como null', () {
      final json = cuerpoSesion();
      (json['usuario']! as Map)['telefono'] = '';
      expect(SesionModel.desdeJson(json).usuario.telefono, isNull);
    });

    for (final (caso, json) in <(String, Object?)>[
      ('no es un objeto', 'texto'),
      ('sin token', {...cuerpoSesion(), 'token': ''}),
      ('fecha inválida', {...cuerpoSesion(), 'expiraEn': 'mañana'}),
      ('sin usuario', {...cuerpoSesion(), 'usuario': null}),
      (
        'usuario incompleto',
        {
          ...cuerpoSesion(),
          'usuario': {'id': 'x', 'rol': 'CLIENTE'},
        },
      ),
      (
        'rol desconocido',
        {
          ...cuerpoSesion(),
          'usuario': {...cuerpoUsuario(clientePrueba), 'rol': 'OTRO'},
        },
      ),
    ]) {
      test('rechaza datos inválidos: $caso', () {
        expect(() => SesionModel.desdeJson(json), throwsFormatException);
      });
    }
  });

  group('AutenticacionRepositoryImpl (Dio simulado)', () {
    late AdaptadorHttpFalso adaptador;

    AutenticacionRepositoryImpl repositorio() => AutenticacionRepositoryImpl(
      ApiClient(
        baseUrl: 'http://localhost:3100/api/v1',
        proveedorToken: const ProveedorTokenSinSesion(),
        dio: Dio()..httpClientAdapter = adaptador,
      ),
    );

    void responder(int estado, Object cuerpo) => adaptador = AdaptadorHttpFalso(
      (o) async => respuestaJson(estado, cuerpo),
    );

    Map<String, dynamic> cuerpoEnviado() =>
        adaptador.peticiones.single.data as Map<String, dynamic>;

    Matcher errorCon(int estado, String codigo, TipoErrorApi tipo) => throwsA(
      isA<ApiException>()
          .having((e) => e.estadoHttp, 'estado', estado)
          .having((e) => e.codigo, 'codigo', codigo)
          .having((e) => e.tipo, 'tipo', tipo),
    );

    const datos = DatosRegistro(
      nombre: ' Ana Pérez ',
      email: ' ana@app.creafacil.test ',
      password: 'secreta123',
      telefono: '+593 99 123-4567',
    );

    test(
      'registro 201: envía el cuerpo del contrato y devuelve la sesión',
      () async {
        responder(201, cuerpoSesion());
        final sesion = await repositorio().registrar(datos);

        final peticion = adaptador.peticiones.single;
        expect(peticion.method, 'POST');
        expect(peticion.path, endsWith('/auth/registro'));
        expect(cuerpoEnviado(), {
          'nombre': 'Ana Pérez',
          'email': 'ana@app.creafacil.test',
          'password': 'secreta123',
          'telefono': '+593991234567',
        });
        expect(cuerpoEnviado().containsKey('rol'), isFalse);
        expect(sesion.usuario.rol, RolUsuario.cliente);
      },
    );

    test('registro sin teléfono: no envía el campo', () async {
      responder(201, cuerpoSesion());
      await repositorio().registrar(
        const DatosRegistro(
          nombre: 'Ana',
          email: 'a@b.co',
          password: 'secreta123',
          telefono: '  ',
        ),
      );
      expect(cuerpoEnviado().containsKey('telefono'), isFalse);
    });

    test('login 200', () async {
      responder(200, cuerpoSesion(usuario: adminPrueba));
      final sesion = await repositorio().iniciarSesion(
        email: ' admin@creafacil.test',
        password: 'x',
      );
      expect(adaptador.peticiones.single.path, endsWith('/auth/login'));
      expect(cuerpoEnviado(), {
        'email': 'admin@creafacil.test',
        'password': 'x',
      });
      expect(sesion.usuario.esAdmin, isTrue);
    });

    test('perfil 200 con el token indicado', () async {
      responder(200, {'usuario': cuerpoUsuario(clientePrueba)});
      final usuario = await repositorio().obtenerPerfil('tok.en');
      final peticion = adaptador.peticiones.single;
      expect(peticion.method, 'GET');
      expect(peticion.path, endsWith('/auth/perfil'));
      expect(peticion.headers['Authorization'], 'Bearer tok.en');
      expect(usuario, clientePrueba);
    });

    test('perfil con forma inesperada → RESPUESTA_INVALIDA', () {
      responder(200, {'otra': 1});
      expect(
        repositorio().obtenerPerfil('t'),
        throwsA(same(AutenticacionRepositoryImpl.respuestaInvalida)),
      );
    });

    test('login con forma inesperada → RESPUESTA_INVALIDA', () {
      responder(200, {'token': 'x'});
      expect(
        repositorio().iniciarSesion(email: 'a@b.co', password: 'x'),
        throwsA(same(AutenticacionRepositoryImpl.respuestaInvalida)),
      );
    });

    test('400 VALIDACION con detalles por campo', () async {
      responder(
        400,
        _error('VALIDACION', 'Hay datos que no son válidos.', [
          {
            'campo': 'email',
            'ubicacion': 'body',
            'mensaje': 'El correo electrónico no es válido',
          },
        ]),
      );
      try {
        await repositorio().registrar(datos);
        fail('debía lanzar');
      } on ApiException catch (e) {
        expect(e.tipo, TipoErrorApi.validacion);
        expect(e.erroresPorCampo, {
          'email': 'El correo electrónico no es válido',
        });
      }
    });

    test('401 CREDENCIALES_INVALIDAS', () {
      responder(
        401,
        _error('CREDENCIALES_INVALIDAS', 'Correo o contraseña incorrectos.'),
      );
      expect(
        repositorio().iniciarSesion(email: 'a@b.co', password: 'x'),
        errorCon(401, 'CREDENCIALES_INVALIDAS', TipoErrorApi.noAutorizado),
      );
    });

    test('403 CUENTA_DESACTIVADA', () {
      responder(
        403,
        _error('CUENTA_DESACTIVADA', 'Tu cuenta está desactivada.'),
      );
      expect(
        repositorio().iniciarSesion(email: 'a@b.co', password: 'x'),
        errorCon(403, 'CUENTA_DESACTIVADA', TipoErrorApi.prohibido),
      );
    });

    test('409 CONFLICTO', () {
      responder(
        409,
        _error('CONFLICTO', 'Ya existe una cuenta con ese correo.'),
      );
      expect(
        repositorio().registrar(datos),
        errorCon(409, 'CONFLICTO', TipoErrorApi.desconocido),
      );
    });

    test('429 DEMASIADOS_INTENTOS con su mensaje', () async {
      responder(
        429,
        _error(
          'DEMASIADOS_INTENTOS',
          'Demasiados intentos de inicio de sesión. Inténtalo de nuevo en 15 minutos.',
        ),
      );
      await expectLater(
        repositorio().iniciarSesion(email: 'a@b.co', password: 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.codigo, 'codigo', 'DEMASIADOS_INTENTOS')
              .having((e) => e.mensaje, 'mensaje', contains('15 minutos')),
        ),
      );
    });
  });

  group('AlmacenSesionSeguro (flutter_secure_storage simulado)', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('guarda, lee y borra la sesión', () async {
      final almacen = AlmacenSesionSeguro();
      expect(await almacen.leer(), isNull);

      await almacen.guardar(sesionPrueba());
      expect(await almacen.leer(), sesionPrueba());
      expect(
        await const FlutterSecureStorage().read(key: AlmacenSesionTexto.clave),
        contains('"rol":"CLIENTE"'),
      );

      await almacen.borrar();
      expect(await almacen.leer(), isNull);
    });

    test('datos dañados: se descartan y se borran', () async {
      FlutterSecureStorage.setMockInitialValues({
        AlmacenSesionTexto.clave: '{"token":',
      });
      final almacen = AlmacenSesionSeguro(const FlutterSecureStorage());
      expect(await almacen.leer(), isNull);
      expect(
        await const FlutterSecureStorage().read(key: AlmacenSesionTexto.clave),
        isNull,
      );
    });

    test('la app móvil usa el almacén seguro', () {
      expect(crearAlmacenSesionDeLaApp(), isA<AlmacenSesionSeguro>());
    });
  });
}
