/// Rutas de la aplicación (go_router).
abstract final class Rutas {
  static const inicio = '/';

  /// Inicio de sesión del cliente (RF-01).
  static const acceso = '/acceso';

  /// Crear cuenta de cliente (RF-01).
  static const registro = '/registro';

  /// Perfil del cliente. Exige sesión (RF-01, RF-02).
  static const perfil = '/perfil';

  /// Editar el nombre y el teléfono. Exige sesión (RF-01, RN-05).
  static const perfilEditar = '/perfil/editar';

  /// Catálogo de componentes Cf*. Solo existe en modo debug.
  static const componentes = '/dev/componentes';

  /// Rutas que exigen la sesión iniciada.
  static const protegidas = {perfil, perfilEditar};

  /// Rutas que no tienen sentido con la sesión iniciada.
  static const soloSinSesion = {acceso, registro};

  /// Parámetro de consulta con el destino al que volver tras iniciar sesión.
  static const parametroDesde = 'desde';

  /// `/acceso?desde=<destino>` (o `/acceso` si no hay destino).
  static String accesoDesde(String? destino) => destino == null
      ? acceso
      : Uri(
          path: acceso,
          queryParameters: {parametroDesde: destino},
        ).toString();
}
