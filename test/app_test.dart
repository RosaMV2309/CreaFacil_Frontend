import 'package:creafacil_app/app.dart';
import 'package:creafacil_app/core/theme/app_colors.dart';
import 'package:creafacil_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la pantalla de inicio de CreaFácil', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    expect(find.text('CreaFácil'), findsOneWidget);
    expect(
      find.text('Manualidades, decoraciones y murales por encargo'),
      findsOneWidget,
    );
  });

  for (final ancho in [360.0, 1280.0]) {
    testWidgets('se adapta sin desbordes a ${ancho.toInt()} px de ancho', (
      tester,
    ) async {
      tester.view.physicalSize = Size(ancho, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final tarjeta = tester.getRect(find.byType(Card));
      expect(tarjeta.left, greaterThanOrEqualTo(0));
      expect(tarjeta.right, lessThanOrEqualTo(ancho));
    });
  }

  test('el tema usa la paleta oficial', () {
    final tema = AppTheme.claro();
    expect(tema.colorScheme.primary, AppColors.primario);
    expect(tema.colorScheme.secondary, AppColors.complementario);
    expect(tema.colorScheme.tertiary, AppColors.terciario);
    expect(tema.scaffoldBackgroundColor, AppColors.fondo);
    expect(tema.colorScheme.onSurface, AppColors.texto);
  });
}
