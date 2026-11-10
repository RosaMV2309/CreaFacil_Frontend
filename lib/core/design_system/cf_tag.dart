import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';

/// Severidades de [CfTag], todas dentro de la paleta oficial.
enum CfTagSeverity {
  /// Rosa pastel con texto principal (marca).
  primary,

  /// Azul artesanal tenue: información.
  info,

  /// Azul artesanal con texto blanco: éxito o estado completado.
  success,

  /// Crema con acento dorado: aviso o estado pendiente.
  warning,

  /// Borde e ícono coral: error, cancelado o peligro.
  danger,

  /// Crema con borde suave: estado neutro.
  neutral,
}

/// Etiqueta de estado al estilo del Tag de PrimeNG. Se usará para los
/// estados de cotización y pedido. El dorado solo aparece como acento.
class CfTag extends StatelessWidget {
  const CfTag({
    required this.label,
    this.severity = CfTagSeverity.neutral,
    this.icon,
    this.rounded = false,
    super.key,
  });

  final String label;
  final CfTagSeverity severity;
  final IconData? icon;

  /// Bordes totalmente redondeados (píldora).
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final ({Color fondo, Color texto, Color borde, Color icono}) c =
        switch (severity) {
          CfTagSeverity.primary => (
            fondo: AppColors.secundario,
            texto: AppColors.texto,
            borde: AppColors.secundario,
            icono: AppColors.texto,
          ),
          CfTagSeverity.info => (
            fondo: AppColors.complementario.withValues(alpha: 0.08),
            texto: AppColors.complementario,
            borde: AppColors.complementario.withValues(alpha: 0.3),
            icono: AppColors.complementario,
          ),
          CfTagSeverity.success => (
            fondo: AppColors.complementario,
            texto: AppColors.blanco,
            borde: AppColors.complementario,
            icono: AppColors.blanco,
          ),
          CfTagSeverity.warning => (
            fondo: AppColors.fondo,
            texto: AppColors.texto,
            borde: AppColors.terciario,
            icono: AppColors.texto,
          ),
          CfTagSeverity.danger => (
            fondo: AppColors.blanco,
            texto: AppColors.texto,
            borde: AppColors.primario,
            icono: AppColors.primario,
          ),
          CfTagSeverity.neutral => (
            fondo: AppColors.fondo,
            texto: AppColors.texto,
            borde: AppColors.borde,
            icono: AppColors.texto,
          ),
        };

    final estilo = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: c.texto);

    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 26),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.espacioSm + 2,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: c.fondo,
          border: Border.all(color: c.borde),
          borderRadius: BorderRadius.circular(rounded ? 999 : tokens.radioSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (severity == CfTagSeverity.warning && icon == null) ...[
              // Acento dorado decorativo, nunca como color de texto.
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.terciario,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[
              Icon(icon, size: 14, color: c.icono),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                style: estilo,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
