/// Roles que devuelve la API: `ADMIN` o `CLIENTE` [RF-02].
enum RolUsuario {
  admin('ADMIN', 'Administradora'),
  cliente('CLIENTE', 'Cliente');

  const RolUsuario(this.valorApi, this.etiqueta);

  /// Valor exacto del contrato de la API.
  final String valorApi;

  /// Texto para la interfaz, en español.
  final String etiqueta;

  /// Lee el rol del JSON de la API; `null` si no es un rol conocido.
  static RolUsuario? desdeApi(Object? valor) {
    for (final rol in values) {
      if (rol.valorApi == valor) {
        return rol;
      }
    }
    return null;
  }
}

/// Usuario autenticado, tal como lo devuelve la API (`usuario`) [RF-01].
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
  });

  /// UUID del usuario (texto).
  final String id;
  final String nombre;
  final String email;

  /// Teléfono normalizado o `null` si no lo indicó.
  final String? telefono;
  final RolUsuario rol;

  bool get esAdmin => rol == RolUsuario.admin;
  bool get esCliente => rol == RolUsuario.cliente;

  @override
  bool operator ==(Object other) =>
      other is Usuario &&
      other.id == id &&
      other.nombre == nombre &&
      other.email == email &&
      other.telefono == telefono &&
      other.rol == rol;

  @override
  int get hashCode => Object.hash(id, nombre, email, telefono, rol);

  @override
  String toString() => 'Usuario($email, ${rol.valorApi})';
}
