import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/network/red.dart';
import '../data/almacen_sesion.dart';
import '../data/autenticacion_repository_impl.dart';
import '../domain/autenticacion_repository.dart';
import '../domain/politica_acceso.dart';
import '../domain/usuario.dart';
import 'configuracion_acceso.dart';
import 'estado_sesion.dart';
import 'proveedor_token_sesion.dart';
import 'sesion_controller.dart';

/// Reloj de la sesión (se sustituye en las pruebas).
final relojProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Qué rol puede usar esta app (ver `configuracion_acceso.dart`).
final politicaAccesoProvider = Provider<PoliticaAcceso>(
  (ref) => politicaAccesoDeLaApp,
);

/// Dónde se guarda la sesión (ver `configuracion_acceso.dart`).
final almacenSesionProvider = Provider<AlmacenSesion>(
  (ref) => crearAlmacenSesionDeLaApp(),
);

final autenticacionRepositoryProvider = Provider<AutenticacionRepository>(
  (ref) => AutenticacionRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Proveedor del token de la sesión para el `ApiClient`.
final proveedorTokenSesionProvider = Provider<ProveedorTokenSesion>(
  (ref) => ProveedorTokenSesion(reloj: ref.watch(relojProvider)),
);

/// Sesión de la app (restauración, inicio, registro y cierre).
final sesionControllerProvider =
    AsyncNotifierProvider<SesionController, EstadoSesion>(
      SesionController.new,
      // Los errores se tratan dentro del controlador: sin reintentos.
      retry: (_, _) => null,
    );

/// Usuario con la sesión iniciada o `null`.
final usuarioActualProvider = Provider<Usuario?>(
  (ref) => ref.watch(sesionControllerProvider).value?.usuario,
);

/// Conecta el `ApiClient` con la sesión: se usan en el `ProviderScope` de
/// `main.dart` (y en las pruebas de la app completa).
final List<Override> overridesAutenticacion = [
  proveedorTokenProvider.overrideWith(
    (ref) => ref.watch(proveedorTokenSesionProvider),
  ),
];
