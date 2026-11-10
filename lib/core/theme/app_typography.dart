import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografía de CreaFácil: Poppins para títulos y etiquetas, Nunito para el
/// cuerpo. Ambas se incluyen como assets locales (ver `assets/fonts/`).
abstract final class AppTipografia {
  static const titulos = 'Poppins';
  static const cuerpo = 'Nunito';

  static TextStyle _poppins(
    double tamano,
    FontWeight peso,
    double alto, {
    double espaciado = 0,
  }) {
    return TextStyle(
      fontFamily: titulos,
      fontSize: tamano,
      fontWeight: peso,
      height: alto / tamano,
      letterSpacing: espaciado,
      color: AppColors.texto,
    );
  }

  static TextStyle _nunito(
    double tamano,
    FontWeight peso,
    double alto, {
    double espaciado = 0,
  }) {
    return TextStyle(
      fontFamily: cuerpo,
      fontSize: tamano,
      fontWeight: peso,
      height: alto / tamano,
      letterSpacing: espaciado,
      color: AppColors.texto,
    );
  }

  /// Escala tipográfica de Material 3 con las fuentes de la marca.
  /// `labelLarge` (botones) va en negrita w600 y 15 px por el contraste del
  /// texto blanco sobre el coral (WCAG AA, texto grande en negrita).
  static final TextTheme textTheme = TextTheme(
    displayLarge: _poppins(57, FontWeight.w600, 64, espaciado: -0.25),
    displayMedium: _poppins(45, FontWeight.w600, 52),
    displaySmall: _poppins(36, FontWeight.w600, 44),
    headlineLarge: _poppins(32, FontWeight.w600, 40),
    headlineMedium: _poppins(28, FontWeight.w600, 36),
    headlineSmall: _poppins(24, FontWeight.w600, 32),
    titleLarge: _poppins(22, FontWeight.w600, 28),
    titleMedium: _poppins(16, FontWeight.w600, 24, espaciado: 0.15),
    titleSmall: _poppins(14, FontWeight.w600, 20, espaciado: 0.1),
    bodyLarge: _nunito(16, FontWeight.w400, 24, espaciado: 0.15),
    bodyMedium: _nunito(14, FontWeight.w400, 20, espaciado: 0.25),
    bodySmall: _nunito(12, FontWeight.w400, 16, espaciado: 0.4),
    labelLarge: _poppins(15, FontWeight.w600, 20, espaciado: 0.1),
    labelMedium: _poppins(12, FontWeight.w600, 16, espaciado: 0.5),
    labelSmall: _poppins(11, FontWeight.w600, 16, espaciado: 0.5),
  );
}
