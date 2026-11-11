import 'dart:async';

import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/core/theme/app_theme.dart';
import 'package:creafacil_app/features/estado_api/domain/estado_api.dart';
import 'package:creafacil_app/features/estado_api/presentation/estado_api_providers.dart';
import 'package:creafacil_app/features/estado_api/presentation/estado_api_tarjeta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/api_falsa.dart';
import '../../helpers/envolver.dart';

Future<void> montarTarjeta(
  WidgetTester tester,
  RepositorioEstadoApiFalso repositorio,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [estadoApiRepositoryProvider.overrideWithValue(repositorio)],
      child: MaterialApp(
        theme: AppTheme.claro(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: EstadoApiTarjeta(),
            ),
          ),
        ),
      ),
    ),
  );
}

const errorSinConexion = ApiException(
  tipo: TipoErrorApi.sinConexion,
  codigo: 'SIN_CONEXION',
  mensaje: ConversorErrores.mensajeSinConexion,
);

void main() {
  testWidgets('cargando: muestra CfSpinner', (tester) async {
    final pendiente = Completer<EstadoApi>();
    await montarTarjeta(
      tester,
      RepositorioEstadoApiFalso(() => pendiente.future),
    );
    await tester.pump();

    expect(find.byType(CfSpinner), findsOneWidget);
    expect(find.text(EstadoApiTarjeta.textoCargando), findsOneWidget);

    pendiente.complete(estadoConectado);
    await tester.pumpAndSettle();
    expect(find.byType(CfSpinner), findsNothing);
  });

  testWidgets('conectado: mensaje de éxito con versión y entorno', (
    tester,
  ) async {
    await montarTarjeta(
      tester,
      RepositorioEstadoApiFalso(() async => estadoConectado),
    );
    await tester.pumpAndSettle();

    expect(find.text(EstadoApiTarjeta.titulo), findsOneWidget);
    expect(find.text(EstadoApiTarjeta.textoConectado), findsOneWidget);
    expect(find.text('Versión 0.1.0 · Entorno: development'), findsOneWidget);
    final mensaje = tester.widget<CfMessage>(find.byType(CfMessage));
    expect(mensaje.severity, CfMessageSeverity.success);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('conectado con base de datos en línea', (tester) async {
    await montarTarjeta(
      tester,
      RepositorioEstadoApiFalso(
        () async => const EstadoApi(
          estado: EstadoServicio.ok,
          servicio: 'CreaFácil API',
          version: '0.2.0',
          entorno: 'production',
          baseDatos: EstadoBaseDatos.ok,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Versión 0.2.0 · Entorno: production · Base de datos en línea'),
      findsOneWidget,
    );
  });

  testWidgets('degradado: aviso de base de datos y Reintentar', (tester) async {
    final repo = RepositorioEstadoApiFalso(() async => estadoDegradado);
    await montarTarjeta(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text(EstadoApiTarjeta.textoDegradado), findsOneWidget);
    expect(find.text(EstadoApiTarjeta.textoConectado), findsNothing);
    expect(
      tester.widget<CfMessage>(find.byType(CfMessage)).severity,
      CfMessageSeverity.warning,
    );

    repo.respuesta = () async => estadoConectado;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(repo.llamadas, 2);
    expect(find.text(EstadoApiTarjeta.textoConectado), findsOneWidget);
  });

  testWidgets('error: CfErrorState con el mensaje y Reintentar', (
    tester,
  ) async {
    final repo = RepositorioEstadoApiFalso(
      () => Future<EstadoApi>.error(errorSinConexion),
    );
    await montarTarjeta(tester, repo);
    await tester.pumpAndSettle();

    expect(find.byType(CfErrorState), findsOneWidget);
    expect(find.text(EstadoApiTarjeta.textoSinConexion), findsOneWidget);
    expect(find.text(ConversorErrores.mensajeSinConexion), findsOneWidget);

    // Al reintentar se ve el spinner y, si la API ya responde, «Conectado».
    final pendiente = Completer<EstadoApi>();
    repo.respuesta = () => pendiente.future;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(find.byType(CfSpinner), findsOneWidget);

    pendiente.complete(estadoConectado);
    await tester.pumpAndSettle();
    expect(repo.llamadas, 2);
    expect(find.byType(CfErrorState), findsNothing);
    expect(find.text(EstadoApiTarjeta.textoConectado), findsOneWidget);
  });

  testWidgets('error que no es ApiException: mensaje genérico', (tester) async {
    await montarTarjeta(
      tester,
      RepositorioEstadoApiFalso(() => Future<EstadoApi>.error(StateError('x'))),
    );
    await tester.pumpAndSettle();

    expect(find.text(ConversorErrores.mensajeDesconocido), findsOneWidget);
  });

  for (final ancho in [375.0, 768.0, 1280.0]) {
    testWidgets('sin desbordes a ${ancho.toInt()} px en error y degradado', (
      tester,
    ) async {
      fijarVentana(tester, ancho);
      await montarTarjeta(
        tester,
        RepositorioEstadoApiFalso(
          () => Future<EstadoApi>.error(errorSinConexion),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Desmonta el ProviderScope anterior para empezar de cero.
      await tester.pumpWidget(const SizedBox());
      await montarTarjeta(
        tester,
        RepositorioEstadoApiFalso(() async => estadoDegradado),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
