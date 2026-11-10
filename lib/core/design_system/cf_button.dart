import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Variantes de [CfButton] (equivalentes a `severity`, `outlined` y `text`
/// del Button de PrimeNG).
enum CfButtonVariant {
  /// Rosa coral: acción principal.
  primary,

  /// Azul artesanal: acción secundaria o de navegación.
  secondary,

  /// Borde coral sobre blanco.
  outlined,

  /// Solo texto coral.
  text,

  /// Acción peligrosa: borde coral, fondo tenue e ícono de aviso.
  danger,
}

/// Botón de CreaFácil al estilo PrimeNG.
///
/// La etiqueta va siempre en negrita (w600) y con 15 px como mínimo para
/// cumplir el contraste WCAG AA del texto blanco sobre el coral. El área
/// táctil mínima es de 48 px y el foco se marca con un anillo azul.
class CfButton extends StatelessWidget {
  const CfButton({
    required this.label,
    required this.onPressed,
    this.variant = CfButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
    this.tooltip,
    super.key,
  });

  final String label;

  /// Si es `null`, el botón queda deshabilitado.
  final VoidCallback? onPressed;
  final CfButtonVariant variant;
  final IconData? icon;

  /// Muestra un indicador de carga e ignora los toques.
  final bool loading;

  /// Ocupa todo el ancho disponible.
  final bool expanded;
  final String? tooltip;

  bool get _relleno =>
      variant == CfButtonVariant.primary ||
      variant == CfButtonVariant.secondary;

  ({Color fondo, Color frente, BorderSide? borde}) get _colores {
    return switch (variant) {
      CfButtonVariant.primary => (
        fondo: AppColors.primario,
        frente: AppColors.blanco,
        borde: null,
      ),
      CfButtonVariant.secondary => (
        fondo: AppColors.complementario,
        frente: AppColors.blanco,
        borde: null,
      ),
      CfButtonVariant.outlined => (
        fondo: AppColors.blanco,
        frente: AppColors.primario,
        borde: const BorderSide(color: AppColors.primario, width: 1.5),
      ),
      CfButtonVariant.text => (
        fondo: Colors.transparent,
        frente: AppColors.primario,
        borde: null,
      ),
      CfButtonVariant.danger => (
        fondo: AppColors.primario.withValues(alpha: 0.08),
        frente: AppColors.texto,
        borde: const BorderSide(color: AppColors.primario, width: 1.5),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colores = _colores;
    final deshabilitado = onPressed == null && !loading;
    final frente = deshabilitado
        ? AppColors.texto.withValues(alpha: 0.55)
        : colores.frente;
    final etiqueta = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15);

    final estilo = ButtonStyle(
      textStyle: WidgetStatePropertyAll(etiqueta),
      minimumSize: WidgetStatePropertyAll(
        expanded ? const Size.fromHeight(48) : const Size(64, 48),
      ),
      backgroundColor: WidgetStatePropertyAll(
        deshabilitado
            ? (variant == CfButtonVariant.text
                  ? Colors.transparent
                  : AppColors.borde)
            : colores.fondo,
      ),
      foregroundColor: WidgetStatePropertyAll(frente),
      iconColor: WidgetStatePropertyAll(frente),
      overlayColor: WidgetStatePropertyAll(
        _relleno
            ? AppColors.blanco.withValues(alpha: 0.14)
            : AppColors.primario.withValues(alpha: 0.08),
      ),
      side: WidgetStateProperty.resolveWith((estados) {
        if (estados.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.complementario, width: 2);
        }
        if (deshabilitado && colores.borde != null) {
          return const BorderSide(color: AppColors.borde);
        }
        return colores.borde;
      }),
      mouseCursor: loading
          ? const WidgetStatePropertyAll(SystemMouseCursors.progress)
          : null,
    );

    // En la variante de peligro siempre hay un ícono que lo explique.
    final iconoElegido =
        icon ??
        (variant == CfButtonVariant.danger
            ? Icons.warning_amber_rounded
            : null);
    final Widget? iconoInicial = loading
        ? Semantics(
            label: 'Cargando',
            child: SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: frente),
            ),
          )
        : iconoElegido == null
        ? null
        : Icon(
            iconoElegido,
            size: 20,
            color: variant == CfButtonVariant.danger && !deshabilitado
                ? AppColors.primario
                : null,
          );

    final contenido = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconoInicial != null) ...[iconoInicial, const SizedBox(width: 8)],
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );

    final alPulsar = loading ? null : onPressed;
    final Widget boton = switch (variant) {
      CfButtonVariant.primary || CfButtonVariant.secondary => FilledButton(
        onPressed: alPulsar,
        style: estilo,
        child: contenido,
      ),
      CfButtonVariant.outlined || CfButtonVariant.danger => OutlinedButton(
        onPressed: alPulsar,
        style: estilo,
        child: contenido,
      ),
      CfButtonVariant.text => TextButton(
        onPressed: alPulsar,
        style: estilo,
        child: contenido,
      ),
    };

    final ancho = expanded
        ? SizedBox(width: double.infinity, child: boton)
        : boton;
    return tooltip == null ? ancho : Tooltip(message: tooltip, child: ancho);
  }
}
