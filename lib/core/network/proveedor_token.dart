/// Fuente del token JWT que el [ApiClient] envía en cada petición.
///
/// TODO(Fase 1, RF-01 y RF-02): implementar con el token de la sesión
/// (flutter_secure_storage en móvil y el almacenamiento disponible en web).
abstract interface class ProveedorToken {
  /// Devuelve el token actual o `null` si no hay sesión.
  Future<String?> obtenerToken();
}

/// Proveedor de la Fase 0: todavía no hay inicio de sesión, así que nunca
/// devuelve un token y las peticiones salen sin cabecera `Authorization`.
class ProveedorTokenSinSesion implements ProveedorToken {
  const ProveedorTokenSinSesion();

  @override
  Future<String?> obtenerToken() async => null;
}
