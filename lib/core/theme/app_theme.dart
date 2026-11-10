import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema base de CreaFácil. El sistema de componentes completo se añade en la subfase 0.7.
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
    error: AppColors.primario,
    onError: AppColors.blanco,
    surface: AppColors.blanco,
    onSurface: AppColors.texto,
    outline: AppColors.borde,
    outlineVariant: AppColors.borde,
  );

  static ThemeData claro() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fondo,
      dividerColor: AppColors.borde,
      cardTheme: const CardThemeData(
        color: AppColors.blanco,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.borde),
        ),
      ),
    );
  }
}
