import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Marca de CreaFácil.
///
/// PROVISIONAL: el logotipo todavía no está en `CONTEXTO/`. Mientras tanto se
/// muestra una marca de texto «CreaFácil» en Poppins coral con un acento
/// dorado decorativo. Cuando la usuaria añada el logotipo, se copiará a
/// `assets/images/logo.png`, se declarará en `pubspec.yaml` y este widget
/// devolverá `Image.asset('assets/images/logo.png', height: ...)` manteniendo
/// la misma API (`size` y la etiqueta semántica «CreaFácil»).
class CfLogo extends StatelessWidget {
  const CfLogo({this.size = 36, this.showAccent = true, super.key});

  /// Tamaño de la letra de la marca. Como mínimo 24 px, para que el coral
  /// sobre fondos claros cumpla el contraste de texto grande (WCAG AA).
  final double size;

  /// Muestra el acento dorado decorativo (destello y subrayado).
  final bool showAccent;

  @override
  Widget build(BuildContext context) {
    final tamano = size < 24 ? 24.0 : size;
    final marca = Text(
      'CreaFácil',
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

    return Semantics(
      label: 'CreaFácil',
      image: true,
      excludeSemantics: true,
      child: FittedBox(
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
      ),
    );
  }
}
