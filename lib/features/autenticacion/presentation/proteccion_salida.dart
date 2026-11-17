import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Comunica al router si una pantalla tiene cambios sin guardar [RNF-05].
///
/// La pantalla registra una consulta al montarse y la libera al desmontarse;
/// el `onExit` de su ruta pregunta [hayCambios] antes de dejarla salir. Así la
/// confirmación cubre todas las salidas: «Cancelar», el botón de volver del
/// encabezado, el botón «Atrás» de Android y el del navegador.
class ProteccionSalida {
  bool Function()? _consulta;

  /// `true` si la pantalla registrada tiene cambios sin guardar.
  bool get hayCambios => _consulta?.call() ?? false;

  void registrar(bool Function() consulta) => _consulta = consulta;

  /// Solo libera la consulta si sigue siendo la registrada (al cambiar de
  /// pantalla, la nueva puede registrarse antes de que la anterior se libere).
  void liberar(bool Function() consulta) {
    if (_consulta == consulta) {
      _consulta = null;
    }
  }
}

/// Protección de salida de «Editar perfil».
final proteccionSalidaPerfilProvider = Provider<ProteccionSalida>(
  (ref) => ProteccionSalida(),
);
