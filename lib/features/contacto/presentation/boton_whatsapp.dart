import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/design_system/cf_components.dart';
import '../data/abridor_enlaces.dart';
import '../domain/enlace_whatsapp.dart';

/// Número de WhatsApp configurado con `--dart-define=WHATSAPP_NUMERO`.
final whatsappNumeroProvider = Provider<String>(
  (ref) => AppConfig.whatsappNumero,
);

final abridorEnlacesProvider = Provider<AbridorEnlaces>(
  (ref) => const AbridorEnlacesUrlLauncher(),
);

/// Botón «Escríbenos por WhatsApp» (enlace externo, sin chat propio).
///
/// Si no hay número configurado, el botón queda deshabilitado y se explica
/// el motivo.
class BotonWhatsApp extends ConsumerWidget {
  const BotonWhatsApp({this.expanded = false, super.key});

  static const etiqueta = 'Escríbenos por WhatsApp';
  static const textoSinNumero =
      'El contacto por WhatsApp aún no está configurado.';
  static const textoError =
      'No se pudo abrir WhatsApp. Inténtalo de nuevo más tarde.';

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enlace = enlaceWhatsApp(ref.watch(whatsappNumeroProvider));
    final tokens = CfTokens.of(context);

    final boton = CfButton(
      label: etiqueta,
      icon: Icons.chat_outlined,
      variant: CfButtonVariant.secondary,
      expanded: expanded,
      // Sin número, la explicación va en el texto de debajo.
      tooltip: enlace == null ? null : 'Abre WhatsApp',
      onPressed: enlace == null
          ? null
          : () async {
              final mensajero = ScaffoldMessenger.of(context);
              final abierto = await ref
                  .read(abridorEnlacesProvider)
                  .abrir(enlace);
              if (!abierto) {
                mensajero
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text(textoError)));
              }
            },
    );

    if (enlace != null) {
      return boton;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        boton,
        SizedBox(height: tokens.espacioXs),
        Text(
          textoSinNumero,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
