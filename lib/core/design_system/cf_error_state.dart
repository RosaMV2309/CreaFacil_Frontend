import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'cf_button.dart';
import 'cf_state_layout.dart';

/// Estado de error con un mensaje claro en español y el botón «Reintentar».
class CfErrorState extends StatelessWidget {
  const CfErrorState({
    this.title = 'Algo salió mal',
    this.message =
        'No pudimos cargar la información. Revisa tu conexión e '
        'inténtalo de nuevo.',
    this.onRetry,
    super.key,
  });

  final String title;
  final String? message;

  /// Si se indica, muestra el botón «Reintentar».
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return CfStateLayout(
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.primario,
      iconBackground: AppColors.secundario.withValues(alpha: 0.45),
      title: title,
      message: message,
      live: true,
      action: onRetry == null
          ? null
          : CfButton(
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
    );
  }
}
