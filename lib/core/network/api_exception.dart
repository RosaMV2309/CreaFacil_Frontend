/// Tipos de error de la API, pensados para decidir qué mostrar en la interfaz.
enum TipoErrorApi {
  /// No se pudo conectar con el servidor (sin red, API apagada o CORS).
  sinConexion,

  /// El servidor tardó demasiado en conectar o en responder.
  tiempoAgotado,

  /// Error del servidor (5xx).
  servidor,

  /// Falta la sesión o no es válida (401).
  noAutorizado,

  /// La sesión no tiene permiso para la acción (403, RN-05).
  prohibido,

  /// El recurso o la ruta no existen (404).
  noEncontrado,

  /// Los datos enviados no son válidos (400, 413 o 422).
  validacion,

  /// Cualquier otro caso.
  desconocido,
}

/// Detalle de un error por campo, tal como lo envía el backend:
/// `{"campo": "…", "ubicacion": "body|query|params", "mensaje": "…"}`.
class DetalleErrorApi {
  const DetalleErrorApi({required this.mensaje, this.campo, this.ubicacion});

  /// Lee un detalle del JSON del backend. Devuelve `null` si no tiene mensaje.
  static DetalleErrorApi? desdeJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final mensaje = json['mensaje'];
    if (mensaje is! String || mensaje.trim().isEmpty) {
      return null;
    }
    final campo = json['campo'];
    final ubicacion = json['ubicacion'];
    return DetalleErrorApi(
      mensaje: mensaje,
      campo: campo is String ? campo : null,
      ubicacion: ubicacion is String ? ubicacion : null,
    );
  }

  /// Campo afectado, por ejemplo `items.0.cantidad`.
  final String? campo;

  /// Parte de la petición: `body`, `query` o `params`.
  final String? ubicacion;

  /// Mensaje en español para la usuaria.
  final String mensaje;

  @override
  String toString() => campo == null ? mensaje : '$campo: $mensaje';
}

/// Error de la API ya traducido para la interfaz [RNF-02].
///
/// [mensaje] siempre está en español y es apto para mostrarse a la usuaria:
/// si el servidor envió un mensaje, se usa ese; si no, uno propio.
class ApiException implements Exception {
  const ApiException({
    required this.tipo,
    required this.codigo,
    required this.mensaje,
    this.estadoHttp,
    this.detalles = const [],
  });

  final TipoErrorApi tipo;

  /// Código estable del backend (`VALIDACION`, `PROHIBIDO`…) o uno propio
  /// del cliente cuando no hubo respuesta (`SIN_CONEXION`, `TIEMPO_AGOTADO`…).
  final String codigo;

  final String mensaje;

  /// Código HTTP de la respuesta, si la hubo.
  final int? estadoHttp;

  /// Errores por campo (por ejemplo, de un formulario).
  final List<DetalleErrorApi> detalles;

  /// Mensajes de error agrupados por campo, útiles para los formularios.
  Map<String, String> get erroresPorCampo => {
    for (final d in detalles)
      if (d.campo != null) d.campo!: d.mensaje,
  };

  @override
  String toString() =>
      'ApiException($codigo, ${estadoHttp ?? 'sin estado'}): $mensaje';
}
