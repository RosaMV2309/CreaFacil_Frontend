import 'dart:convert';

import '../domain/sesion.dart';
import 'sesion_model.dart';

/// Dónde se guarda la sesión en el dispositivo [RNF-01].
///
/// Abstracción inyectable: la app móvil usa `flutter_secure_storage` y el
/// panel web `shared_preferences`; las pruebas usan un almacén en memoria.
abstract interface class AlmacenSesion {
  /// La sesión guardada o `null` si no hay (o si está dañada).
  Future<Sesion?> leer();

  Future<void> guardar(Sesion sesion);

  /// Borra todo lo guardado de la sesión.
  Future<void> borrar();
}

/// Base para almacenes de clave y valor de texto: guarda la sesión como un
/// único JSON bajo [clave]. Las subclases solo adaptan el paquete concreto.
abstract class AlmacenSesionTexto implements AlmacenSesion {
  static const clave = 'creafacil.sesion';

  Future<String?> leerTexto(String clave);
  Future<void> escribirTexto(String clave, String valor);
  Future<void> borrarTexto(String clave);

  @override
  Future<Sesion?> leer() async {
    final texto = await leerTexto(clave);
    if (texto == null || texto.isEmpty) {
      return null;
    }
    try {
      return SesionModel.desdeJson(jsonDecode(texto));
    } on FormatException {
      // Datos dañados o de una versión anterior: se descartan.
      await borrarTexto(clave);
      return null;
    }
  }

  @override
  Future<void> guardar(Sesion sesion) =>
      escribirTexto(clave, jsonEncode(SesionModel.aJson(sesion)));

  @override
  Future<void> borrar() => borrarTexto(clave);
}
