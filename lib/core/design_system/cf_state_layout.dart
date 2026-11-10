import 'package:flutter/material.dart';

import '../theme/cf_tokens.dart';

/// Estructura común de [CfEmptyState] y [CfErrorState]: ícono en un círculo,
/// título, mensaje y acción opcional. Uso interno de la librería.
class CfStateLayout extends StatelessWidget {
  const CfStateLayout({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.message,
    this.action,
    this.live = false,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? message;
  final Widget? action;

  /// Anuncia el contenido a los lectores de pantalla al aparecer.
  final bool live;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: live,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: EdgeInsets.all(tokens.espacioXl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: iconColor),
                  ),
                ),
                SizedBox(height: tokens.espacioLg),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textos.titleMedium,
                  ),
                ),
                if (message != null) ...[
                  SizedBox(height: tokens.espacioSm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium,
                  ),
                ],
                if (action != null) ...[
                  SizedBox(height: tokens.espacioXl),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
