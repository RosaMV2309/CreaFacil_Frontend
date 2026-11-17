import 'cambios_perfil.dart';
import 'sesion.dart';
import 'usuario.dart';

/// Datos del formulario de registro que se envían a la API [RF-01].
///
/// La confirmación de la contraseña solo existe en el formulario y no se
/// envía. Tampoco se envía el rol: el registro público siempre crea clientes.
class DatosRegistro {
  const DatosRegistro({
    required this.nombre,
    required this.email,
    required this.password,
    this.telefono,
  });

  final String nombre;
  final String email;
  final String password;

  /// Opcional; `null` si no se indicó.
  final String? telefono;
}

/// Contrato de acceso a la autenticación de la API (`/auth`).
///
/// Las implementaciones lanzan `ApiException` (de `core/network`) cuando la
/// API responde con error.
abstract interface class AutenticacionRepository {
  /// `POST /auth/registro` → 201 con la sesión del nuevo cliente.
  Future<Sesion> registrar(DatosRegistro datos);

  /// `POST /auth/login` → 200 con la sesión.
  Future<Sesion> iniciarSesion({
    required String email,
    required String password,
  });

  /// `GET /auth/perfil` con el [token] indicado → 200 con el usuario.
  Future<Usuario> obtenerPerfil(String token);

  /// `PATCH /auth/perfil` con el token de la sesión → 200 con el usuario
  /// actualizado. Solo envía los campos de [cambios] (RF-01, RN-05).
  Future<Usuario> actualizarPerfil(CambiosPerfil cambios);
}
