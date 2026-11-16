import 'usuario.dart';

/// Qué rol puede usar cada aplicación (decisión aprobada de la Fase 1).
///
/// - App móvil: solo `CLIENTE`.
/// - Panel administrativo: solo `ADMIN`.
///
/// Es una comprobación de **navegación**: los permisos reales los verifica
/// siempre el servidor (RNF-03, RN-05).
class PoliticaAcceso {
  const PoliticaAcceso({
    required this.rolPermitido,
    required this.mensajeRechazo,
  });

  final RolUsuario rolPermitido;

  /// Mensaje que se muestra si inicia sesión alguien con otro rol.
  final String mensajeRechazo;

  bool permite(RolUsuario rol) => rol == rolPermitido;
}

/// Las credenciales son correctas, pero el rol no puede usar esta app.
/// La sesión **no** se guarda.
class AccesoRechazadoException implements Exception {
  const AccesoRechazadoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'AccesoRechazadoException: $mensaje';
}
