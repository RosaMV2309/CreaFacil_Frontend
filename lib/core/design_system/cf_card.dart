import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';

/// Variantes de color de [CfCard].
enum CfCardVariant {
  /// Superficie blanca (por defecto).
  blanca,

  /// Rosa pastel, para destacar contenido secundario.
  pastel,
}

/// Tarjeta de CreaFácil al estilo del Card de PrimeNG: radio de 16 px,
/// borde de 1 px y sombra discreta.
class CfCard extends StatelessWidget {
  const CfCard({
    this.child,
    this.title,
    this.subtitle,
    this.variant = CfCardVariant.blanca,
    this.padding,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget? child;
  final String? title;
  final String? subtitle;
  final CfCardVariant variant;

  /// Relleno interior; por defecto 24 px.
  final EdgeInsetsGeometry? padding;

  /// Si se indica, la tarjeta completa es pulsable.
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final radio = BorderRadius.circular(tokens.radioLg);
    final fondo = variant == CfCardVariant.pastel
        ? AppColors.secundario
        : AppColors.blanco;

    final contenido = Padding(
      padding: padding ?? EdgeInsets.all(tokens.espacioXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Semantics(
              header: true,
              child: Text(title!, style: textos.titleLarge),
            ),
          if (subtitle != null) ...[
            if (title != null) SizedBox(height: tokens.espacioXs),
            Text(subtitle!, style: textos.bodyMedium),
          ],
          if (child != null) ...[
            if (title != null || subtitle != null)
              SizedBox(height: tokens.espacioLg),
            child!,
          ],
        ],
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      button: onTap != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radio,
          boxShadow: tokens.sombra,
        ),
        child: Material(
          color: fondo,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: radio,
            side: const BorderSide(color: AppColors.borde),
          ),
          child: onTap == null
              ? contenido
              : InkWell(onTap: onTap, child: contenido),
        ),
      ),
    );
  }
}
