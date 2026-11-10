import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'cf_state_layout.dart';

/// Estado vacío: se muestra cuando una lista no tiene elementos.
class CfEmptyState extends StatelessWidget {
  const CfEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// Acción opcional, normalmente un `CfButton`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return CfStateLayout(
      icon: icon,
      iconColor: AppColors.complementario,
      iconBackground: AppColors.secundario.withValues(alpha: 0.6),
      title: title,
      message: message,
      action: action,
    );
  }
}
