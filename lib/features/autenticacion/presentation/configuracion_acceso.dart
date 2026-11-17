import '../data/almacen_sesion.dart';
import '../data/almacen_sesion_seguro.dart';
import '../domain/politica_acceso.dart';
import '../domain/usuario.dart';

// ÚNICO archivo de `domain`, `data` (salvo el almacén concreto) y del
// controlador de `features/autenticacion` que es distinto en
// CreaFacil_Frontend y CreaFacil_AdminWeb. El resto es idéntico.

/// La app móvil es solo para clientes (decisión aprobada de la Fase 1).
const politicaAccesoDeLaApp = PoliticaAcceso(
  rolPermitido: RolUsuario.cliente,
  mensajeRechazo: 'Esta app es para clientes. Usa el panel administrativo.',
);

/// En la app móvil la sesión se guarda con `flutter_secure_storage`.
AlmacenSesion crearAlmacenSesionDeLaApp() => AlmacenSesionSeguro();
