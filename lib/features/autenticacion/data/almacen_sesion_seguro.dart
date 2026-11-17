import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'almacen_sesion.dart';

/// Sesión guardada con `flutter_secure_storage` (solo app móvil) [RNF-01].
///
/// - Android: cifrada con claves del Android Keystore.
/// - Web: cifrada con WebCrypto (AES-GCM) en el almacenamiento local del
///   navegador. No protege frente a un XSS, pero el servidor verifica siempre
///   el JWT y el rol, y el token caduca a las 8 horas.
class AlmacenSesionSeguro extends AlmacenSesionTexto {
  AlmacenSesionSeguro([FlutterSecureStorage? almacen])
    : _almacen = almacen ?? const FlutterSecureStorage();

  final FlutterSecureStorage _almacen;

  @override
  Future<String?> leerTexto(String clave) => _almacen.read(key: clave);

  @override
  Future<void> escribirTexto(String clave, String valor) =>
      _almacen.write(key: clave, value: valor);

  @override
  Future<void> borrarTexto(String clave) => _almacen.delete(key: clave);
}
