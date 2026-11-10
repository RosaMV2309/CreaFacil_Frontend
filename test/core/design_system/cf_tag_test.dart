import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  testWidgets('CfTag muestra todas sus severidades', (tester) async {
    await montar(
      tester,
      Wrap(
        children: [
          for (final s in CfTagSeverity.values)
            CfTag(label: s.name, severity: s),
        ],
      ),
    );

    for (final s in CfTagSeverity.values) {
      expect(find.text(s.name), findsOneWidget);
      expect(find.bySemanticsLabel(s.name), findsOneWidget);
    }
  });

  testWidgets('el dorado nunca se usa como color de texto', (tester) async {
    await montar(
      tester,
      Wrap(
        children: [
          for (final s in CfTagSeverity.values)
            CfTag(label: s.name, severity: s),
        ],
      ),
    );

    for (final texto in tester.widgetList<Text>(find.byType(Text))) {
      expect(texto.style?.color, isNot(AppColors.terciario));
    }
  });

  testWidgets('CfTag con ícono y redondeado', (tester) async {
    await montar(
      tester,
      const CfTag(label: 'Listo', icon: Icons.check, rounded: true),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
