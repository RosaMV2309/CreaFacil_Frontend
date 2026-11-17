import 'usuario.dart';
import 'validaciones_acceso.dart';

/// Cambios del propio perfil para `PATCH /auth/perfil` [RF-01][RN-05].
///
/// Solo se pueden cambiar el nombre y el teléfono (el correo, el rol y la
/// contraseña no se envían nunca). Se usa un objeto en lugar de parámetros
/// opcionales porque el contrato distingue tres casos para el teléfono, y un
/// parámetro opcional de Dart no diferencia «no indicado» de `null`:
///
/// - [cambiaTelefono] `false`: el teléfono no se envía (no cambia);
/// - [cambiaTelefono] `true` y [telefono] con valor: se cambia;
/// - [cambiaTelefono] `true` y [telefono] `null`: se envía `null` y se borra.
class CambiosPerfil {
  const CambiosPerfil({this.nombre, this.cambiaTelefono = false, this.telefono})
    : assert(
        cambiaTelefono || telefono == null,
        'Si no cambia el teléfono, no se indica uno nuevo',
      );

  /// Solo borra el teléfono.
  const CambiosPerfil.borrarTelefono()
    : nombre = null,
      cambiaTelefono = true,
      telefono = null;

  /// Compara el formulario con los datos [actual]es y deja **solo** lo que
  /// cambió. El nombre se recorta y el teléfono se normaliza igual que en el
  /// servidor (sin espacios, guiones ni paréntesis); si queda vacío y antes
  /// había uno, se borra.
  factory CambiosPerfil.desdeFormulario(
    Usuario actual, {
    required String nombre,
    required String telefono,
  }) {
    final nombreNuevo = nombre.trim();
    final telefonoNuevo = ValidacionesAcceso.normalizarTelefono(telefono);
    final cambiaTelefono = telefonoNuevo != actual.telefono;
    return CambiosPerfil(
      nombre: nombreNuevo == actual.nombre ? null : nombreNuevo,
      cambiaTelefono: cambiaTelefono,
      telefono: cambiaTelefono ? telefonoNuevo : null,
    );
  }

  /// Nombre nuevo o `null` si no cambia.
  final String? nombre;

  /// `true` si el teléfono se envía (para cambiarlo o, con `null`, borrarlo).
  final bool cambiaTelefono;

  /// Teléfono nuevo, ya normalizado; `null` con [cambiaTelefono] lo borra.
  final String? telefono;

  /// `true` si el teléfono se borra.
  bool get borraTelefono => cambiaTelefono && telefono == null;

  /// `false` si no hay nada que enviar (la API exige al menos un campo).
  bool get hayCambios => nombre != null || cambiaTelefono;

  @override
  bool operator ==(Object other) =>
      other is CambiosPerfil &&
      other.nombre == nombre &&
      other.cambiaTelefono == cambiaTelefono &&
      other.telefono == telefono;

  @override
  int get hashCode => Object.hash(nombre, cambiaTelefono, telefono);

  @override
  String toString() =>
      'CambiosPerfil(nombre: $nombre, '
      'telefono: ${cambiaTelefono ? (telefono ?? 'borrar') : 'sin cambios'})';
}
