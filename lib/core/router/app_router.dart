import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dev/presentation/componentes_page.dart';
import '../../features/inicio/presentation/inicio_page.dart';
import 'rutas.dart';

export 'rutas.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Rutas.inicio,
    routes: [
      GoRoute(
        path: Rutas.inicio,
        builder: (context, state) => const InicioPage(),
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
});
