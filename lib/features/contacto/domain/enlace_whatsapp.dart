/// Construye el enlace externo de WhatsApp `https://wa.me/<numero>`.
///
/// CreaFácil no tiene chat propio (fuera del alcance del DERCAS): el contacto
/// directo con el negocio se hace por WhatsApp.
///
/// Se quedan solo los dígitos del número (se admiten `+`, espacios o guiones
/// al configurarlo). Devuelve `null` si no hay número.
Uri? enlaceWhatsApp(String numero) {
  final digitos = numero.replaceAll(RegExp(r'\D'), '');
  if (digitos.isEmpty) {
    return null;
  }
  return Uri.https('wa.me', '/$digitos');
}
