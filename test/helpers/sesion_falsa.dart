import 'package:creafacil_app/core/network/red.dart';
import 'package:creafacil_app/features/autenticacion/data/almacen_sesion.dart';
import 'package:creafacil_app/features/autenticacion/domain/autenticacion_repository.dart';
import 'package:creafacil_app/features/autenticacion/domain/sesion.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/presentation/autenticacion_providers.dart';
import 'package:flutter_riverpod/misc.dart';

/// Instante fijo de las pruebas de sesión.
final ahoraPrueba = DateTime.utc(2026, 11, 14, 12);

const clientePrueba = Usuario(
  id: '7d0c4c1e-1111-4a2b-9c3d-000000000001',
  nombre: 'Ana Pérez',
  email: 'ana@app.creafacil.test',
  telefono: '+593991234567',
  rol: RolUsuario.cliente,
);

const adminPrueba = Usuario(
  id: '7d0c4c1e-1111-4a2b-9c3d-000000000002',
  nombre: 'Rosalía',
  email: 'admin@creafacil.test',
  rol: RolUsuario.admin,
);

Sesion sesionPrueba({
  Usuario usuario = clientePrueba,
  Duration vigencia = const Duration(hours: 8),
  String token = 'eyJhbGciOiJIUzI1NiJ9.prueba.firma',
}) =>
    Sesion(token: token, expiraEn: ahoraPrueba.add(vigencia), usuario: usuario);

/// JSON de la API para una sesión (201 del registro o 200 del login).
Map<String, Object?> cuerpoSesion({
  Usuario usuario = clientePrueba,
  String token = 'eyJhbGciOiJIUzI1NiJ9.prueba.firma',
  String expiraEn = '2026-11-14T20:00:00.000Z',
}) => {
  'token': token,
  'tipo': 'Bearer',
  'expiraEn': expiraEn,
  'usuario': cuerpoUsuario(usuario),
};

Map<String, Object?> cuerpoUsuario(Usuario usuario) => {
  'id': usuario.id,
  'nombre': usuario.nombre,
  'email': usuario.email,
  'telefono': usuario.telefono,
  'rol': usuario.rol.valorApi,
};

/// Error de la API con la forma real del backend.
ApiException errorApi(
  int estado,
  String codigo,
  String mensaje, [
  List<Map<String, String>> detalles = const [],
]) => ConversorErrores.desdeRespuesta(estado, {
  'error': {'codigo': codigo, 'mensaje': mensaje, 'detalles': detalles},
});

/// Almacén de sesión en memoria.
class AlmacenSesionMemoria implements AlmacenSesion {
  AlmacenSesionMemoria([this.sesion]);

  Sesion? sesion;
  bool fallarAlLeer = false;
  bool fallarAlEscribir = false;
  int guardados = 0;
  int borrados = 0;

  @override
  Future<Sesion?> leer() async {
    if (fallarAlLeer) {
      throw StateError('almacén dañado');
    }
    return sesion;
  }

  @override
  Future<void> guardar(Sesion nueva) async {
    if (fallarAlEscribir) {
      throw StateError('sin espacio');
    }
    guardados++;
    sesion = nueva;
  }

  @override
  Future<void> borrar() async {
    if (fallarAlEscribir) {
      throw StateError('sin espacio');
    }
    borrados++;
    sesion = null;
  }
}

/// Repositorio de autenticación falso y configurable.
class RepositorioAutenticacionFalso implements AutenticacionRepository {
  Future<Sesion> Function(String email, String password) alIniciar = (
    _,
    _,
  ) async => sesionPrueba();
  Future<Sesion> Function(DatosRegistro datos) alRegistrar = (_) async =>
      sesionPrueba();
  Future<Usuario> Function(String token) alPerfil = (_) async => clientePrueba;

  final llamadas = <String>[];
  DatosRegistro? ultimoRegistro;

  @override
  Future<Sesion> iniciarSesion({
    required String email,
    required String password,
  }) {
    llamadas.add('login:$email');
    return alIniciar(email, password);
  }

  @override
  Future<Sesion> registrar(DatosRegistro datos) {
    llamadas.add('registro:${datos.email}');
    ultimoRegistro = datos;
    return alRegistrar(datos);
  }

  @override
  Future<Usuario> obtenerPerfil(String token) {
    llamadas.add('perfil');
    return alPerfil(token);
  }
}

/// Overrides de la sesión para montar la app sin red ni plugins.
List<Override> sesionSimulada({
  AlmacenSesion? almacen,
  AutenticacionRepository? repositorio,
  DateTime Function()? reloj,
}) => [
  ...overridesAutenticacion,
  almacenSesionProvider.overrideWithValue(almacen ?? AlmacenSesionMemoria()),
  autenticacionRepositoryProvider.overrideWithValue(
    repositorio ?? RepositorioAutenticacionFalso(),
  ),
  relojProvider.overrideWithValue(reloj ?? () => ahoraPrueba),
];
