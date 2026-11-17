import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/red.dart';
import '../data/almacen_sesion.dart';
import '../domain/autenticacion_repository.dart';
import '../domain/cambios_perfil.dart';
import '../domain/politica_acceso.dart';
import '../domain/sesion.dart';
import '../domain/usuario.dart';
import 'autenticacion_providers.dart';
import 'estado_sesion.dart';
import 'proveedor_token_sesion.dart';

/// Controlador de la sesión [RF-01][RF-02][RNF-01].
///
/// - Al arrancar restaura la sesión guardada: si caducó la borra; si no, la
///   valida con `GET /auth/perfil` y la borra si la API responde 401.
/// - Inicia sesión o registra y guarda la sesión, **solo** si el rol puede
///   usar esta app ([PoliticaAcceso]).
/// - Actualiza el perfil (`PATCH /auth/perfil`) y la sesión guardada.
/// - Cierra la sesión al caducar el token (8 h, sin renovación) o si la API
///   responde 401 a una petición autenticada, con el aviso
///   [avisoSesionExpirada].
///
/// No decide permisos: el servidor los verifica siempre (RNF-03, RN-05).
class SesionController extends AsyncNotifier<EstadoSesion> {
  static const avisoSesionExpirada =
      'Tu sesión expiró, vuelve a iniciar sesión.';

  Timer? _temporizador;

  AutenticacionRepository get _repositorio =>
      ref.read(autenticacionRepositoryProvider);
  AlmacenSesion get _almacen => ref.read(almacenSesionProvider);
  PoliticaAcceso get _politica => ref.read(politicaAccesoProvider);
  ProveedorTokenSesion get _proveedor => ref.read(proveedorTokenSesionProvider);
  DateTime _ahora() => ref.read(relojProvider)();

  @override
  Future<EstadoSesion> build() async {
    final proveedor = _proveedor;
    proveedor.alRechazar = expirarSesion;
    ref.onDispose(() {
      _temporizador?.cancel();
      proveedor
        ..alRechazar = null
        ..sesion = null;
    });
    return _restaurar();
  }

  Future<EstadoSesion> _restaurar() async {
    final Sesion? guardada;
    try {
      guardada = await _almacen.leer();
    } on Object {
      await _borrarSinFallar();
      return const EstadoSesion();
    }
    if (guardada == null) {
      return const EstadoSesion();
    }
    if (!_politica.permite(guardada.usuario.rol)) {
      await _borrarSinFallar();
      return const EstadoSesion();
    }
    if (guardada.expiradaEn(_ahora())) {
      await _borrarSinFallar();
      return const EstadoSesion(aviso: avisoSesionExpirada);
    }

    try {
      final usuario = await _repositorio.obtenerPerfil(guardada.token);
      if (!_politica.permite(usuario.rol)) {
        await _borrarSinFallar();
        return const EstadoSesion();
      }
      final sesion = guardada.conUsuario(usuario);
      await _guardarSinFallar(sesion);
      _activar(sesion);
      return EstadoSesion(sesion: sesion);
    } on ApiException catch (error) {
      if (error.tipo == TipoErrorApi.noAutorizado ||
          error.tipo == TipoErrorApi.prohibido) {
        await _borrarSinFallar();
        return const EstadoSesion(aviso: avisoSesionExpirada);
      }
      // Sin conexión o error del servidor: se conserva la sesión guardada.
      // La API la volverá a verificar en la próxima petición autenticada.
      _activar(guardada);
      return EstadoSesion(sesion: guardada);
    }
  }

  /// `POST /auth/login`. Lanza `ApiException` si la API lo rechaza y
  /// [AccesoRechazadoException] si el rol no puede usar esta app.
  Future<Sesion> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final sesion = await _repositorio.iniciarSesion(
      email: email,
      password: password,
    );
    return _abrir(sesion);
  }

  /// `POST /auth/registro`: al registrarse, la sesión queda iniciada.
  Future<Sesion> registrar(DatosRegistro datos) async =>
      _abrir(await _repositorio.registrar(datos));

  Future<Sesion> _abrir(Sesion sesion) async {
    if (!_politica.permite(sesion.usuario.rol)) {
      // Credenciales correctas, pero esta app no es para ese rol:
      // la sesión NO se guarda.
      throw AccesoRechazadoException(_politica.mensajeRechazo);
    }
    await _guardarSinFallar(sesion);
    _activar(sesion);
    if (ref.mounted) {
      state = AsyncData(EstadoSesion(sesion: sesion));
    }
    return sesion;
  }

  /// `PATCH /auth/perfil` [RF-01][RN-05]: cambia el nombre o el teléfono de
  /// la persona con la sesión iniciada (el servidor usa siempre la del token).
  ///
  /// Con el 200 actualiza el usuario de la sesión en memoria y en el almacén.
  /// El token y su caducidad no cambian, así que no se pide uno nuevo ni se
  /// reinicia el temporizador. Lanza `ApiException` si la API lo rechaza
  /// (400 con detalles por campo; un 401 además cierra la sesión) y
  /// [StateError] si no hay sesión.
  Future<Usuario> actualizarPerfil(CambiosPerfil cambios) async {
    final actual = _proveedor.sesion;
    if (actual == null) {
      throw StateError('No hay una sesión iniciada');
    }
    if (!cambios.hayCambios) {
      return actual.usuario;
    }
    final usuario = await _repositorio.actualizarPerfil(cambios);
    // Si mientras tanto la sesión se cerró (401, caducidad o cierre), no se
    // vuelve a abrir.
    if (_proveedor.sesion?.token != actual.token) {
      return usuario;
    }
    final sesion = actual.conUsuario(usuario);
    _proveedor.sesion = sesion;
    await _guardarSinFallar(sesion);
    if (ref.mounted) {
      state = AsyncData(EstadoSesion(sesion: sesion));
    }
    return usuario;
  }

  /// Cierra la sesión a petición de la usuaria y borra todo lo guardado.
  Future<void> cerrarSesion() => _cerrar();

  /// Cierra la sesión porque caducó o la API rechazó el token (401).
  /// Si ya no había sesión, no hace nada.
  void expirarSesion() {
    if (_proveedor.sesion == null) {
      return;
    }
    unawaited(_cerrar(aviso: avisoSesionExpirada));
  }

  /// Quita el aviso pendiente (ya se mostró).
  void descartarAviso() {
    final actual = state.value;
    if (actual?.aviso != null) {
      state = AsyncData(EstadoSesion(sesion: actual!.sesion));
    }
  }

  Future<void> _cerrar({String? aviso}) async {
    _temporizador?.cancel();
    _temporizador = null;
    _proveedor.sesion = null;
    if (ref.mounted) {
      state = AsyncData(EstadoSesion(aviso: aviso));
    }
    await _borrarSinFallar();
  }

  void _activar(Sesion sesion) {
    _proveedor.sesion = sesion;
    _temporizador?.cancel();
    final restante = sesion.expiraEn.difference(_ahora());
    _temporizador = Timer(
      restante.isNegative ? Duration.zero : restante,
      expirarSesion,
    );
  }

  Future<void> _guardarSinFallar(Sesion sesion) async {
    try {
      await _almacen.guardar(sesion);
    } on Object {
      // Si el almacén falla, la sesión sigue en memoria hasta cerrar la app.
    }
  }

  Future<void> _borrarSinFallar() async {
    try {
      await _almacen.borrar();
    } on Object {
      // Nada más que hacer: la sesión ya no está en memoria.
    }
  }
}
