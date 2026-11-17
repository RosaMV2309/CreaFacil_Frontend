import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/features/autenticacion/domain/autenticacion_repository.dart';
import 'package:creafacil_app/features/autenticacion/domain/politica_acceso.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/presentation/autenticacion_providers.dart';
import 'package:creafacil_app/features/autenticacion/presentation/estado_sesion.dart';
import 'package:creafacil_app/features/autenticacion/presentation/proveedor_token_sesion.dart';
import 'package:creafacil_app/features/autenticacion/presentation/sesion_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/sesion_falsa.dart';

void main() {
  late AlmacenSesionMemoria almacen;
  late RepositorioAutenticacionFalso repositorio;

  setUp(() {
    almacen = AlmacenSesionMemoria();
    repositorio = RepositorioAutenticacionFalso();
  });

  ProviderContainer contenedor({DateTime Function()? reloj}) {
    final c = ProviderContainer(
      overrides: sesionSimulada(
        almacen: almacen,
        repositorio: repositorio,
        reloj: reloj,
      ),
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<EstadoSesion> estadoInicial(ProviderContainer c) =>
      c.read(sesionControllerProvider.future);

  SesionController controlador(ProviderContainer c) =>
      c.read(sesionControllerProvider.notifier);

  group('restaurar al arrancar', () {
    test('sin sesión guardada: sin sesión y sin llamar a la API', () async {
      final estado = await estadoInicial(contenedor());
      expect(estado, const EstadoSesion());
      expect(repositorio.llamadas, isEmpty);
    });

    test(
      'sesión vigente: la valida con GET /auth/perfil y la actualiza',
      () async {
        almacen.sesion = sesionPrueba();
        final actualizado = Usuario(
          id: clientePrueba.id,
          nombre: 'Ana María',
          email: clientePrueba.email,
          rol: clientePrueba.rol,
        );
        repositorio.alPerfil = (_) async => actualizado;
        final c = contenedor();

        final estado = await estadoInicial(c);
        expect(repositorio.llamadas, ['perfil']);
        expect(estado.usuario?.nombre, 'Ana María');
        expect(almacen.sesion?.usuario.nombre, 'Ana María');
        expect(
          await c.read(proveedorTokenProvider).obtenerToken(),
          sesionPrueba().token,
        );
        expect(c.read(usuarioActualProvider)?.nombre, 'Ana María');
      },
    );

    test(
      'sesión caducada: la borra sin llamar a la API y deja el aviso',
      () async {
        almacen.sesion = sesionPrueba(vigencia: const Duration(minutes: -1));
        final estado = await estadoInicial(contenedor());
        expect(estado.iniciada, isFalse);
        expect(estado.aviso, SesionController.avisoSesionExpirada);
        expect(almacen.sesion, isNull);
        expect(repositorio.llamadas, isEmpty);
      },
    );

    test('la API responde 401: la borra y deja el aviso', () async {
      almacen.sesion = sesionPrueba();
      repositorio.alPerfil = (_) async =>
          throw errorApi(401, 'TOKEN_INVALIDO', 'Token no válido');
      final estado = await estadoInicial(contenedor());
      expect(estado.iniciada, isFalse);
      expect(estado.aviso, SesionController.avisoSesionExpirada);
      expect(almacen.borrados, 1);
    });

    test('sin conexión: conserva la sesión guardada', () async {
      almacen.sesion = sesionPrueba();
      repositorio.alPerfil = (_) async => throw const ApiException(
        tipo: TipoErrorApi.sinConexion,
        codigo: 'SIN_CONEXION',
        mensaje: 'sin red',
      );
      final estado = await estadoInicial(contenedor());
      expect(estado.sesion, sesionPrueba());
      expect(almacen.borrados, 0);
    });

    test('sesión guardada de una ADMIN: se descarta', () async {
      almacen.sesion = sesionPrueba(usuario: adminPrueba);
      final estado = await estadoInicial(contenedor());
      expect(estado.iniciada, isFalse);
      expect(almacen.sesion, isNull);
    });

    test('el perfil devuelve rol ADMIN: se descarta', () async {
      almacen.sesion = sesionPrueba();
      repositorio.alPerfil = (_) async => adminPrueba;
      final estado = await estadoInicial(contenedor());
      expect(estado.iniciada, isFalse);
      expect(almacen.sesion, isNull);
    });

    test('almacén ilegible: sin sesión', () async {
      almacen.fallarAlLeer = true;
      final estado = await estadoInicial(contenedor());
      expect(estado.iniciada, isFalse);
    });
  });

  group('iniciar sesión y registrarse', () {
    test('login de un cliente: guarda la sesión y entrega el token', () async {
      final c = contenedor();
      await estadoInicial(c);

      await controlador(c)
          .iniciarSesion(email: 'ana@x.co', password: 'secreta1');

      expect(repositorio.llamadas, ['login:ana@x.co']);
      expect(almacen.sesion, sesionPrueba());
      expect(c.read(sesionControllerProvider).value?.usuario, clientePrueba);
      expect(
        await c.read(proveedorTokenProvider).obtenerToken(),
        sesionPrueba().token,
      );
    });

    test('login de una ADMIN: rechazo y NO se guarda la sesión', () async {
      repositorio.alIniciar = (_, _) async =>
          sesionPrueba(usuario: adminPrueba);
      final c = contenedor();
      await estadoInicial(c);

      await expectLater(
        controlador(c).iniciarSesion(email: 'admin@x.co', password: 'x'),
        throwsA(
          isA<AccesoRechazadoException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Esta app es para clientes. Usa el panel administrativo.',
          ),
        ),
      );
      expect(almacen.guardados, 0);
      expect(c.read(sesionControllerProvider).value?.iniciada, isFalse);
      expect(await c.read(proveedorTokenProvider).obtenerToken(), isNull);
    });

    test('los errores de la API se propagan al formulario', () async {
      repositorio.alIniciar = (_, _) async => throw errorApi(
        401,
        'CREDENCIALES_INVALIDAS',
        'Correo o contraseña incorrectos.',
      );
      final c = contenedor();
      await estadoInicial(c);
      await expectLater(
        controlador(c).iniciarSesion(email: 'a@b.co', password: 'x'),
        throwsA(isA<ApiException>()),
      );
      expect(almacen.guardados, 0);
    });

    test('registro: la sesión queda iniciada', () async {
      final c = contenedor();
      await estadoInicial(c);
      await controlador(c).registrar(
        const DatosRegistro(
          nombre: 'Ana',
          email: 'a@b.co',
          password: 'secreta1',
        ),
      );
      expect(repositorio.ultimoRegistro?.email, 'a@b.co');
      expect(c.read(sesionControllerProvider).value?.iniciada, isTrue);
      expect(almacen.guardados, 1);
    });

    test('si el almacén falla, la sesión sigue en memoria', () async {
      almacen.fallarAlEscribir = true;
      final c = contenedor();
      await estadoInicial(c);
      await controlador(c).iniciarSesion(email: 'a@b.co', password: 'x');
      expect(c.read(sesionControllerProvider).value?.iniciada, isTrue);
      await controlador(c).cerrarSesion();
      expect(c.read(sesionControllerProvider).value?.iniciada, isFalse);
    });
  });

  group('cerrar y expirar', () {
    test('cerrar sesión borra todo y sin aviso', () async {
      almacen.sesion = sesionPrueba();
      final c = contenedor();
      await estadoInicial(c);

      await controlador(c).cerrarSesion();

      expect(almacen.sesion, isNull);
      expect(c.read(sesionControllerProvider).value, const EstadoSesion());
      expect(await c.read(proveedorTokenProvider).obtenerToken(), isNull);
    });

    test('token rechazado (401) → sin sesión con el aviso; descartarAviso lo quita', () async {
      almacen.sesion = sesionPrueba();
      final c = contenedor();
      await estadoInicial(c);

      c.read(proveedorTokenProvider).tokenRechazado();
      await Future<void>.delayed(Duration.zero);

      final estado = c.read(sesionControllerProvider).value!;
      expect(estado.iniciada, isFalse);
      expect(estado.aviso, SesionController.avisoSesionExpirada);
      expect(almacen.sesion, isNull);

      // Un segundo 401 ya no hace nada.
      c.read(proveedorTokenProvider).tokenRechazado();
      expect(almacen.borrados, 1);

      controlador(c).descartarAviso();
      expect(c.read(sesionControllerProvider).value, const EstadoSesion());
      controlador(c).descartarAviso();
    });

    test('al llegar expiraEn, la sesión se cierra sola', () async {
      almacen.sesion = sesionPrueba(vigencia: const Duration(milliseconds: 40));
      final c = contenedor();
      await estadoInicial(c);
      expect(c.read(sesionControllerProvider).value?.iniciada, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      final estado = c.read(sesionControllerProvider).value!;
      expect(estado.iniciada, isFalse);
      expect(estado.aviso, SesionController.avisoSesionExpirada);
    });

    test('ProveedorTokenSesion no entrega un token caducado', () async {
      var rechazos = 0;
      var ahora = ahoraPrueba;
      final proveedor = ProveedorTokenSesion(reloj: () => ahora)
        ..alRechazar = () => rechazos++;
      expect(await proveedor.obtenerToken(), isNull);

      proveedor.sesion = sesionPrueba();
      expect(await proveedor.obtenerToken(), sesionPrueba().token);

      ahora = ahoraPrueba.add(const Duration(hours: 9));
      expect(await proveedor.obtenerToken(), isNull);
      expect(rechazos, 1);
      expect(ProveedorTokenSesion().sesion, isNull);
    });
  });

  test(
    '401 global: una petición autenticada con 401 cierra la sesión',
    () async {
      almacen.sesion = sesionPrueba();
      final adaptador = AdaptadorHttpFalso(
        (o) async => respuestaJson(401, {
          'error': {
            'codigo': 'TOKEN_EXPIRADO',
            'mensaje': 'Tu sesión ha expirado.',
          },
        }),
      );
      final c = ProviderContainer(
        overrides: [
          ...sesionSimulada(almacen: almacen, repositorio: repositorio),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              baseUrl: 'http://api.prueba/api/v1',
              proveedorToken: ref.watch(proveedorTokenProvider),
              dio: Dio()..httpClientAdapter = adaptador,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(sesionControllerProvider.future);

      await expectLater(
        c.read(apiClientProvider).get('/cotizaciones'),
        throwsA(isA<ApiException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        adaptador.peticiones.single.headers['Authorization'],
        'Bearer ${sesionPrueba().token}',
      );
      final estado = c.read(sesionControllerProvider).value!;
      expect(estado.iniciada, isFalse);
      expect(estado.aviso, SesionController.avisoSesionExpirada);
      expect(almacen.sesion, isNull);
    },
  );
}
