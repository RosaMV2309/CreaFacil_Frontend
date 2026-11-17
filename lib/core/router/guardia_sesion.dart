import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/autenticacion/presentation/estado_sesion.dart';
import 'rutas.dart';

/// Redirección del router según la sesión [RF-01][RF-02].
///
/// - Las rutas protegidas ([Rutas.protegidas]) exigen sesión: sin ella (o
///   mientras se restaura) se va a `/acceso?desde=<ruta>`.
/// - Con sesión, `/acceso` y `/registro` llevan al destino guardado o al
///   inicio.
///
/// Es solo navegación: los permisos reales los comprueba siempre el servidor
/// (RNF-03, RN-05).
String? redireccionPorSesion({
  required AsyncValue<EstadoSesion> estado,
  required Uri uri,
}) {
  final ruta = uri.path;
  final iniciada = estado.value?.iniciada ?? false;

  if (!iniciada && Rutas.protegidas.contains(ruta)) {
    return Rutas.accesoDesde(uri.toString());
  }
  if (iniciada && Rutas.soloSinSesion.contains(ruta)) {
    return destinoSeguro(uri.queryParameters[Rutas.parametroDesde]) ??
        Rutas.inicio;
  }
  return null;
}

/// Acepta solo destinos internos de la app (evita redirecciones abiertas).
String? destinoSeguro(String? destino) {
  if (destino == null ||
      !destino.startsWith('/') ||
      destino.startsWith('//') ||
      destino.contains('\\')) {
    return null;
  }
  final ruta = Uri.tryParse(destino)?.path;
  if (ruta == null || Rutas.soloSinSesion.contains(ruta)) {
    return null;
  }
  return destino;
}
