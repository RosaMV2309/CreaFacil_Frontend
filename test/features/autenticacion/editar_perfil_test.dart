import 'dart:async';

import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/core/router/app_router.dart';
import 'package:creafacil_app/features/autenticacion/domain/cambios_perfil.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/presentation/editar_perfil_page.dart';
import 'package:creafacil_app/features/autenticacion/presentation/perfil_page.dart';
import 'package:creafacil_app/features/autenticacion/presentation/sesion_controller.dart';
import 'package:creafacil_app/features/autenticacion/presentation/widgets/cuenta_widgets.dart';
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
    almacen = AlmacenSesionMemoria(sesionPrueba());
    repositorio = RepositorioAutenticacionFalso();
  });

  Future<void> montar(WidgetTester tester, {double ancho = 1280}) async {
    fijarVentana(tester, ancho, 1400);
    await montarApp(
      tester,
      almacen: almacen,
      repositorio: repositorio,
      ruta: Rutas.perfilEditar,
    );
  }

  String ruta(WidgetTester tester) =>
      rutaActual(ProviderScopeHelper.contenedor(tester));

  Finder campo(Key clave) => find.descendant(
    of: find.byKey(clave),
    matching: find.byType(EditableText),
  );

  String texto(WidgetTester tester, Key clave) =>
      tester.widget<EditableText>(campo(clave)).controller.text;

  CfButton boton(WidgetTester tester, Key clave) =>
      tester.widget<CfButton>(find.byKey(clave));

  Future<void> escribir(WidgetTester tester, Key clave, String valor) async {
    await tester.enterText(find.byKey(clave), valor);
    await tester.pump();
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.tap(find.byKey(EditarPerfilPage.claveGuardar));
    await tester.pumpAndSettle();
  }

  testWidgets('precarga nombre y teléfono; correo de solo lectura', (
    tester,
  ) async {
    await montar(tester);
    expect(ruta(tester), Rutas.perfilEditar);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(texto(tester, EditarPerfilPage.claveNombre), 'Ana Pérez');
    expect(texto(tester, EditarPerfilPage.claveTelefono), '+593991234567');
    final correo = find.byKey(EditarPerfilPage.claveCorreo);
    expect(
      find.descendant(
        of: correo,
        matching: find.text('ana@app.creafacil.test'),
      ),
      findsOneWidget,
    );
    expect(find.text(EditarPerfilPage.notaCorreo), findsOneWidget);
    expect(
      find.descendant(of: correo, matching: find.byType(EditableText)),
      findsNothing,
    );
    expect(find.textContaining('próximamente'), findsNothing);
  });

  testWidgets('sin cambios: «Guardar cambios» deshabilitado y sin API', (
    tester,
  ) async {
    await montar(tester);
    expect(boton(tester, EditarPerfilPage.claveGuardar).onPressed, isNull);
    expect(find.byKey(EditarPerfilPage.claveSinCambios), findsOneWidget);

    // Volver al mismo valor (con separadores) tampoco cuenta como cambio.
    await escribir(tester, EditarPerfilPage.claveTelefono, '+593 99 123 4567');
    expect(boton(tester, EditarPerfilPage.claveGuardar).onPressed, isNull);

    // Enter en el teléfono tampoco envía nada.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repositorio.llamadas, isNot(contains('actualizar')));
  });

  testWidgets('valida en el cliente igual que el registro', (tester) async {
    await montar(tester);
    await escribir(tester, EditarPerfilPage.claveNombre, 'A');
    await escribir(tester, EditarPerfilPage.claveTelefono, '12-34');
    await guardar(tester);
    expect(
      find.text('El nombre debe tener al menos 2 caracteres'),
      findsOneWidget,
    );
    expect(
      find.textContaining('El teléfono debe tener de 7 a 15 dígitos'),
      findsOneWidget,
    );
    await escribir(tester, EditarPerfilPage.claveNombre, '   ');
    await guardar(tester);
    expect(find.text('El nombre es obligatorio'), findsOneWidget);
    expect(repositorio.llamadas, isNot(contains('actualizar')));
  });

  testWidgets('envía solo el nombre y vuelve a Mi perfil con el aviso', (
    tester,
  ) async {
    await montar(tester);
    await escribir(tester, EditarPerfilPage.claveNombre, '  Ana María ');
    await guardar(tester);

    expect(
      repositorio.cambiosEnviados.single,
      const CambiosPerfil(nombre: 'Ana María'),
    );
    expect(ruta(tester), Rutas.perfil);
    expect(find.byKey(EditarPerfilPage.claveAvisoGuardado), findsOneWidget);
    expect(find.text(EditarPerfilPage.avisoGuardado), findsOneWidget);
    expect(find.text('Ana María'), findsWidgets);
    expect(almacen.sesion?.usuario.nombre, 'Ana María');
    // Sin diálogo de cambios pendientes tras guardar.
    expect(find.byType(CfConfirmDialog), findsNothing);

    // El saludo del inicio refleja el nombre nuevo.
    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana María'), findsOneWidget);
    expect(find.byKey(TarjetaCuenta.claveTarjeta), findsOneWidget);
  });

  testWidgets('envía solo el teléfono, normalizado, con Enter', (tester) async {
    await montar(tester);
    await escribir(tester, EditarPerfilPage.claveTelefono, '(099) 876-5432');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      repositorio.cambiosEnviados.single,
      const CambiosPerfil(cambiaTelefono: true, telefono: '0998765432'),
    );
    expect(find.text('0998765432'), findsOneWidget);
  });

  testWidgets('«Borrar teléfono» vacía el campo y envía null', (tester) async {
    await montar(tester);
    await tester.tap(find.byKey(EditarPerfilPage.claveBorrarTelefono));
    await tester.pump();
    expect(texto(tester, EditarPerfilPage.claveTelefono), isEmpty);
    expect(find.text(EditarPerfilPage.ayudaTelefonoBorrado), findsOneWidget);
    expect(
      boton(tester, EditarPerfilPage.claveBorrarTelefono).onPressed,
      isNull,
      reason: 'ya no hay teléfono que borrar',
    );
    await guardar(tester);
    expect(
      repositorio.cambiosEnviados.single,
      const CambiosPerfil.borrarTelefono(),
    );
    expect(find.text(PerfilPage.textoSinTelefono), findsOneWidget);
    expect(almacen.sesion?.usuario.telefono, isNull);
  });

  testWidgets('muestra el estado de carga y evita el doble envío', (
    tester,
  ) async {
    final respuesta = Completer<Usuario>();
    repositorio.alActualizar = (_) => respuesta.future;
    await montar(tester);
    await escribir(tester, EditarPerfilPage.claveNombre, 'Ana María');
    await tester.tap(find.byKey(EditarPerfilPage.claveGuardar));
    await tester.pump();

    expect(find.text('Guardando…'), findsOneWidget);
    expect(boton(tester, EditarPerfilPage.claveGuardar).loading, isTrue);
    expect(boton(tester, EditarPerfilPage.claveCancelar).onPressed, isNull);
    await tester.tap(find.byKey(EditarPerfilPage.claveGuardar));
    await tester.pump();
    expect(repositorio.cambiosEnviados, hasLength(1));

    respuesta.complete(
      aplicarCambios(clientePrueba, repositorio.cambiosEnviados.single),
    );
    await tester.pumpAndSettle();
    expect(ruta(tester), Rutas.perfil);
  });

  testWidgets('400: errores en su campo y el resto en el mensaje', (
    tester,
  ) async {
    repositorio.alActualizar = (_) async => throw errorApi(
      400,
      'VALIDACION',
      'Los datos enviados no son válidos.',
      [
        {
          'campo': 'telefono',
          'ubicacion': 'body',
          'mensaje': 'El teléfono no es válido (servidor)',
        },
        {
          'campo': 'email',
          'ubicacion': 'body',
          'mensaje': 'Este campo no se puede modificar',
        },
      ],
    );
    await montar(tester);
    await escribir(tester, EditarPerfilPage.claveTelefono, '0998765432');
    await guardar(tester);

    expect(ruta(tester), Rutas.perfilEditar);
    expect(find.text('El teléfono no es válido (servidor)'), findsOneWidget);
    final error = find.byKey(EditarPerfilPage.claveError);
    expect(error, findsOneWidget);
    expect(find.text('Revisa los datos'), findsOneWidget);
    expect(
      find.descendant(
        of: error,
        matching: find.textContaining('Este campo no se puede modificar'),
      ),
      findsOneWidget,
    );

    // Al corregir el campo, su error desaparece; el mensaje se puede cerrar.
    await escribir(tester, EditarPerfilPage.claveTelefono, '0998765433');
    // Espera a que termine la animación de salida del error.
    await tester.pumpAndSettle();
    expect(find.text('El teléfono no es válido (servidor)'), findsNothing);
    await tester.tap(
      find.descendant(of: error, matching: find.byTooltip('Cerrar')),
    );
    await tester.pump();
    expect(find.byKey(EditarPerfilPage.claveError), findsNothing);
  });

  testWidgets('sin conexión: CfMessage con el mensaje', (tester) async {
    repositorio.alActualizar = (_) async => throw const ApiException(
      tipo: TipoErrorApi.sinConexion,
      codigo: 'SIN_CONEXION',
      mensaje: 'No se pudo conectar con el servidor.',
    );
    await montar(tester);
    await escribir(tester, EditarPerfilPage.claveNombre, 'Ana María');
    await guardar(tester);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('No se pudo conectar con el servidor.'), findsOneWidget);
    expect(ruta(tester), Rutas.perfilEditar);
  });

  testWidgets('401: cierra la sesión y lleva al acceso sin preguntar', (
    tester,
  ) async {
    await montar(tester);
    repositorio.alActualizar = (_) async {
      ProviderScopeHelper.contenedor(tester)
          .read(proveedorTokenProvider)
          .tokenRechazado();
      throw errorApi(401, 'NO_AUTENTICADO', 'Tu sesión ya no es válida.');
    };
    await escribir(tester, EditarPerfilPage.claveNombre, 'Ana María');
    await guardar(tester);
    expect(find.byType(CfConfirmDialog), findsNothing);
    expect(ruta(tester), startsWith(Rutas.acceso));
    expect(find.text(SesionController.avisoSesionExpirada), findsOneWidget);
  });

  group('confirmación al salir con cambios', () {
    testWidgets('sin cambios, «Cancelar» sale directamente', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(EditarPerfilPage.claveCancelar));
      await tester.pumpAndSettle();
      expect(find.byType(CfConfirmDialog), findsNothing);
      expect(ruta(tester), Rutas.perfil);
    });

    testWidgets('«Cancelar» con cambios: seguir editando o salir', (
      tester,
    ) async {
      await montar(tester);
      await escribir(tester, EditarPerfilPage.claveNombre, 'Ana María');
      await tester.tap(find.byKey(EditarPerfilPage.claveCancelar));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);

      await tester.tap(find.byKey(CfConfirmDialog.claveCancelar));
      await tester.pumpAndSettle();
      expect(ruta(tester), Rutas.perfilEditar);
      expect(texto(tester, EditarPerfilPage.claveNombre), 'Ana María');

      await tester.tap(find.byKey(EditarPerfilPage.claveCancelar));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CfConfirmDialog.claveConfirmar));
      await tester.pumpAndSettle();
      expect(ruta(tester), Rutas.perfil);
      expect(find.text('Ana Pérez'), findsWidgets);
      expect(repositorio.cambiosEnviados, isEmpty);
    });

    testWidgets('el botón de volver del encabezado también pregunta', (
      tester,
    ) async {
      await montar(tester);
      await tester.tap(find.byKey(EditarPerfilPage.claveBorrarTelefono));
      await tester.pump();
      await tester.tap(find.byTooltip('Volver a Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);
      await tester.tap(find.byKey(CfConfirmDialog.claveConfirmar));
      await tester.pumpAndSettle();
      expect(ruta(tester), Rutas.perfil);
    });
  });

  testWidgets('sin sesión, la ruta lleva al acceso', (tester) async {
    almacen.sesion = null;
    await montar(tester);
    expect(ruta(tester), '/acceso?desde=%2Fperfil%2Feditar');
  });

  group('Diseño adaptable', () {
    for (final ancho in [375.0, 768.0, 1280.0]) {
      testWidgets('sin desbordes a ${ancho.toInt()} px', (tester) async {
        fijarVentana(tester, ancho, 900);
        await montarApp(
          tester,
          almacen: almacen,
          repositorio: repositorio,
          ruta: Rutas.perfilEditar,
        );
        await escribir(tester, EditarPerfilPage.claveNombre, 'Ana María');
        expect(tester.takeException(), isNull);
        final tarjeta = tester.getRect(
          find.byKey(PlantillaAcceso.claveTarjeta),
        );
        expect(tarjeta.left, greaterThanOrEqualTo(0));
        expect(tarjeta.right, lessThanOrEqualTo(ancho));
        final guardar = tester.getRect(
          find.byKey(EditarPerfilPage.claveGuardar),
        );
        final cancelar = tester.getRect(
          find.byKey(EditarPerfilPage.claveCancelar),
        );
        if (ancho < 600) {
          // Móvil: apilados a todo el ancho, «Guardar» arriba.
          expect(guardar.top, lessThan(cancelar.top));
          expect(guardar.width, closeTo(cancelar.width, 0.5));
        } else {
          expect(tarjeta.width, lessThanOrEqualTo(560));
          expect(guardar.top, closeTo(cancelar.top, 0.5));
          expect(cancelar.right, lessThan(guardar.left));
        }
        expect(guardar.height, greaterThanOrEqualTo(48));
      });
    }
  });
}
