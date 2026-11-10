import 'package:creafacil_app/app.dart';
import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/widgets/cf_logo.dart';
import 'package:creafacil_app/core/widgets/responsive_layout.dart';
import 'package:creafacil_app/features/inicio/presentation/inicio_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/envolver.dart';

void main() {
  testWidgets('muestra la pantalla de inicio de CreaFácil', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    expect(
      find.text('Manualidades, decoraciones y murales por encargo'),
      findsOneWidget,
    );
  });

  testWidgets('la bienvenida muestra el logotipo completo de CreaFácil', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    final enTarjeta = find.descendant(
      of: find.byType(CfCard),
      matching: find.byType(CfLogo),
    );
    expect(enTarjeta, findsOneWidget);
    expect(tester.widget<CfLogo>(enTarjeta).variant, CfLogoVariant.completo);
    expect(
      find.descendant(of: enTarjeta, matching: find.byType(Image)),
      findsOneWidget,
    );
  });

  testWidgets('el encabezado muestra la ilustración junto a «CreaFácil»', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    final encabezado = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(CfMarcaEncabezado),
    );
    expect(encabezado, findsOneWidget);
    final icono = find.descendant(
      of: encabezado,
      matching: find.byType(CfLogo),
    );
    expect(tester.widget<CfLogo>(icono).variant, CfLogoVariant.icono);
    expect(
      find.descendant(of: encabezado, matching: find.text('CreaFácil')),
      findsOneWidget,
    );
  });

  testWidgets('el botón de prueba del inicio avisa que llega pronto', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explorar el catálogo'));
    await tester.pump();

    expect(
      find.text('El catálogo estará disponible muy pronto.'),
      findsOneWidget,
    );
  });

  testWidgets('en modo debug abre el catálogo de componentes', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver componentes'));
    // El catálogo tiene un CfSpinner animado: no se usa pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Catálogo de componentes'), findsOneWidget);
  });

  for (final ancho in [360.0, 375.0, 768.0, 1280.0]) {
    testWidgets('el inicio se adapta sin desbordes a ${ancho.toInt()} px', (
      tester,
    ) async {
      fijarVentana(tester, ancho);

      await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final tarjeta = tester.getRect(find.byType(CfCard));
      expect(tarjeta.left, greaterThanOrEqualTo(0));
      expect(tarjeta.right, lessThanOrEqualTo(ancho));

      // El logotipo completo cabe en la tarjeta y cambia de tamaño.
      final logo = tester.getRect(
        find.descendant(of: find.byType(CfCard), matching: find.byType(CfLogo)),
      );
      expect(logo.left, greaterThanOrEqualTo(tarjeta.left));
      expect(logo.right, lessThanOrEqualTo(tarjeta.right));
      expect(logo.width, InicioPage.tamanoLogo(PuntosCorte.de(ancho)));
    });
  }
}
