import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/theme/app_theme.dart';
import 'package:creafacil_app/features/dev/presentation/componentes_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

Future<void> _montarCatalogo(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.claro(), home: const ComponentesPage()),
  );
  await tester.pump();
}

void main() {
  testWidgets('el catálogo muestra todas las variantes de los componentes', (
    tester,
  ) async {
    fijarVentana(tester, 1280, 4000);
    await _montarCatalogo(tester);

    expect(find.text('Catálogo de componentes'), findsOneWidget);
    expect(find.byType(CfButton), findsWidgets);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Secundario'), findsWidgets);
    expect(find.text('Contorno'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.byType(CfTag), findsNWidgets(6));
    expect(find.byType(CfMessage), findsNWidgets(4));
    expect(find.byType(CfSpinner), findsOneWidget);
    expect(find.byType(CfEmptyState), findsOneWidget);
    expect(find.byType(CfErrorState), findsOneWidget);
  });

  testWidgets('el botón de carga del catálogo cambia de estado', (
    tester,
  ) async {
    fijarVentana(tester, 1280, 4000);
    await _montarCatalogo(tester);

    await tester.tap(find.text('Probar carga'));
    await tester.pump();
    expect(find.text('Guardando'), findsOneWidget);

    await tester.tap(find.text('Detener carga'));
    await tester.pump();
    expect(find.text('Probar carga'), findsOneWidget);
  });

  for (final ancho in [375.0, 768.0, 1280.0]) {
    testWidgets('el catálogo se adapta sin desbordes a ${ancho.toInt()} px', (
      tester,
    ) async {
      fijarVentana(tester, ancho);
      await _montarCatalogo(tester);

      expect(tester.takeException(), isNull);

      // Recorre todo el catálogo para construir y revisar cada sección.
      final desplazable = find.byType(Scrollable).first;
      for (var i = 0; i < 12; i++) {
        await tester.drag(desplazable, const Offset(0, -600));
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
