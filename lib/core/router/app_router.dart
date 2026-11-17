import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/autenticacion/presentation/acceso_page.dart';
import '../../features/autenticacion/presentation/autenticacion_providers.dart';
import '../../features/autenticacion/presentation/perfil_page.dart';
import '../../features/autenticacion/presentation/registro_page.dart';
import '../../features/dev/presentation/componentes_page.dart';
import '../../features/inicio/presentation/inicio_page.dart';
import 'guardia_sesion.dart';
import 'rutas.dart';

export 'rutas.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Avisa al router cada vez que cambia la sesión para reevaluar `redirect`.
  final refresco = ValueNotifier<int>(0);
  late final GoRouter router;

  ref.listen(sesionControllerProvider, (anterior, siguiente) {
    final teniaSesion = anterior?.value?.iniciada ?? false;
    final estado = siguiente.value;
    // Sesión caducada o 401: al inicio de sesión con el aviso, recordando
    // dónde estaba la usuaria. La ubicación se toma ANTES de refrescar el
    // router, porque el refresco ya puede redirigir.
    if (teniaSesion &&
        estado != null &&
        !estado.iniciada &&
        estado.aviso != null) {
      final actual = router.routerDelegate.currentConfiguration.uri;
      final desde = Rutas.soloSinSesion.contains(actual.path)
          ? null
          : actual.toString();
      router.go(Rutas.accesoDesde(desde));
    }
    refresco.value++;
  });

  router = GoRouter(
    initialLocation: Rutas.inicio,
    refreshListenable: refresco,
    redirect: (context, state) => redireccionPorSesion(
      estado: ref.read(sesionControllerProvider),
      uri: state.uri,
    ),
    routes: [
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const InicioPage(),
      ),
      GoRoute(
        path: Rutas.acceso,
        builder: (context, state) =>
            AccesoPage(desde: state.uri.queryParameters[Rutas.parametroDesde]),
      ),
      GoRoute(
        path: Rutas.registro,
        builder: (context, state) => RegistroPage(
          desde: state.uri.queryParameters[Rutas.parametroDesde],
        ),
      ),
      GoRoute(
        path: Rutas.perfil,
        builder: (context, state) => const PerfilPage(),
      ),
      // Catálogo de componentes para revisión visual: solo en modo debug,
      // no existe en las compilaciones de perfil ni de producción.
      if (kDebugMode)
        GoRoute(
          path: Rutas.componentes,
          builder: (context, state) => const ComponentesPage(),
        ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresco.dispose();
  });
  return router;
});
