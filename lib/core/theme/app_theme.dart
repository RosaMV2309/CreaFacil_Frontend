import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'cf_tokens.dart';

/// Tema de CreaFácil (Material 3) con la paleta oficial [RNF-05].
///
/// El `ColorScheme` es explícito (no se usa `fromSeed`, que genera tonos fuera
/// de la paleta). Los radios, espaciados y sombras se exponen como
/// [CfTokens]. Guía: `references/identidad-visual.md` de la skill frontend.
abstract final class AppTheme {
  static const ColorScheme esquema = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primario,
    onPrimary: AppColors.blanco,
    primaryContainer: AppColors.secundario,
    onPrimaryContainer: AppColors.texto,
    secondary: AppColors.complementario,
    onSecondary: AppColors.blanco,
    secondaryContainer: AppColors.secundario,
    onSecondaryContainer: AppColors.texto,
    tertiary: AppColors.terciario,
    onTertiary: AppColors.texto,
    tertiaryContainer: AppColors.fondo,
    onTertiaryContainer: AppColors.texto,
    error: AppColors.primario,
    onError: AppColors.blanco,
    errorContainer: AppColors.secundario,
    onErrorContainer: AppColors.texto,
    surface: AppColors.blanco,
    onSurface: AppColors.texto,
    onSurfaceVariant: AppColors.texto,
    surfaceDim: AppColors.fondo,
    surfaceBright: AppColors.blanco,
    surfaceContainerLowest: AppColors.blanco,
    surfaceContainerLow: AppColors.blanco,
    surfaceContainer: AppColors.fondo,
    surfaceContainerHigh: AppColors.fondo,
    surfaceContainerHighest: AppColors.fondo,
    outline: AppColors.borde,
    outlineVariant: AppColors.borde,
    shadow: AppColors.texto,
    scrim: AppColors.texto,
    inverseSurface: AppColors.complementario,
    onInverseSurface: AppColors.blanco,
    inversePrimary: AppColors.secundario,
    surfaceTint: Colors.transparent,
  );

  static ThemeData claro() {
    final tokens = CfTokens.estandar;
    final textos = AppTipografia.textTheme;

    RoundedRectangleBorder forma(double radio, {BorderSide? lado}) {
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radio),
        side: lado ?? BorderSide.none,
      );
    }

    // Anillo de foco visible (web y teclado) común a todos los botones.
    WidgetStateProperty<BorderSide?> ladoConFoco(BorderSide? normal) {
      return WidgetStateProperty.resolveWith((estados) {
        if (estados.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.complementario, width: 2);
        }
        if (estados.contains(WidgetState.disabled) && normal != null) {
          return const BorderSide(color: AppColors.borde);
        }
        return normal;
      });
    }

    const tamanoMinimo = Size(64, 48);
    const relleno = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final textoDeshabilitado = AppColors.texto.withValues(alpha: 0.55);

    ButtonStyle botonRelleno(Color fondo, Color frente) {
      return ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(tamanoMinimo),
        padding: const WidgetStatePropertyAll(relleno),
        textStyle: WidgetStatePropertyAll(textos.labelLarge),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(forma(tokens.radioMd)),
        side: ladoConFoco(null),
        backgroundColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.disabled) ? AppColors.borde : fondo,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.disabled) ? textoDeshabilitado : frente,
        ),
        overlayColor: WidgetStatePropertyAll(
          AppColors.blanco.withValues(alpha: 0.14),
        ),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fondo,
      canvasColor: AppColors.fondo,
      dividerColor: AppColors.borde,
      fontFamily: AppTipografia.cuerpo,
      textTheme: textos,
      extensions: [tokens],
      focusColor: AppColors.complementario.withValues(alpha: 0.12),
      hoverColor: AppColors.primario.withValues(alpha: 0.06),
      splashColor: AppColors.primario.withValues(alpha: 0.10),
      highlightColor: AppColors.primario.withValues(alpha: 0.06),
      iconTheme: const IconThemeData(color: AppColors.texto),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      // Botones
      filledButtonTheme: FilledButtonThemeData(
        style: botonRelleno(AppColors.primario, AppColors.blanco),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: botonRelleno(AppColors.primario, AppColors.blanco),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(tamanoMinimo),
          padding: const WidgetStatePropertyAll(relleno),
          textStyle: WidgetStatePropertyAll(textos.labelLarge),
          shape: WidgetStatePropertyAll(forma(tokens.radioMd)),
          side: ladoConFoco(
            const BorderSide(color: AppColors.primario, width: 1.5),
          ),
          backgroundColor: const WidgetStatePropertyAll(AppColors.blanco),
          foregroundColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled)
                ? textoDeshabilitado
                : AppColors.primario,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primario.withValues(alpha: 0.08),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(tamanoMinimo),
          padding: const WidgetStatePropertyAll(relleno),
          textStyle: WidgetStatePropertyAll(textos.labelLarge),
          shape: WidgetStatePropertyAll(forma(tokens.radioMd)),
          side: ladoConFoco(null),
          foregroundColor: WidgetStateProperty.resolveWith(
            (e) => e.contains(WidgetState.disabled)
                ? textoDeshabilitado
                : AppColors.primario,
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primario.withValues(alpha: 0.08),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: ladoConFoco(null),
        ),
      ),
      // Campos de formulario
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.blanco,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: textos.bodyLarge,
        floatingLabelStyle: textos.bodyMedium?.copyWith(
          color: AppColors.complementario,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textos.bodyLarge?.copyWith(
          color: AppColors.texto.withValues(alpha: 0.6),
        ),
        helperStyle: textos.bodySmall,
        errorStyle: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        prefixIconColor: AppColors.texto,
        suffixIconColor: AppColors.texto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radioSm),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radioSm),
          borderSide: const BorderSide(color: AppColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radioSm),
          borderSide: const BorderSide(
            color: AppColors.complementario,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radioSm),
          borderSide: const BorderSide(color: AppColors.primario),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radioSm),
          borderSide: const BorderSide(color: AppColors.primario, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radioSm),
          borderSide: BorderSide(color: AppColors.borde.withValues(alpha: 0.6)),
        ),
      ),
      // Superficies
      cardTheme: CardThemeData(
        color: AppColors.blanco,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.texto.withValues(alpha: 0.4),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: forma(
          tokens.radioLg,
          lado: const BorderSide(color: AppColors.borde),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.fondo,
        selectedColor: AppColors.secundario,
        disabledColor: AppColors.borde,
        checkmarkColor: AppColors.texto,
        labelStyle: textos.labelMedium,
        side: const BorderSide(color: AppColors.borde),
        shape: forma(tokens.radioMd),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.blanco,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.texto.withValues(alpha: 0.5),
        elevation: 6,
        shape: forma(
          tokens.radioLg,
          lado: const BorderSide(color: AppColors.borde),
        ),
        titleTextStyle: textos.headlineSmall,
        contentTextStyle: textos.bodyLarge,
        barrierColor: AppColors.texto.withValues(alpha: 0.4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.blanco,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.borde,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radioXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.complementario,
        contentTextStyle: textos.bodyMedium?.copyWith(color: AppColors.blanco),
        actionTextColor: AppColors.secundario,
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: forma(tokens.radioMd),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.complementario,
          borderRadius: BorderRadius.circular(tokens.radioSm),
        ),
        textStyle: textos.bodySmall?.copyWith(color: AppColors.blanco),
      ),
      // Navegación: azul artesanal
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.complementario,
        foregroundColor: AppColors.blanco,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textos.titleLarge?.copyWith(color: AppColors.blanco),
        iconTheme: const IconThemeData(color: AppColors.blanco),
        actionsIconTheme: const IconThemeData(color: AppColors.blanco),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.complementario,
        indicatorColor: AppColors.secundario,
        indicatorShape: forma(tokens.radioMd),
        selectedIconTheme: const IconThemeData(color: AppColors.complementario),
        unselectedIconTheme: IconThemeData(
          color: AppColors.blanco.withValues(alpha: 0.85),
        ),
        selectedLabelTextStyle: textos.labelMedium?.copyWith(
          color: AppColors.blanco,
        ),
        unselectedLabelTextStyle: textos.labelMedium?.copyWith(
          color: AppColors.blanco.withValues(alpha: 0.85),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.complementario,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.secundario,
        indicatorShape: forma(tokens.radioMd),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith(
          (e) => IconThemeData(
            color: e.contains(WidgetState.selected)
                ? AppColors.complementario
                : AppColors.blanco.withValues(alpha: 0.85),
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          textos.labelMedium?.copyWith(color: AppColors.blanco),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.complementario,
        surfaceTintColor: Colors.transparent,
        scrimColor: AppColors.texto.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(tokens.radioLg),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.texto,
        textColor: AppColors.texto,
        shape: forma(tokens.radioMd),
        minVerticalPadding: 12,
      ),
      // Divisores y tablas
      dividerTheme: const DividerThemeData(
        color: AppColors.borde,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.fondo),
        headingTextStyle: textos.titleSmall,
        dataTextStyle: textos.bodyMedium,
        dividerThickness: 1,
        headingRowHeight: 52,
        dataRowMinHeight: 48,
        decoration: BoxDecoration(
          color: AppColors.blanco,
          border: Border.all(color: AppColors.borde),
          borderRadius: BorderRadius.circular(tokens.radioMd),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primario,
        linearTrackColor: AppColors.secundario,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.complementario,
        selectionColor: AppColors.secundario.withValues(alpha: 0.7),
        selectionHandleColor: AppColors.complementario,
      ),
    );
  }
}
