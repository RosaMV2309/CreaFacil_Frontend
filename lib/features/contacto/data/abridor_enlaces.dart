import 'package:url_launcher/url_launcher.dart';

/// Abre enlaces externos (WhatsApp) fuera de la app.
abstract interface class AbridorEnlaces {
  /// Devuelve `false` si no se pudo abrir el enlace.
  Future<bool> abrir(Uri enlace);
}

/// Implementación con url_launcher: en Android abre la app de WhatsApp (o el
/// navegador) y en web una pestaña nueva.
class AbridorEnlacesUrlLauncher implements AbridorEnlaces {
  const AbridorEnlacesUrlLauncher();

  @override
  Future<bool> abrir(Uri enlace) async {
    try {
      return await launchUrl(enlace, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
