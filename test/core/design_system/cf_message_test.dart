import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  const iconos = {
    CfMessageSeverity.info: Icons.info_outline_rounded,
    CfMessageSeverity.success: Icons.check_circle_outline_rounded,
    CfMessageSeverity.warning: Icons.warning_amber_rounded,
    CfMessageSeverity.error: Icons.error_outline_rounded,
  };

  for (final entrada in iconos.entries) {
    testWidgets('CfMessage ${entrada.key.name} muestra su ícono y texto', (
      tester,
    ) async {
      await montar(
        tester,
        SizedBox(
          width: 360,
          child: CfMessage(
            severity: entrada.key,
            title: 'Título',
            text: 'Mensaje de prueba',
          ),
        ),
      );

      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Mensaje de prueba'), findsOneWidget);
      expect(find.byIcon(entrada.value), findsOneWidget);
    });
  }

  testWidgets('el botón «Cerrar» responde al toque', (tester) async {
    var cerrado = false;
    await montar(
      tester,
      SizedBox(
        width: 360,
        child: CfMessage(text: 'Hola', onClose: () => cerrado = true),
      ),
    );

    await tester.tap(find.byTooltip('Cerrar'));
    expect(cerrado, isTrue);
    expect(
      tester.getSize(find.byType(IconButton)).height,
      greaterThanOrEqualTo(48),
    );
  });
}
