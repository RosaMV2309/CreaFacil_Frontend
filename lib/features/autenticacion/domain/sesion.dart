import 'usuario.dart';

/// Sesión iniciada: token JWT, fecha de caducidad y usuario [RF-01][RNF-01].
///
/// El token dura 8 horas y no se renueva: al caducar (o si la API responde
/// 401) la sesión se cierra y hay que volver a iniciarla.
class Sesion {
  const Sesion({
    required this.token,
    required this.expiraEn,
    required this.usuario,
  });

  final String token;

  /// Fecha de caducidad del token, en UTC (`expiraEn` de la API).
  final DateTime expiraEn;
  final Usuario usuario;

  /// `true` si en el instante [ahora] el token ya no es válido.
  bool expiradaEn(DateTime ahora) => !ahora.isBefore(expiraEn);

  /// Misma sesión con los datos del usuario actualizados (por ejemplo, tras
  /// validar la sesión con `GET /auth/perfil`).
  Sesion conUsuario(Usuario nuevo) =>
      Sesion(token: token, expiraEn: expiraEn, usuario: nuevo);

  /// Token enmascarado para registros y depuración: nunca se muestra entero.
  String get tokenEnmascarado =>
      token.length <= 8 ? '****' : '${token.substring(0, 4)}…(oculto)';

  @override
  bool operator ==(Object other) =>
      other is Sesion &&
      other.token == token &&
      other.expiraEn.isAtSameMomentAs(expiraEn) &&
      other.usuario == usuario;

  @override
  int get hashCode =>
      Object.hash(token, expiraEn.millisecondsSinceEpoch, usuario);

  @override
  String toString() =>
      'Sesion($usuario, token: $tokenEnmascarado, expira: '
      '${expiraEn.toIso8601String()})';
}
