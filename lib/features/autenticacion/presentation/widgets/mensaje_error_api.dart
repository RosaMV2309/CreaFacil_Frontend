import '../../../../core/network/red.dart';

/// Título y texto de un error de acceso para mostrarlo en un `CfMessage`.
///
/// El texto es siempre el mensaje en español que envía el servidor (por
/// ejemplo, «Correo o contraseña incorrectos.» o el tiempo de espera del 429).
class MensajeErrorApi {
  const MensajeErrorApi({required this.texto, this.titulo, this.codigo});

  /// Rechazo por rol (la cuenta existe, pero no puede usar esta app).
  factory MensajeErrorApi.rechazo(String texto) => MensajeErrorApi(
    titulo: 'Acceso no permitido',
    texto: texto,
    codigo: 'ROL_NO_PERMITIDO',
  );

  factory MensajeErrorApi.desde(ApiException error) => MensajeErrorApi(
    titulo: switch (error.codigo) {
      'DEMASIADOS_INTENTOS' => 'Demasiados intentos',
      'CUENTA_DESACTIVADA' => 'Cuenta desactivada',
      'CONFLICTO' => 'Correo ya registrado',
      'VALIDACION' => 'Revisa los datos',
      _ => switch (error.tipo) {
        TipoErrorApi.sinConexion => 'Sin conexión',
        TipoErrorApi.tiempoAgotado => 'Sin respuesta',
        _ => null,
      },
    },
    texto: error.mensaje,
    codigo: error.codigo,
  );

  final String? titulo;
  final String texto;
  final String? codigo;
}
