import 'package:dio/dio.dart';

import '../../../core/network/red.dart';
import '../domain/autenticacion_repository.dart';
import '../domain/cambios_perfil.dart';
import '../domain/sesion.dart';
import '../domain/usuario.dart';
import '../domain/validaciones_acceso.dart';
import 'sesion_model.dart';

/// Autenticación contra la API REST de CreaFácil [RF-01][RNF-04].
///
/// Contrato (subfase 1.1 del backend):
/// - `POST /auth/registro` `{nombre, email, password, telefono?}` → 201
/// - `POST /auth/login` `{email, password}` → 200
/// - `GET /auth/perfil` con `Authorization: Bearer <token>` → 200 `{usuario}`
/// - `PATCH /auth/perfil` `{nombre?, telefono?}` (subfase 1.2; `telefono: null`
///   lo borra) → 200 `{usuario}`
///
/// Los errores llegan como [ApiException] (400 VALIDACION con detalles,
/// 401, 403 CUENTA_DESACTIVADA, 409 CONFLICTO, 429 DEMASIADOS_INTENTOS…).
class AutenticacionRepositoryImpl implements AutenticacionRepository {
  AutenticacionRepositoryImpl(this._api);

  final ApiClient _api;

  static const rutaRegistro = '/auth/registro';
  static const rutaLogin = '/auth/login';
  static const rutaPerfil = '/auth/perfil';

  /// Error si el servidor responde con una forma que no es la del contrato.
  static const respuestaInvalida = ApiException(
    tipo: TipoErrorApi.desconocido,
    codigo: 'RESPUESTA_INVALIDA',
    mensaje:
        'El servidor envió una respuesta inesperada. Inténtalo de nuevo más '
        'tarde.',
  );

  @override
  Future<Sesion> registrar(DatosRegistro datos) async {
    final telefono = ValidacionesAcceso.normalizarTelefono(datos.telefono);
    final respuesta = await _api.post(
      rutaRegistro,
      datos: {
        'nombre': datos.nombre.trim(),
        'email': datos.email.trim(),
        'password': datos.password,
        'telefono': ?telefono,
      },
    );
    return _leer(() => SesionModel.desdeJson(respuesta.data));
  }

  @override
  Future<Sesion> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final respuesta = await _api.post(
      rutaLogin,
      datos: {'email': email.trim(), 'password': password},
    );
    return _leer(() => SesionModel.desdeJson(respuesta.data));
  }

  @override
  Future<Usuario> obtenerPerfil(String token) async {
    final respuesta = await _api.get(
      rutaPerfil,
      opciones: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return _leerUsuario(respuesta.data);
  }

  /// El token lo añade `InterceptorToken` (es el de la sesión): si la API
  /// responde 401, la sesión se cierra como en cualquier petición autenticada.
  @override
  Future<Usuario> actualizarPerfil(CambiosPerfil cambios) async {
    final respuesta = await _api.patch(
      rutaPerfil,
      datos: <String, Object?>{
        'nombre': ?cambios.nombre,
        if (cambios.cambiaTelefono) 'telefono': cambios.telefono,
      },
    );
    return _leerUsuario(respuesta.data);
  }

  Usuario _leerUsuario(Object? cuerpo) => _leer(
    () =>
        SesionModel.usuarioDesdeJson(cuerpo is Map ? cuerpo['usuario'] : null),
  );

  T _leer<T>(T Function() conversion) {
    try {
      return conversion();
    } on FormatException {
      throw respuestaInvalida;
    }
  }
}
