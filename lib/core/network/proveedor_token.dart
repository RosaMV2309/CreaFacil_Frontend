/// Fuente del token JWT que el [ApiClient] envía en cada petición.
///
/// La implementación real es la de la sesión
/// (`features/autenticacion`, RF-01 y RNF-01): devuelve el token guardado y
/// cierra la sesión cuando la API lo rechaza.
abstract interface class ProveedorToken {
  /// Devuelve el token actual o `null` si no hay sesión.
  Future<String?> obtenerToken();

  /// La API respondió 401 a una petición que **sí** llevaba el token: la
  /// sesión caducó o dejó de ser válida y hay que cerrarla.
  void tokenRechazado();
}

/// Proveedor sin sesión: nunca devuelve un token y las peticiones salen sin
/// cabecera `Authorization`. Es el valor por defecto de
/// `proveedorTokenProvider` hasta que la app conecta el de la sesión.
class ProveedorTokenSinSesion implements ProveedorToken {
  const ProveedorTokenSinSesion();

  @override
  Future<String?> obtenerToken() async => null;

  @override
  void tokenRechazado() {}
}
