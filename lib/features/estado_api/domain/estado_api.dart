/// Estado general que informa la API en `GET /health`.
enum EstadoServicio {
  /// La API y sus dependencias funcionan.
  ok,

  /// La API responde, pero alguna dependencia (la base de datos) falla.
  degradado,
}

/// Estado de la base de datos según la API.
enum EstadoBaseDatos { ok, error }

/// Entidad del estado de la API [RNF-04][RNF-07].
class EstadoApi {
  const EstadoApi({
    required this.estado,
    required this.servicio,
    required this.version,
    required this.entorno,
    this.marcaTiempo,
    this.tiempoActividadSegundos,
    this.baseDatos,
  });

  final EstadoServicio estado;
  final String servicio;
  final String version;
  final String entorno;
  final DateTime? marcaTiempo;
  final int? tiempoActividadSegundos;

  /// `null` si la API todavía no informa del estado de la base de datos.
  final EstadoBaseDatos? baseDatos;

  /// La API responde pero la base de datos tiene problemas.
  bool get baseDatosConProblemas =>
      estado == EstadoServicio.degradado || baseDatos == EstadoBaseDatos.error;
}
