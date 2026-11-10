import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens de diseño de CreaFácil (radios, espaciados y sombras) expuestos
/// como extensión del tema. Se leen con `CfTokens.of(context)`.
@immutable
class CfTokens extends ThemeExtension<CfTokens> {
  const CfTokens({
    required this.radioSm,
    required this.radioMd,
    required this.radioLg,
    required this.radioXl,
    required this.espacioXs,
    required this.espacioSm,
    required this.espacioMd,
    required this.espacioLg,
    required this.espacioXl,
    required this.espacioXxl,
    required this.sombra,
    required this.sombraElevada,
  });

  /// 8 px: campos y botones pequeños.
  final double radioSm;

  /// 12 px: botones y chips.
  final double radioMd;

  /// 16 px: tarjetas y diálogos.
  final double radioLg;

  /// 24 px: hojas inferiores.
  final double radioXl;

  final double espacioXs;
  final double espacioSm;
  final double espacioMd;
  final double espacioLg;
  final double espacioXl;
  final double espacioXxl;

  /// Sombra discreta de una sola capa para tarjetas.
  final List<BoxShadow> sombra;

  /// Sombra algo más marcada para diálogos y elementos flotantes.
  final List<BoxShadow> sombraElevada;

  /// Valores oficiales de la guía de identidad visual.
  static final CfTokens estandar = CfTokens(
    radioSm: 8,
    radioMd: 12,
    radioLg: 16,
    radioXl: 24,
    espacioXs: 4,
    espacioSm: 8,
    espacioMd: 12,
    espacioLg: 16,
    espacioXl: 24,
    espacioXxl: 32,
    sombra: [
      BoxShadow(
        color: AppColors.texto.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 2),
      ),
    ],
    sombraElevada: [
      BoxShadow(
        color: AppColors.texto.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Tokens del tema actual (o los estándar si el tema no los define).
  static CfTokens of(BuildContext context) =>
      Theme.of(context).extension<CfTokens>() ?? estandar;

  @override
  CfTokens copyWith({
    double? radioSm,
    double? radioMd,
    double? radioLg,
    double? radioXl,
    double? espacioXs,
    double? espacioSm,
    double? espacioMd,
    double? espacioLg,
    double? espacioXl,
    double? espacioXxl,
    List<BoxShadow>? sombra,
    List<BoxShadow>? sombraElevada,
  }) {
    return CfTokens(
      radioSm: radioSm ?? this.radioSm,
      radioMd: radioMd ?? this.radioMd,
      radioLg: radioLg ?? this.radioLg,
      radioXl: radioXl ?? this.radioXl,
      espacioXs: espacioXs ?? this.espacioXs,
      espacioSm: espacioSm ?? this.espacioSm,
      espacioMd: espacioMd ?? this.espacioMd,
      espacioLg: espacioLg ?? this.espacioLg,
      espacioXl: espacioXl ?? this.espacioXl,
      espacioXxl: espacioXxl ?? this.espacioXxl,
      sombra: sombra ?? this.sombra,
      sombraElevada: sombraElevada ?? this.sombraElevada,
    );
  }

  @override
  CfTokens lerp(covariant CfTokens? other, double t) {
    if (other == null) {
      return this;
    }
    double mezcla(double a, double b) => lerpDouble(a, b, t) ?? a;
    return CfTokens(
      radioSm: mezcla(radioSm, other.radioSm),
      radioMd: mezcla(radioMd, other.radioMd),
      radioLg: mezcla(radioLg, other.radioLg),
      radioXl: mezcla(radioXl, other.radioXl),
      espacioXs: mezcla(espacioXs, other.espacioXs),
      espacioSm: mezcla(espacioSm, other.espacioSm),
      espacioMd: mezcla(espacioMd, other.espacioMd),
      espacioLg: mezcla(espacioLg, other.espacioLg),
      espacioXl: mezcla(espacioXl, other.espacioXl),
      espacioXxl: mezcla(espacioXxl, other.espacioXxl),
      sombra: BoxShadow.lerpList(sombra, other.sombra, t) ?? sombra,
      sombraElevada:
          BoxShadow.lerpList(sombraElevada, other.sombraElevada, t) ??
          sombraElevada,
    );
  }
}
