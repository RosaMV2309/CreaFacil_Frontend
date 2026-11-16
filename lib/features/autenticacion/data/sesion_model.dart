import '../domain/sesion.dart';
import '../domain/usuario.dart';

/// Conversión JSON ⇄ entidades de la autenticación.
///
/// La forma es la del contrato de la API:
/// `{ token, tipo, expiraEn, usuario: { id, nombre, email, telefono, rol } }`.
/// También se usa para guardar la sesión en el dispositivo.
abstract final class SesionModel {
  /// Lee la sesión. Lanza [FormatException] si falta o sobra algo esencial.
  static Sesion desdeJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('La sesión no es un objeto JSON');
    }
    final token = json['token'];
    final expiraEn = json['expiraEn'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('Falta el token');
    }
    final fecha = expiraEn is String ? DateTime.tryParse(expiraEn) : null;
    if (fecha == null) {
      throw const FormatException('Falta la fecha de caducidad');
    }
    return Sesion(
      token: token,
      expiraEn: fecha.toUtc(),
      usuario: usuarioDesdeJson(json['usuario']),
    );
  }

  static Map<String, Object?> aJson(Sesion sesion) => {
    'token': sesion.token,
    'tipo': 'Bearer',
    'expiraEn': sesion.expiraEn.toUtc().toIso8601String(),
    'usuario': usuarioAJson(sesion.usuario),
  };

  static Usuario usuarioDesdeJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Falta el usuario');
    }
    final id = json['id'];
    final nombre = json['nombre'];
    final email = json['email'];
    final telefono = json['telefono'];
    final rol = RolUsuario.desdeApi(json['rol']);
    if (id is! String || nombre is! String || email is! String) {
      throw const FormatException('Datos del usuario incompletos');
    }
    if (rol == null) {
      throw const FormatException('Rol desconocido');
    }
    return Usuario(
      id: id,
      nombre: nombre,
      email: email,
      telefono: telefono is String && telefono.isNotEmpty ? telefono : null,
      rol: rol,
    );
  }

  static Map<String, Object?> usuarioAJson(Usuario usuario) => {
    'id': usuario.id,
    'nombre': usuario.nombre,
    'email': usuario.email,
    'telefono': usuario.telefono,
    'rol': usuario.rol.valorApi,
  };
}
