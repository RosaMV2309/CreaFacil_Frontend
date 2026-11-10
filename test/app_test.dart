import 'package:creafacil_app/app.dart';
import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/widgets/cf_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/envolver.dart';

void main() {
  testWidgets('muestra la pantalla de inicio de CreaFácil', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CreaFacilApp()));
    await tester.pumpAndSettle();

    expect(find.text('CreaFácil'), findsOneWidget);
    expect(find.byType(CfLogo), findsOneWidget);
    expect(
      find.text('Manualidades, decoraciones y murales por encargo'),
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
    });
  }
}
