import '../../../core/network/proveedor_token.dart';
import '../domain/sesion.dart';

/// [ProveedorToken] real: entrega el token de la sesión activa al
/// `ApiClient` y avisa al `SesionController` cuando hay que cerrarla
/// [RF-01][RNF-01].
///
/// Es un objeto sencillo (sin depender del controlador) para evitar ciclos
/// entre providers: el controlador le asigna [sesion] y [alRechazar].
class ProveedorTokenSesion implements ProveedorToken {
  ProveedorTokenSesion({DateTime Function()? reloj})
    : _reloj = reloj ?? DateTime.now;

  final DateTime Function() _reloj;

  /// Sesión activa (la asigna el controlador).
  Sesion? sesion;

  /// Qué hacer si el token caducó o la API lo rechazó (cerrar la sesión).
  void Function()? alRechazar;

  @override
  Future<String?> obtenerToken() async {
    final actual = sesion;
    if (actual == null) {
      return null;
    }
    if (actual.expiradaEn(_reloj())) {
      // Caducó: no se envía y se cierra la sesión con el aviso.
      tokenRechazado();
      return null;
    }
    return actual.token;
  }

  @override
  void tokenRechazado() => alRechazar?.call();
}
