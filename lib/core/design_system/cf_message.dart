import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';

/// Severidades de [CfMessage]. No salen de la paleta:
/// información y éxito en azul, aviso con acento dorado y error en coral.
enum CfMessageSeverity { info, success, warning, error }

/// Mensaje en línea al estilo del Message de PrimeNG.
class CfMessage extends StatelessWidget {
  const CfMessage({
    required this.text,
    this.title,
    this.severity = CfMessageSeverity.info,
    this.onClose,
    super.key,
  });

  final String text;
  final String? title;
  final CfMessageSeverity severity;

  /// Si se indica, muestra un botón «Cerrar».
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final ({Color fondo, Color acento, Color icono, IconData simbolo}) c =
        switch (severity) {
          CfMessageSeverity.info => (
            fondo: AppColors.fondo,
            acento: AppColors.complementario,
            icono: AppColors.complementario,
            simbolo: Icons.info_outline_rounded,
          ),
          CfMessageSeverity.success => (
            fondo: AppColors.complementario.withValues(alpha: 0.08),
            acento: AppColors.complementario,
            icono: AppColors.complementario,
            simbolo: Icons.check_circle_outline_rounded,
          ),
          CfMessageSeverity.warning => (
            fondo: AppColors.terciario.withValues(alpha: 0.14),
            acento: AppColors.terciario,
            icono: AppColors.texto,
            simbolo: Icons.warning_amber_rounded,
          ),
          CfMessageSeverity.error => (
            fondo: AppColors.secundario.withValues(alpha: 0.35),
            acento: AppColors.primario,
            icono: AppColors.primario,
            simbolo: Icons.error_outline_rounded,
          ),
        };

    final prefijo = switch (severity) {
      CfMessageSeverity.info => 'Información',
      CfMessageSeverity.success => 'Éxito',
      CfMessageSeverity.warning => 'Aviso',
      CfMessageSeverity.error => 'Error',
    };

    return Semantics(
      container: true,
      liveRegion: true,
      label: prefijo,
      child: Container(
        decoration: BoxDecoration(
          color: c.fondo,
          borderRadius: BorderRadius.circular(tokens.radioMd),
          border: Border.all(color: c.acento.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: c.acento),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.espacioMd,
                    tokens.espacioMd,
                    onClose == null ? tokens.espacioLg : 0,
                    tokens.espacioMd,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Icon(c.simbolo, color: c.icono, size: 22),
                      ),
                      SizedBox(width: tokens.espacioMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Text(title!, style: textos.titleSmall),
                            Text(text, style: textos.bodyMedium),
                          ],
                        ),
                      ),
                      if (onClose != null)
                        IconButton(
                          onPressed: onClose,
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: AppColors.texto,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
