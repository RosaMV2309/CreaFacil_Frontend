import 'dart:async';

import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/features/autenticacion/data/autenticacion_repository_impl.dart';
import 'package:creafacil_app/features/autenticacion/domain/cambios_perfil.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/presentation/autenticacion_providers.dart';
import 'package:creafacil_app/features/autenticacion/presentation/proteccion_salida.dart';
import 'package:creafacil_app/features/autenticacion/presentation/sesion_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/sesion_falsa.dart';

/// Proveedor de token que registra los rechazos (401 con token).
class _ProveedorTokenPrueba implements ProveedorToken {
  int rechazos = 0;

  @override
  Future<String?> obtenerToken() async => 'tok.en';

  @override
  void tokenRechazado() => rechazos++;
}

const _anaMaria = Usuario(
  id: '7d0c4c1e-1111-4a2b-9c3d-000000000001',
  nombre: 'Ana María',
  email: 'ana@app.creafacil.test',
  telefono: '+593987654321',
  rol: RolUsuario.cliente,
);

void main() {
  group('CambiosPerfil (solo lo que cambió)', () {
    CambiosPerfil desde(String nombre, String telefono) =>
        CambiosPerfil.desdeFormulario(
          clientePrueba,
          nombre: nombre,
          telefono: telefono,
        );

    test('sin cambios (con espacios y separadores) no hay nada que enviar', () {
      final cambios = desde('  Ana Pérez ', '+593 99 123-4567');
      expect(cambios.hayCambios, isFalse);
      expect(cambios, const CambiosPerfil());
    });

    test('solo el nombre, recortado', () {
      final cambios = desde(' Ana María ', '+593991234567');
      expect(cambios, const CambiosPerfil(nombre: 'Ana María'));
      expect(cambios.cambiaTelefono, isFalse);
      expect(cambios.hayCambios, isTrue);
    });

    test('solo el teléfono, normalizado como en el servidor', () {
      expect(
        desde('Ana Pérez', '(099) 876-54 32'),
        const CambiosPerfil(cambiaTelefono: true, telefono: '0998765432'),
      );
    });

    test('teléfono vacío con uno guardado: se borra', () {
      final cambios = desde('Ana Pérez', '   ');
      expect(cambios, const CambiosPerfil.borrarTelefono());
      expect(cambios.borraTelefono, isTrue);
      expect(cambios.hayCambios, isTrue);
    });

    test('teléfono vacío sin uno guardado: no cambia', () {
      final sinTelefono = aplicarCambios(
        clientePrueba,
        const CambiosPerfil.borrarTelefono(),
      );
      expect(
        CambiosPerfil.desdeFormulario(
          sinTelefono,
          nombre: 'Ana Pérez',
          telefono: '',
        ),
        const CambiosPerfil(),
      );
    });

    test('igualdad y texto legible', () {
      const a = CambiosPerfil(
        nombre: 'X',
        cambiaTelefono: true,
        telefono: '1234567',
      );
      const b = CambiosPerfil(
        nombre: 'X',
        cambiaTelefono: true,
        telefono: '1234567',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const CambiosPerfil(nombre: 'X')));
      expect('$a', contains('1234567'));
      expect('${const CambiosPerfil.borrarTelefono()}', contains('borrar'));
      expect('${const CambiosPerfil()}', contains('sin cambios'));
    });
  });

  group('AutenticacionRepositoryImpl.actualizarPerfil (Dio simulado)', () {
    late AdaptadorHttpFalso adaptador;
    late _ProveedorTokenPrueba proveedor;

    setUp(() => proveedor = _ProveedorTokenPrueba());

    AutenticacionRepositoryImpl repositorio() => AutenticacionRepositoryImpl(
      ApiClient(
        baseUrl: 'http://localhost:3100/api/v1',
        proveedorToken: proveedor,
        dio: Dio()..httpClientAdapter = adaptador,
      ),
    );

    void responder(int estado, Object cuerpo) => adaptador = AdaptadorHttpFalso(
      (o) async => respuestaJson(estado, cuerpo),
    );

    Map<String, dynamic> cuerpoEnviado() =>
        adaptador.peticiones.single.data as Map<String, dynamic>;

    test('200: PATCH /auth/perfil con el token y SOLO el nombre', () async {
      responder(200, {'usuario': cuerpoUsuario(_anaMaria)});
      final usuario = await repositorio().actualizarPerfil(
        const CambiosPerfil(nombre: 'Ana María'),
      );

      final peticion = adaptador.peticiones.single;
      expect(peticion.method, 'PATCH');
      expect(peticion.path, endsWith('/auth/perfil'));
      expect(peticion.headers['Authorization'], 'Bearer tok.en');
      expect(cuerpoEnviado(), {'nombre': 'Ana María'});
      expect(usuario, _anaMaria);
    });

    test('200: nombre y teléfono', () async {
      responder(200, {'usuario': cuerpoUsuario(_anaMaria)});
      await repositorio().actualizarPerfil(
        const CambiosPerfil(
          nombre: 'Ana María',
          cambiaTelefono: true,
          telefono: '+593987654321',
        ),
      );
      expect(cuerpoEnviado(), {
        'nombre': 'Ana María',
        'telefono': '+593987654321',
      });
    });

    test('200: borrar el teléfono envía telefono: null', () async {
      final sinTelefono = aplicarCambios(
        clientePrueba,
        const CambiosPerfil.borrarTelefono(),
      );
      responder(200, {'usuario': cuerpoUsuario(sinTelefono)});
      final usuario = await repositorio().actualizarPerfil(
        const CambiosPerfil.borrarTelefono(),
      );
      expect(cuerpoEnviado(), {'telefono': null});
      expect(cuerpoEnviado().containsKey('telefono'), isTrue);
      expect(usuario.telefono, isNull);
    });

    test('200 con forma inesperada → RESPUESTA_INVALIDA', () {
      responder(200, {'ok': true});
      expect(
        repositorio().actualizarPerfil(const CambiosPerfil(nombre: 'Ana')),
        throwsA(same(AutenticacionRepositoryImpl.respuestaInvalida)),
      );
    });

    test('400 VALIDACION con detalles por campo', () async {
      responder(400, {
        'error': {
          'codigo': 'VALIDACION',
          'mensaje': 'Los datos enviados no son válidos.',
          'detalles': [
            {
              'campo': 'telefono',
              'ubicacion': 'body',
              'mensaje':
                  'El teléfono debe tener de 7 a 15 dígitos (puede empezar '
                  'por + y llevar espacios o guiones)',
            },
            {
              'campo': 'email',
              'ubicacion': 'body',
              'mensaje':
                  'Este campo no se puede modificar: solo se pueden cambiar '
                  'nombre y telefono',
            },
          ],
        },
      });
      try {
        await repositorio().actualizarPerfil(
          const CambiosPerfil(cambiaTelefono: true, telefono: '12'),
        );
        fail('debía lanzar');
      } on ApiException catch (e) {
        expect(e.tipo, TipoErrorApi.validacion);
        expect(e.estadoHttp, 400);
        expect(e.erroresPorCampo.keys, ['telefono', 'email']);
        expect(e.erroresPorCampo['email'], startsWith('Este campo no se'));
      }
      expect(proveedor.rechazos, 0, reason: 'un 400 no cierra la sesión');
    });

    test('401 con token: ApiException y aviso de token rechazado', () async {
      responder(401, {
        'error': {
          'codigo': 'NO_AUTENTICADO',
          'mensaje': 'Tu sesión ya no es válida. Inicia sesión de nuevo.',
        },
      });
      await expectLater(
        repositorio().actualizarPerfil(const CambiosPerfil(nombre: 'Ana')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.tipo, 'tipo', TipoErrorApi.noAutorizado)
              .having((e) => e.codigo, 'codigo', 'NO_AUTENTICADO'),
        ),
      );
      expect(proveedor.rechazos, 1);
    });
  });

  group('SesionController.actualizarPerfil', () {
    late AlmacenSesionMemoria almacen;
    late RepositorioAutenticacionFalso repositorio;

    setUp(() {
      almacen = AlmacenSesionMemoria(sesionPrueba());
      repositorio = RepositorioAutenticacionFalso();
    });

    Future<ProviderContainer> contenedor() async {
      final c = ProviderContainer(
        overrides: sesionSimulada(almacen: almacen, repositorio: repositorio),
      );
      addTearDown(c.dispose);
      await c.read(sesionControllerProvider.future);
      return c;
    }

    SesionController controlador(ProviderContainer c) =>
        c.read(sesionControllerProvider.notifier);

    test(
      '200: actualiza la sesión en memoria y en el almacén, mismo token',
      () async {
        final c = await contenedor();
        final guardadosAntes = almacen.guardados;

        final usuario = await controlador(c)
            .actualizarPerfil(const CambiosPerfil(nombre: 'Ana María'));

        expect(usuario.nombre, 'Ana María');
        expect(repositorio.llamadas.last, 'actualizar');
        expect(c.read(usuarioActualProvider)?.nombre, 'Ana María');
        final sesion = c.read(sesionControllerProvider).value!.sesion!;
        expect(sesion.token, sesionPrueba().token);
        expect(sesion.expiraEn, sesionPrueba().expiraEn);
        expect(almacen.guardados, guardadosAntes + 1);
        expect(almacen.sesion?.usuario.nombre, 'Ana María');
        expect(almacen.sesion?.token, sesionPrueba().token);
        expect(
          await c.read(proveedorTokenProvider).obtenerToken(),
          sesionPrueba().token,
        );
        expect(
          repositorio.llamadas.where((l) => l.startsWith('login')),
          isEmpty,
          reason: 'no se pide un token nuevo',
        );
      },
    );

    test('borrar el teléfono deja la sesión sin teléfono', () async {
      final c = await contenedor();
      await controlador(c)
          .actualizarPerfil(const CambiosPerfil.borrarTelefono());
      expect(c.read(usuarioActualProvider)?.telefono, isNull);
      expect(almacen.sesion?.usuario.telefono, isNull);
    });

    test('sin cambios: no llama a la API', () async {
      final c = await contenedor();
      final usuario = await controlador(c)
          .actualizarPerfil(const CambiosPerfil());
      expect(usuario, clientePrueba);
      expect(repositorio.llamadas, isNot(contains('actualizar')));
    });

    test('sin sesión: StateError', () async {
      almacen.sesion = null;
      final c = await contenedor();
      expect(
        () => controlador(c).actualizarPerfil(const CambiosPerfil(nombre: 'X')),
        throwsStateError,
      );
    });

    test('error de la API: se propaga y la sesión no cambia', () async {
      repositorio.alActualizar = (_) async => throw errorApi(
        400,
        'VALIDACION',
        'Los datos enviados no son válidos.',
        [
          {'campo': 'nombre', 'ubicacion': 'body', 'mensaje': 'Corto'},
        ],
      );
      final c = await contenedor();
      final guardadosAntes = almacen.guardados;
      await expectLater(
        controlador(c).actualizarPerfil(const CambiosPerfil(nombre: 'A')),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(usuarioActualProvider), clientePrueba);
      expect(almacen.guardados, guardadosAntes);
    });

    test('si la sesión se cerró durante la petición, no se reabre', () async {
      final respuesta = Completer<Usuario>();
      repositorio.alActualizar = (_) => respuesta.future;
      final c = await contenedor();

      final peticion = controlador(c)
          .actualizarPerfil(const CambiosPerfil(nombre: 'Ana María'));
      await controlador(c).cerrarSesion();
      respuesta.complete(_anaMaria);
      await peticion;

      expect(c.read(sesionControllerProvider).value?.iniciada, isFalse);
      expect(almacen.sesion, isNull);
    });

    test('si el almacén falla, la sesión se actualiza en memoria', () async {
      final c = await contenedor();
      almacen.fallarAlEscribir = true;
      await controlador(c)
          .actualizarPerfil(const CambiosPerfil(nombre: 'Ana María'));
      expect(c.read(usuarioActualProvider)?.nombre, 'Ana María');
    });
  });

  group('ProteccionSalida', () {
    test('registra, consulta y solo libera su propia consulta', () {
      final proteccion = ProteccionSalida();
      expect(proteccion.hayCambios, isFalse);

      bool conCambios() => true;
      bool otra() => false;
      proteccion.registrar(conCambios);
      expect(proteccion.hayCambios, isTrue);

      proteccion.liberar(otra);
      expect(proteccion.hayCambios, isTrue);
      proteccion.liberar(conCambios);
      expect(proteccion.hayCambios, isFalse);
    });
  });
}
