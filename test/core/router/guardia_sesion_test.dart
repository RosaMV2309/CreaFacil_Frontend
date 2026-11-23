import 'package:creafacil_app/core/config/herramientas_dev.dart';
import 'package:creafacil_app/core/router/guardia_sesion.dart';
import 'package:creafacil_app/core/router/rutas.dart';
import 'package:creafacil_app/features/autenticacion/presentation/estado_sesion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_prueba.dart';
import '../../helpers/sesion_falsa.dart';

void main() {
  const sinSesion = AsyncData(EstadoSesion());
  final conSesion = AsyncData(EstadoSesion(sesion: sesionPrueba()));
  const cargando = AsyncLoading<EstadoSesion>();

  String? redirigir(AsyncValue<EstadoSesion> estado, String ruta) =>
      redireccionPorSesion(estado: estado, uri: Uri.parse(ruta));

  group('redireccionPorSesion [RF-01][RF-02]', () {
    test('/perfil sin sesión → /acceso conservando el destino', () {
      expect(redirigir(sinSesion, Rutas.perfil), '/acceso?desde=%2Fperfil');
    });

    test('mientras se restaura, /perfil espera en /acceso', () {
      expect(redirigir(cargando, Rutas.perfil), '/acceso?desde=%2Fperfil');
      expect(redirigir(cargando, Rutas.acceso), isNull);
    });

    test('las rutas públicas no se redirigen', () {
      for (final ruta in [
        Rutas.inicio,
        Rutas.acceso,
        Rutas.registro,
        Rutas.componentes,
      ]) {
        expect(redirigir(sinSesion, ruta), isNull, reason: ruta);
      }
      expect(redirigir(conSesion, Rutas.inicio), isNull);
      expect(redirigir(conSesion, Rutas.perfil), isNull);
    });

    test('con sesión, /acceso y /registro van al destino o al inicio', () {
      expect(redirigir(conSesion, Rutas.acceso), Rutas.inicio);
      expect(redirigir(conSesion, Rutas.registro), Rutas.inicio);
      expect(redirigir(conSesion, '/acceso?desde=%2Fperfil'), Rutas.perfil);
    });

    test('destinoSeguro solo acepta rutas internas', () {
      expect(destinoSeguro(null), isNull);
      expect(destinoSeguro('https://malo.com'), isNull);
      expect(destinoSeguro('//malo.com'), isNull);
      expect(destinoSeguro(r'/\malo.com'), isNull);
      expect(destinoSeguro(Rutas.acceso), isNull);
      expect(destinoSeguro('/registro?x=1'), isNull);
      expect(destinoSeguro(Rutas.perfil), Rutas.perfil);
    });

    test('accesoDesde', () {
      expect(Rutas.accesoDesde(null), Rutas.acceso);
      expect(Rutas.accesoDesde('/'), '/acceso?desde=%2F');
    });
  });

  group('router de la app', () {
    testWidgets('con sesión, abrir /acceso o /registro lleva al inicio', (
      tester,
    ) async {
      final contenedor = await montarApp(
        tester,
        almacen: AlmacenSesionMemoria(sesionPrueba()),
        ruta: Rutas.acceso,
      );
      expect(rutaActual(contenedor), Rutas.inicio);
      contenedor.read(appRouterProviderParaPrueba).go(Rutas.registro);
      await tester.pumpAndSettle();
      expect(rutaActual(contenedor), Rutas.inicio);
    });

    testWidgets('sin sesión, /perfil lleva a /acceso', (tester) async {
      final contenedor = await montarApp(tester, ruta: Rutas.perfil);
      expect(rutaActual(contenedor), '/acceso?desde=%2Fperfil');
      expect(find.text('Iniciar sesión'), findsWidgets);
    });

    testWidgets('el catálogo /dev/componentes sigue disponible en debug', (
      tester,
    ) async {
      await montarApp(tester);
      final contenedor = ProviderScopeHelper.contenedor(tester);
      contenedor.read(appRouterProviderParaPrueba).go(Rutas.componentes);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Catálogo de componentes'), findsOneWidget);
    });

    testWidgets('con MOSTRAR_HERRAMIENTAS_DEV=false no hay botón ni ruta', (
      tester,
    ) async {
      final contenedor = await montarApp(
        tester,
        extra: [mostrarHerramientasDevProvider.overrideWithValue(false)],
      );
      expect(find.text('Ver componentes'), findsNothing);
      final router = contenedor.read(appRouterProviderParaPrueba);
      final rutas = router.configuration.routes.whereType<GoRoute>().map(
        (r) => r.path,
      );
      expect(rutas, isNot(contains(Rutas.componentes)));
      router.go(Rutas.componentes);
      await tester.pumpAndSettle();
      expect(find.text('Catálogo de componentes'), findsNothing);
    });

    testWidgets('con las herramientas activas se ve «Ver componentes»', (
      tester,
    ) async {
      await montarApp(
        tester,
        extra: [mostrarHerramientasDevProvider.overrideWithValue(true)],
      );
      expect(find.text('Ver componentes'), findsOneWidget);
    });
  });
}
