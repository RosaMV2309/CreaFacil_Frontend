import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Indicador de carga al estilo del ProgressSpinner de PrimeNG.
class CfSpinner extends StatelessWidget {
  const CfSpinner({this.size = 40, this.label, super.key});

  /// Diámetro del indicador en píxeles.
  final double size;

  /// Texto opcional bajo el indicador (por ejemplo, «Cargando servicios…»).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final indicador = SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: size >= 32 ? 4 : 2.5,
        color: AppColors.primario,
        backgroundColor: AppColors.secundario.withValues(alpha: 0.5),
        strokeCap: StrokeCap.round,
      ),
    );

    return Semantics(
      label: label ?? 'Cargando',
      liveRegion: true,
      excludeSemantics: true,
      child: label == null
          ? indicador
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                indicador,
                const SizedBox(height: 12),
                Text(
                  label!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
    );
  }
}
