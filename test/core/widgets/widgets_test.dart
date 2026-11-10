import 'package:creafacil_app/core/widgets/cf_logo.dart';
import 'package:creafacil_app/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  test('puntos de corte: móvil < 600, tablet < 1024, escritorio ≥ 1024', () {
    expect(PuntosCorte.de(375), TamanoPantalla.movil);
    expect(PuntosCorte.de(599), TamanoPantalla.movil);
    expect(PuntosCorte.de(600), TamanoPantalla.tablet);
    expect(PuntosCorte.de(1023), TamanoPantalla.tablet);
    expect(PuntosCorte.de(1024), TamanoPantalla.escritorio);
  });

  for (final caso in {
    375.0: 'móvil',
    768.0: 'tablet',
    1280.0: 'escritorio',
  }.entries) {
    testWidgets('ResponsiveLayout elige la vista ${caso.value}', (
      tester,
    ) async {
      fijarVentana(tester, caso.key);
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            movil: (_) => const Text('móvil'),
            tablet: (_) => const Text('tablet'),
            escritorio: (_) => const Text('escritorio'),
          ),
        ),
      );
      expect(find.text(caso.value), findsOneWidget);
    });
  }

  testWidgets('ResponsiveLayout usa la vista móvil si falta otra', (
    tester,
  ) async {
    fijarVentana(tester, 1280);
    await tester.pumpWidget(
      MaterialApp(home: ResponsiveLayout(movil: (_) => const Text('móvil'))),
    );
    expect(find.text('móvil'), findsOneWidget);
  });

  testWidgets('CfLogo muestra la marca «CreaFácil» accesible', (tester) async {
    await montar(tester, const CfLogo());
    expect(find.text('CreaFácil'), findsOneWidget);
    expect(find.bySemanticsLabel('CreaFácil'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('CfLogo sin acento ni tamaños menores de 24 px', (tester) async {
    await montar(tester, const CfLogo(size: 12, showAccent: false));
    final texto = tester.widget<Text>(find.text('CreaFácil'));
    expect(texto.style?.fontSize, 24);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });
}
