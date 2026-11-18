import 'dart:async';

import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/core/router/rutas.dart';
import 'package:creafacil_app/features/autenticacion/domain/sesion.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/presentation/perfil_page.dart';
import 'package:creafacil_app/features/autenticacion/presentation/registro_page.dart';
import 'package:creafacil_app/features/autenticacion/presentation/sesion_controller.dart';
import 'package:creafacil_app/features/autenticacion/presentation/widgets/cuenta_widgets.dart';
import 'package:creafacil_app/features/autenticacion/presentation/widgets/formulario_acceso.dart';
import 'package:creafacil_app/features/autenticacion/presentation/widgets/plantilla_acceso.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_prueba.dart';
import '../../helpers/envolver.dart';
import '../../helpers/sesion_falsa.dart';

void main() {
  late AlmacenSesionMemoria almacen;
  late RepositorioAutenticacionFalso repositorio;

  setUp(() {
    almacen = AlmacenSesionMemoria();
    repositorio = RepositorioAutenticacionFalso();
  });

  Future<void> montar(WidgetTester tester, String ruta) async {
    fijarVentana(tester, 1280, 1400);
    await montarApp(
      tester,
      almacen: almacen,
      repositorio: repositorio,
      ruta: ruta,
    );
  }

  Future<String> ruta(WidgetTester tester) async =>
      rutaActual(ProviderScopeHelper.contenedor(tester));

  Future<void> escribir(WidgetTester tester, Key clave, String texto) =>
      tester.enterText(find.byKey(clave), texto);

  Finder mensaje(Key clave) => find.byKey(clave);

  group('Iniciar sesión', () {
    testWidgets('valida en el cliente sin llamar a la API', (tester) async {
      await montar(tester, Rutas.acceso);

      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pump();
      expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);

      await escribir(tester, FormularioAcceso.claveEmail, 'ana@');
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pump();
      expect(find.text('El correo electrónico no es válido'), findsOneWidget);
      expect(repositorio.llamadas, isEmpty);
    });

    testWidgets('no muestra «¿Olvidaste tu contraseña?»', (tester) async {
      await montar(tester, Rutas.acceso);
      expect(find.textContaining('Olvidaste'), findsNothing);
      expect(find.text('¿No tienes cuenta?'), findsOneWidget);
    });

    testWidgets('login correcto: entra y lleva al inicio con su nombre', (
      tester,
    ) async {
      await montar(tester, Rutas.acceso);
      await escribir(
        tester,
        FormularioAcceso.claveEmail,
        'ana@app.creafacil.test',
      );
      await escribir(tester, FormularioAcceso.clavePassword, 'secreta123');
      // Enter en la contraseña envía el formulario.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repositorio.llamadas, ['login:ana@app.creafacil.test']);
      expect(await ruta(tester), Rutas.inicio);
      expect(find.text('Hola, Ana Pérez'), findsOneWidget);
      expect(find.byKey(AccionCuenta.clavePerfil), findsOneWidget);
      expect(almacen.sesion, isNotNull);
    });

    testWidgets('estado de carga y sin envíos dobles', (tester) async {
      final respuesta = Completer<Sesion>();
      repositorio.alIniciar = (_, _) => respuesta.future;
      await montar(tester, Rutas.acceso);
      await escribir(tester, FormularioAcceso.claveEmail, 'ana@x.co');
      await escribir(tester, FormularioAcceso.clavePassword, 'secreta123');

      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pump();
      expect(find.text('Iniciando sesión…'), findsOneWidget);
      expect(
        tester
            .widget<CfButton>(find.byKey(FormularioAcceso.claveEnviar))
            .loading,
        isTrue,
      );
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repositorio.llamadas, hasLength(1));

      respuesta.complete(sesionPrueba());
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.inicio);
    });

    for (final (estado, codigo, texto, titulo) in [
      (401, 'CREDENCIALES_INVALIDAS', 'Correo o contraseña incorrectos.', null),
      (
        403,
        'CUENTA_DESACTIVADA',
        'Tu cuenta está desactivada.',
        'Cuenta desactivada',
      ),
      (
        429,
        'DEMASIADOS_INTENTOS',
        'Demasiados intentos de inicio de sesión. Inténtalo de nuevo en 15 minutos.',
        'Demasiados intentos',
      ),
    ]) {
      testWidgets('muestra el error $estado $codigo con CfMessage', (
        tester,
      ) async {
        repositorio.alIniciar = (_, _) async =>
            throw errorApi(estado, codigo, texto);
        await montar(tester, Rutas.acceso);
        await escribir(tester, FormularioAcceso.claveEmail, 'ana@x.co');
        await escribir(tester, FormularioAcceso.clavePassword, 'mala');
        await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
        await tester.pumpAndSettle();

        final error = tester.widget<CfMessage>(
          mensaje(FormularioAcceso.claveError),
        );
        expect(error.text, texto);
        expect(error.title, titulo);
        expect(error.severity, CfMessageSeverity.error);
        expect(await ruta(tester), Rutas.acceso);
        expect(almacen.sesion, isNull);
      });
    }

    testWidgets('un 400 marca el campo con el mensaje del servidor', (
      tester,
    ) async {
      repositorio.alIniciar = (_, _) async =>
          throw errorApi(400, 'VALIDACION', 'Hay datos que no son válidos.', [
            {'campo': 'email', 'ubicacion': 'body', 'mensaje': 'Correo raro'},
          ]);
      await montar(tester, Rutas.acceso);
      await escribir(tester, FormularioAcceso.claveEmail, 'ana@x.co');
      await escribir(tester, FormularioAcceso.clavePassword, 'x');
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pumpAndSettle();
      expect(find.text('Correo raro'), findsOneWidget);

      await escribir(tester, FormularioAcceso.claveEmail, 'ana@y.co');
      await tester.pump();
      expect(find.text('Correo raro'), findsNothing);
    });

    testWidgets('una ADMIN recibe el rechazo y no se guarda la sesión', (
      tester,
    ) async {
      repositorio.alIniciar = (_, _) async =>
          sesionPrueba(usuario: adminPrueba);
      await montar(tester, Rutas.acceso);
      await escribir(
        tester,
        FormularioAcceso.claveEmail,
        'admin@creafacil.test',
      );
      await escribir(tester, FormularioAcceso.clavePassword, 'secreta123');
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pumpAndSettle();

      expect(
        find.text('Esta app es para clientes. Usa el panel administrativo.'),
        findsOneWidget,
      );
      expect(find.text('Acceso no permitido'), findsOneWidget);
      expect(almacen.guardados, 0);
      expect(await ruta(tester), Rutas.acceso);
    });

    testWidgets('«Crear cuenta» abre el registro conservando el destino', (
      tester,
    ) async {
      await montar(tester, Rutas.perfil);
      expect(await ruta(tester), '/acceso?desde=%2Fperfil');
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(await ruta(tester), '/registro?desde=%2Fperfil');
      expect(find.byKey(RegistroPage.claveNombre), findsOneWidget);
    });

    testWidgets('el botón de volver lleva al inicio', (tester) async {
      await montar(tester, Rutas.acceso);
      await tester.tap(find.byTooltip('Volver al inicio'));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.inicio);
    });
  });

  group('Crear cuenta', () {
    testWidgets('valida todos los campos como el servidor', (tester) async {
      await montar(tester, Rutas.registro);
      await tester.tap(find.byKey(RegistroPage.claveEnviar));
      await tester.pump();
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('El correo electrónico es obligatorio'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria'), findsOneWidget);
      expect(find.text('Confirma la contraseña'), findsOneWidget);

      await escribir(tester, RegistroPage.claveNombre, 'Ana');
      await escribir(tester, RegistroPage.claveEmail, 'ana@x.co');
      await escribir(tester, RegistroPage.claveTelefono, '123');
      await escribir(tester, RegistroPage.clavePassword, 'corta');
      await escribir(tester, RegistroPage.claveConfirmar, 'otra');
      await tester.tap(find.byKey(RegistroPage.claveEnviar));
      await tester.pump();
      expect(find.textContaining('El teléfono debe tener'), findsOneWidget);
      expect(
        find.text('La contraseña debe tener al menos 8 caracteres'),
        findsOneWidget,
      );
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      expect(repositorio.llamadas, isEmpty);
    });

    Future<void> rellenar(WidgetTester tester) async {
      await escribir(tester, RegistroPage.claveNombre, 'Ana Pérez');
      await escribir(tester, RegistroPage.claveEmail, 'ana@app.creafacil.test');
      await escribir(tester, RegistroPage.claveTelefono, '+593 99 123 4567');
      await escribir(tester, RegistroPage.clavePassword, 'secreta123');
      await escribir(tester, RegistroPage.claveConfirmar, 'secreta123');
    }

    testWidgets('registro correcto: sesión iniciada y saludo en el inicio', (
      tester,
    ) async {
      await montar(tester, Rutas.registro);
      await rellenar(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final datos = repositorio.ultimoRegistro!;
      expect(datos.nombre, 'Ana Pérez');
      expect(datos.telefono, '+593 99 123 4567');
      expect(datos.password, 'secreta123');
      expect(await ruta(tester), Rutas.inicio);
      expect(find.text('Hola, Ana Pérez'), findsOneWidget);
      expect(almacen.sesion?.usuario.rol, RolUsuario.cliente);
    });

    testWidgets('los detalles del 400 aparecen en su campo', (tester) async {
      repositorio.alRegistrar = (_) async =>
          throw errorApi(400, 'VALIDACION', 'Hay datos que no son válidos.', [
            {
              'campo': 'telefono',
              'ubicacion': 'body',
              'mensaje': 'Teléfono no aceptado por el servidor',
            },
            {
              'campo': 'nombre',
              'ubicacion': 'body',
              'mensaje': 'Nombre no aceptado',
            },
          ]);
      await montar(tester, Rutas.registro);
      await rellenar(tester);
      await tester.tap(find.byKey(RegistroPage.claveEnviar));
      await tester.pumpAndSettle();

      expect(find.text('Teléfono no aceptado por el servidor'), findsOneWidget);
      expect(find.text('Nombre no aceptado'), findsOneWidget);
      expect(find.text('Revisa los datos'), findsOneWidget);

      await escribir(tester, RegistroPage.claveNombre, 'Ana María');
      await tester.pump();
      expect(find.text('Nombre no aceptado'), findsNothing);
    });

    testWidgets('el 409 ofrece iniciar sesión con ese correo', (tester) async {
      repositorio.alRegistrar = (_) async => throw errorApi(
        409,
        'CONFLICTO',
        'Ya existe una cuenta con ese correo.',
      );
      await montar(tester, Rutas.registro);
      await rellenar(tester);
      await tester.tap(find.byKey(RegistroPage.claveEnviar));
      await tester.pumpAndSettle();

      expect(find.text('Ya existe una cuenta con ese correo.'), findsOneWidget);
      await tester.tap(find.byKey(RegistroPage.claveIrAcceso));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.acceso);
    });

    testWidgets('estado de carga en el registro', (tester) async {
      final respuesta = Completer<Sesion>();
      repositorio.alRegistrar = (_) => respuesta.future;
      await montar(tester, '/registro?desde=%2Fperfil');
      await rellenar(tester);
      await tester.tap(find.byKey(RegistroPage.claveEnviar));
      await tester.pump();
      expect(find.text('Creando cuenta…'), findsOneWidget);
      await tester.tap(find.byKey(RegistroPage.claveEnviar));
      await tester.pump();
      expect(repositorio.llamadas, hasLength(1));
      respuesta.complete(sesionPrueba());
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.perfil, reason: 'vuelve al destino');
    });

    testWidgets('«¿Ya tienes cuenta?» lleva al inicio de sesión', (
      tester,
    ) async {
      await montar(tester, '/registro?desde=%2Fperfil');
      await tester.tap(find.text('Iniciar sesión').last);
      await tester.pumpAndSettle();
      expect(await ruta(tester), '/acceso?desde=%2Fperfil');
    });
  });

  group('Mi perfil', () {
    testWidgets('muestra los datos del cliente y la edición habilitada', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, Rutas.perfil);

      expect(await ruta(tester), Rutas.perfil);
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsWidgets);
      expect(find.text('ana@app.creafacil.test'), findsOneWidget);
      expect(find.text('+593991234567'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      expect(
        tester.widget<CfButton>(find.byKey(PerfilPage.claveEditar)).onPressed,
        isNotNull,
      );
      expect(find.textContaining('próximamente'), findsNothing);

      await tester.tap(find.byKey(PerfilPage.claveEditar));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.perfilEditar);
    });

    testWidgets('sin teléfono muestra «No indicado»', (tester) async {
      almacen.sesion = sesionPrueba(usuario: adminPrueba).conUsuario(
        const Usuario(
          id: 'x',
          nombre: 'Luis',
          email: 'luis@x.co',
          rol: RolUsuario.cliente,
        ),
      );
      repositorio.alPerfil = (_) async => almacen.sesion!.usuario;
      await montar(tester, Rutas.perfil);
      expect(find.text(PerfilPage.textoSinTelefono), findsOneWidget);
    });

    testWidgets('cerrar sesión pide confirmación y borra la sesión', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, Rutas.perfil);

      await tester.tap(find.byKey(PerfilPage.claveCerrarSesion));
      await tester.pumpAndSettle();
      expect(
        find.text('¿Quieres cerrar tu sesión en CreaFácil?'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CfConfirmDialog.claveCancelar));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.perfil);
      expect(almacen.sesion, isNotNull);

      await tester.tap(find.byKey(PerfilPage.claveCerrarSesion));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CfConfirmDialog.claveConfirmar));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.inicio);
      expect(almacen.sesion, isNull);
      expect(find.text('Tu cuenta'), findsOneWidget);
      expect(find.byKey(AccionCuenta.claveAcceso), findsOneWidget);
    });
  });

  group('Inicio', () {
    testWidgets('sin sesión: «Iniciar sesión» y «Crear cuenta»', (
      tester,
    ) async {
      await montar(tester, Rutas.inicio);
      final tarjeta = find.byKey(TarjetaCuenta.claveTarjeta);
      expect(
        find.descendant(of: tarjeta, matching: find.text('Crear cuenta')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: tarjeta, matching: find.text('Crear cuenta')),
      );
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.registro);

      await tester.tap(find.byTooltip('Volver al inicio'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: tarjeta, matching: find.text('Iniciar sesión')),
      );
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.acceso);

      await tester.tap(find.byTooltip('Volver al inicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccionCuenta.claveAcceso));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.acceso);
    });

    testWidgets('con sesión: «Hola, nombre» y acceso a «Mi perfil»', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, Rutas.inicio);
      expect(find.text('Hola, Ana Pérez'), findsOneWidget);
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.perfil);

      await tester.tap(find.byTooltip('Volver al inicio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AccionCuenta.clavePerfil));
      await tester.pumpAndSettle();
      expect(await ruta(tester), Rutas.perfil);
    });

    testWidgets('mientras se restaura la sesión muestra un indicador', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      final perfil = Completer<Usuario>();
      repositorio.alPerfil = (_) => perfil.future;
      fijarVentana(tester, 1280, 1400);
      await montarAppSinEsperar(tester, almacen, repositorio);
      expect(find.text('Comprobando tu sesión…'), findsOneWidget);

      perfil.complete(clientePrueba);
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana Pérez'), findsOneWidget);
    });
  });

  group('Sesión expirada', () {
    testWidgets('al restaurar una sesión caducada se avisa en el acceso', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba(vigencia: const Duration(hours: -1));
      await montar(tester, Rutas.perfil);
      expect(await ruta(tester), '/acceso?desde=%2Fperfil');
      expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pump();
      expect(find.text(SesionController.avisoSesionExpirada), findsNothing);
    });

    testWidgets('un 401 durante el uso cierra la sesión y lleva al acceso', (
      tester,
    ) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, Rutas.perfil);
      final contenedor = ProviderScopeHelper.contenedor(tester);

      contenedor.read(proveedorTokenProvider).tokenRechazado();
      await tester.pumpAndSettle();

      expect(rutaActual(contenedor), '/acceso?desde=%2Fperfil');
      expect(find.byKey(FormularioAcceso.claveAviso), findsOneWidget);
      expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);
      expect(almacen.sesion, isNull);

      // Al volver a entrar, regresa al perfil.
      await escribir(tester, FormularioAcceso.claveEmail, 'ana@x.co');
      await escribir(tester, FormularioAcceso.clavePassword, 'secreta123');
      await tester.tap(find.byKey(FormularioAcceso.claveEnviar));
      await tester.pumpAndSettle();
      expect(rutaActual(contenedor), Rutas.perfil);
    });

    testWidgets('un 401 en el inicio también lleva al acceso', (tester) async {
      almacen.sesion = sesionPrueba();
      await montar(tester, Rutas.inicio);
      final contenedor = ProviderScopeHelper.contenedor(tester);
      contenedor.read(proveedorTokenProvider).tokenRechazado();
      await tester.pumpAndSettle();
      expect(rutaActual(contenedor), '/acceso?desde=%2F');
      expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);
    });
  });

  group('Diseño adaptable', () {
    for (final ancho in [375.0, 768.0, 1280.0]) {
      for (final (nombre, destino, conSesion) in [
        ('acceso', Rutas.acceso, false),
        ('registro', Rutas.registro, false),
        ('perfil', Rutas.perfil, true),
      ]) {
        testWidgets('$nombre sin desbordes a ${ancho.toInt()} px', (
          tester,
        ) async {
          if (conSesion) {
            almacen.sesion = sesionPrueba();
          }
          fijarVentana(tester, ancho, 900);
          await montarApp(
            tester,
            almacen: almacen,
            repositorio: repositorio,
            ruta: destino,
          );
          expect(tester.takeException(), isNull);
          final tarjeta = tester.getRect(
            find.byKey(PlantillaAcceso.claveTarjeta),
          );
          expect(tarjeta.left, greaterThanOrEqualTo(0));
          expect(tarjeta.right, lessThanOrEqualTo(ancho));
          if (ancho >= 768) {
            expect(tarjeta.width, lessThanOrEqualTo(560));
          }
        });
      }
    }
  });
}
