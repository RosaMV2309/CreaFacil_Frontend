import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Variantes del logotipo de CreaFácil.
enum CfLogoVariant {
  /// Logotipo completo: ilustración y banda con «CreaFácil» y «HECHO A MANO».
  completo,

  /// Solo la ilustración recortada, para encabezados y espacios pequeños.
  icono,
}

/// Logotipo de CreaFácil [RNF-05].
///
/// Muestra la imagen de `assets/images/` según la [variant]. Si la imagen no
/// se puede cargar, usa como respaldo la marca de texto [CfMarcaTexto].
/// Para los lectores de pantalla siempre se anuncia como «CreaFácil».
class CfLogo extends StatelessWidget {
  const CfLogo({
    this.variant = CfLogoVariant.completo,
    this.size = 160,
    super.key,
  });

  static const assetCompleto = 'assets/images/logo.png';
  static const assetIcono = 'assets/images/logo_icono.png';
  static const etiqueta = 'CreaFácil';

  final CfLogoVariant variant;

  /// Lado del cuadrado que ocupa el logotipo (ambas imágenes son cuadradas).
  final double size;

  String get asset => switch (variant) {
    CfLogoVariant.completo => assetCompleto,
    CfLogoVariant.icono => assetIcono,
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: etiqueta,
      image: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Center(
            child: CfMarcaTexto(
              size: size * 0.2,
              showAccent: variant == CfLogoVariant.completo,
            ),
          ),
        ),
      ),
    );
  }
}

/// Marca de texto «CreaFácil» en Poppins coral con un acento dorado
/// decorativo. Es el respaldo de [CfLogo] cuando la imagen no carga.
class CfMarcaTexto extends StatelessWidget {
  const CfMarcaTexto({this.size = 36, this.showAccent = true, super.key});

  /// Tamaño de la letra de la marca. Como mínimo 24 px, para que el coral
  /// sobre fondos claros cumpla el contraste de texto grande (WCAG AA).
  final double size;

  /// Muestra el acento dorado decorativo (destello y subrayado).
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final tamano = size < 24 ? 24.0 : size;
    final marca = Text(
      CfLogo.etiqueta,
      maxLines: 1,
      style: TextStyle(
        fontFamily: AppTipografia.titulos,
        fontSize: tamano,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: AppColors.primario,
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(right: tamano * 0.45),
                child: marca,
              ),
              if (showAccent)
                Positioned(
                  right: 0,
                  top: -tamano * 0.05,
                  child: Icon(
                    Icons.auto_awesome,
                    size: tamano * 0.5,
                    color: AppColors.terciario,
                  ),
                ),
            ],
          ),
          if (showAccent)
            Padding(
              padding: EdgeInsets.only(right: tamano * 0.45),
              child: Container(
                width: tamano * 1.6,
                height: tamano * 0.12,
                decoration: BoxDecoration(
                  color: AppColors.terciario,
                  borderRadius: BorderRadius.circular(tamano),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Marca para encabezados (AppBar o cabecera del panel): la ilustración del
/// logotipo en un círculo blanco junto al nombre «CreaFácil».
///
/// Pensada para el AppBar azul artesanal: el nombre se pinta con el color de
/// primer plano del AppBar (blanco sobre azul, contraste ≈ 9,6:1).
class CfMarcaEncabezado extends StatelessWidget {
  const CfMarcaEncabezado({this.iconSize = 36, super.key});

  /// Diámetro del círculo con la ilustración.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final estilo =
        (tema.appBarTheme.titleTextStyle ?? tema.textTheme.titleLarge)
            ?.copyWith(
              fontFamily: AppTipografia.titulos,
              fontWeight: FontWeight.w700,
            );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          padding: EdgeInsets.all(iconSize * 0.06),
          decoration: const BoxDecoration(
            color: AppColors.blanco,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: CfLogo(variant: CfLogoVariant.icono, size: iconSize),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: ExcludeSemantics(
            child: Text(
              CfLogo.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estilo,
            ),
          ),
        ),
      ],
    );
  }
}
