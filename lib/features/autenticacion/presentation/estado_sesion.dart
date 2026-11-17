import '../domain/sesion.dart';
import '../domain/usuario.dart';

/// Estado de la sesión que publica el `SesionController`.
class EstadoSesion {
  const EstadoSesion({this.sesion, this.aviso});

  /// Sesión iniciada o `null` si no hay.
  final Sesion? sesion;

  /// Aviso pendiente de mostrar en el inicio de sesión (por ejemplo,
  /// «Tu sesión expiró, vuelve a iniciar sesión.»).
  final String? aviso;

  bool get iniciada => sesion != null;
  Usuario? get usuario => sesion?.usuario;

  @override
  bool operator ==(Object other) =>
      other is EstadoSesion && other.sesion == sesion && other.aviso == aviso;

  @override
  int get hashCode => Object.hash(sesion, aviso);

  @override
  String toString() => 'EstadoSesion(${sesion ?? 'sin sesión'}, aviso: $aviso)';
}
