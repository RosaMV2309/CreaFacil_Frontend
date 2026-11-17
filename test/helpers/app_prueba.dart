import 'package:creafacil_app/app.dart';
import 'package:creafacil_app/core/router/app_router.dart';
import 'package:creafacil_app/features/autenticacion/data/almacen_sesion.dart';
import 'package:creafacil_app/features/autenticacion/domain/autenticacion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'api_falsa.dart';
import 'sesion_falsa.dart';

/// Monta la app completa (API «conectada», sesión simulada) y, si se indica,
/// navega a [ruta]. Devuelve el contenedor de Riverpod de la app.
Future<ProviderContainer> montarApp(
  WidgetTester tester, {
  AlmacenSesion? almacen,
  AutenticacionRepository? repositorio,
  String? ruta,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...apiConectada(),
        ...sesionSimulada(almacen: almacen, repositorio: repositorio),
        ...extra,
      ],
      child: const CreaFacilApp(),
    ),
  );
  await tester.pumpAndSettle();
  final contenedor = ProviderScope.containerOf(
    tester.element(find.byType(CreaFacilApp)),
  );
  if (ruta != null) {
    contenedor.read(appRouterProvider).go(ruta);
    await tester.pumpAndSettle();
  }
  return contenedor;
}

/// Monta la app y solo hace un `pump` (para ver estados de carga).
Future<void> montarAppSinEsperar(
  WidgetTester tester,
  AlmacenSesion almacen,
  AutenticacionRepository repositorio,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...apiConectada(),
        ...sesionSimulada(almacen: almacen, repositorio: repositorio),
      ],
      child: const CreaFacilApp(),
    ),
  );
  await tester.pump();
}

/// Acceso al contenedor de Riverpod de la app montada.
abstract final class ProviderScopeHelper {
  static ProviderContainer contenedor(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CreaFacilApp)));
}

/// Alias del provider del router para las pruebas.
final appRouterProviderParaPrueba = appRouterProvider;

/// Ruta actual del router de la app.
String rutaActual(ProviderContainer contenedor) => contenedor
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .toString();
