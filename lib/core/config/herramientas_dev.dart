import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// Indica si se muestran las herramientas de desarrollo (catálogo de
/// componentes). Sobrescribible en las pruebas.
final mostrarHerramientasDevProvider = Provider<bool>(
  (ref) => AppConfig.mostrarHerramientasDev,
);
