import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

Color _fondo(WidgetTester tester) {
  return tester
      .widget<Material>(
        find.descendant(
          of: find.byType(CfCard),
          matching: find.byType(Material),
        ),
      )
      .color!;
}

void main() {
  testWidgets('CfCard blanca muestra título, subtítulo y contenido', (
    tester,
  ) async {
    await montar(
      tester,
      const CfCard(
        title: 'Título',
        subtitle: 'Subtítulo',
        child: Text('Contenido'),
      ),
    );

    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Subtítulo'), findsOneWidget);
    expect(find.text('Contenido'), findsOneWidget);
    expect(_fondo(tester), AppColors.blanco);
  });

  testWidgets('CfCard pastel usa el rosa pastel', (tester) async {
    await montar(
      tester,
      const CfCard(variant: CfCardVariant.pastel, child: Text('Hola')),
    );
    expect(_fondo(tester), AppColors.secundario);
  });

  testWidgets('CfCard sin título ni subtítulo solo muestra el contenido', (
    tester,
  ) async {
    await montar(tester, const CfCard(child: Text('Solo')));
    expect(find.text('Solo'), findsOneWidget);
  });

  testWidgets('CfCard pulsable responde al toque', (tester) async {
    var toques = 0;
    await montar(tester, CfCard(title: 'Pulsable', onTap: () => toques++));
    await tester.tap(find.byType(CfCard));
    expect(toques, 1);
  });
}
