import '../domain/estado_api.dart';

/// Modelo de la respuesta de `GET /health`.
///
/// Es tolerante: `baseDatos` es opcional (llega con la subfase 0.4 del
/// backend) y los campos desconocidos se ignoran.
abstract final class EstadoApiModel {
  /// `true` si el JSON tiene la forma de una respuesta de health.
  static bool esRespuestaDeSalud(Object? json) =>
      json is Map && json['estado'] is String;

  /// Convierte el JSON de la API en [EstadoApi].
  ///
  /// Lanza [FormatException] si no es una respuesta de health.
  static EstadoApi fromJson(Object? json) {
    if (json is! Map || !esRespuestaDeSalud(json)) {
      throw const FormatException('La respuesta de /health no es válida.');
    }
    final estado = json['estado'] == 'ok'
        ? EstadoServicio.ok
        : EstadoServicio.degradado;
    final baseDatos = switch (json['baseDatos']) {
      'ok' => EstadoBaseDatos.ok,
      'error' => EstadoBaseDatos.error,
      _ => null,
    };
    final marca = json['marcaTiempo'];
    final actividad = json['tiempoActividadSegundos'];

    return EstadoApi(
      estado: estado,
      servicio: _texto(json['servicio'], 'CreaFácil API'),
      version: _texto(json['version'], 'desconocida'),
      entorno: _texto(json['entorno'], 'desconocido'),
      marcaTiempo: marca is String ? DateTime.tryParse(marca) : null,
      tiempoActividadSegundos: actividad is num ? actividad.toInt() : null,
      baseDatos: baseDatos,
    );
  }

  static String _texto(Object? valor, String porDefecto) =>
      valor is String && valor.trim().isNotEmpty ? valor : porDefecto;
}
