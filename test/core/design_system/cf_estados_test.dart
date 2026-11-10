import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  testWidgets('CfSpinner se anuncia como «Cargando»', (tester) async {
    await montar(tester, const CfSpinner());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
  });

  testWidgets('CfSpinner con etiqueta y tamaño pequeño', (tester) async {
    await montar(tester, const CfSpinner(size: 24, label: 'Cargando datos'));
    expect(find.text('Cargando datos'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size(24, 24),
    );
  });

  testWidgets('CfEmptyState muestra título, mensaje y acción', (tester) async {
    var toques = 0;
    await montar(
      tester,
      CfEmptyState(
        title: 'Sin pedidos',
        message: 'Aún no hay pedidos.',
        action: CfButton(label: 'Crear', onPressed: () => toques++),
      ),
    );

    expect(find.text('Sin pedidos'), findsOneWidget);
    expect(find.text('Aún no hay pedidos.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    await tester.tap(find.text('Crear'));
    expect(toques, 1);
  });

  testWidgets('CfErrorState muestra «Reintentar» y responde al toque', (
    tester,
  ) async {
    var reintentos = 0;
    await montar(tester, CfErrorState(onRetry: () => reintentos++));

    expect(find.text('Algo salió mal'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(reintentos, 1);
  });

  testWidgets('CfErrorState sin onRetry no muestra el botón', (tester) async {
    await montar(
      tester,
      const CfErrorState(title: 'Sin conexión', message: 'Revisa tu red.'),
    );
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });
}
