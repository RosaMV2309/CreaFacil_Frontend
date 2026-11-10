import 'package:creafacil_app/core/theme/app_colors.dart';
import 'package:creafacil_app/core/theme/app_theme.dart';
import 'package:creafacil_app/core/theme/app_typography.dart';
import 'package:creafacil_app/core/theme/cf_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tema = AppTheme.claro();

  test('el tema usa la paleta oficial', () {
    expect(tema.colorScheme.primary, AppColors.primario);
    expect(tema.colorScheme.secondary, AppColors.complementario);
    expect(tema.colorScheme.tertiary, AppColors.terciario);
    expect(tema.scaffoldBackgroundColor, AppColors.fondo);
    expect(tema.colorScheme.onSurface, AppColors.texto);
  });

  test('el ColorScheme es explícito y coincide con la guía', () {
    final e = tema.colorScheme;
    expect(tema.useMaterial3, isTrue);
    expect(e.onPrimary, AppColors.blanco);
    expect(e.onSecondary, AppColors.blanco);
    expect(e.onTertiary, AppColors.texto);
    expect(e.primaryContainer, AppColors.secundario);
    expect(e.secondaryContainer, AppColors.secundario);
    expect(e.onPrimaryContainer, AppColors.texto);
    expect(e.surface, AppColors.blanco);
    expect(e.error, AppColors.primario);
    expect(e.onError, AppColors.blanco);
    expect(e.outline, AppColors.borde);
    expect(e.outlineVariant, AppColors.borde);
    expect(e.shadow, AppColors.texto);
  });

  test('la navegación usa el azul artesanal', () {
    expect(tema.appBarTheme.backgroundColor, AppColors.complementario);
    expect(tema.navigationRailTheme.backgroundColor, AppColors.complementario);
    expect(tema.navigationBarTheme.backgroundColor, AppColors.complementario);
    expect(tema.drawerTheme.backgroundColor, AppColors.complementario);
    expect(tema.dividerTheme.color, AppColors.borde);
  });

  test('las tarjetas tienen radio 16 y borde de 1 px', () {
    final forma = tema.cardTheme.shape! as RoundedRectangleBorder;
    expect(forma.borderRadius, BorderRadius.circular(16));
    expect(forma.side.color, AppColors.borde);
    expect(forma.side.width, 1);
  });

  test('tipografía: Poppins en títulos y Nunito en el cuerpo', () {
    expect(tema.textTheme.headlineMedium?.fontFamily, AppTipografia.titulos);
    expect(tema.textTheme.bodyLarge?.fontFamily, AppTipografia.cuerpo);
    final etiqueta = tema.textTheme.labelLarge!;
    expect(etiqueta.fontWeight, FontWeight.w600);
    expect(etiqueta.fontSize, greaterThanOrEqualTo(15));
  });

  test('CfTokens está disponible con radios, espaciados y sombras', () {
    final tokens = tema.extension<CfTokens>();
    expect(tokens, isNotNull);
    expect(
      [tokens!.radioSm, tokens.radioMd, tokens.radioLg, tokens.radioXl],
      [8, 12, 16, 24],
    );
    expect(
      [
        tokens.espacioXs,
        tokens.espacioSm,
        tokens.espacioMd,
        tokens.espacioLg,
        tokens.espacioXl,
        tokens.espacioXxl,
      ],
      [4, 8, 12, 16, 24, 32],
    );
    expect(tokens.sombra, hasLength(1));
    expect(tokens.sombra.first.color.a, lessThanOrEqualTo(0.08));
  });

  test('CfTokens se puede copiar e interpolar', () {
    final base = CfTokens.estandar;
    final copia = base.copyWith(radioLg: 20);
    expect(copia.radioLg, 20);
    expect(copia.radioSm, base.radioSm);
    expect(base.lerp(copia, 0.5).radioLg, 18);
    expect(base.lerp(null, 0.5), same(base));
  });

  testWidgets('CfTokens.of lee los tokens del tema', (tester) async {
    late CfTokens leidos;
    await tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: Builder(
          builder: (context) {
            leidos = CfTokens.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(leidos.radioLg, 16);
  });
}
