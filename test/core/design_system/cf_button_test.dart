import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  for (final variante in CfButtonVariant.values) {
    testWidgets('CfButton ${variante.name} se ve y responde al toque', (
      tester,
    ) async {
      var toques = 0;
      await montar(
        tester,
        CfButton(
          label: 'Aceptar',
          variant: variante,
          onPressed: () => toques++,
        ),
      );

      expect(find.text('Aceptar'), findsOneWidget);
      await tester.tap(find.byType(CfButton));
      expect(toques, 1);

      // Área táctil mínima de 48 px.
      expect(
        tester.getSize(find.byType(CfButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  }

  testWidgets('la etiqueta va en negrita w600 y al menos 15 px', (
    tester,
  ) async {
    await montar(tester, CfButton(label: 'Guardar', onPressed: () {}));

    final estilo = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .style!
        .textStyle!
        .resolve({})!;
    expect(estilo.fontWeight, FontWeight.w600);
    expect(estilo.fontSize, greaterThanOrEqualTo(15));
  });

  testWidgets('primary es coral y secondary azul artesanal', (tester) async {
    await montar(
      tester,
      Column(
        children: [
          CfButton(label: 'Uno', onPressed: () {}),
          CfButton(
            label: 'Dos',
            variant: CfButtonVariant.secondary,
            onPressed: () {},
          ),
        ],
      ),
    );

    final botones = tester
        .widgetList<FilledButton>(find.byType(FilledButton))
        .toList();
    expect(botones[0].style!.backgroundColor!.resolve({}), AppColors.primario);
    expect(
      botones[1].style!.backgroundColor!.resolve({}),
      AppColors.complementario,
    );
  });

  testWidgets('muestra el ícono opcional y danger siempre lleva ícono', (
    tester,
  ) async {
    await montar(
      tester,
      Column(
        children: [
          CfButton(label: 'Añadir', icon: Icons.add, onPressed: () {}),
          CfButton(
            label: 'Eliminar',
            variant: CfButtonVariant.danger,
            onPressed: () {},
          ),
        ],
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('en carga muestra el indicador e ignora los toques', (
    tester,
  ) async {
    var toques = 0;
    await montar(
      tester,
      CfButton(label: 'Enviar', loading: true, onPressed: () => toques++),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // El botón fusiona su semántica: se anuncia «Cargando» junto a la etiqueta.
    expect(find.bySemanticsLabel(RegExp('Cargando')), findsOneWidget);
    await tester.tap(find.byType(CfButton));
    expect(toques, 0);
  });

  testWidgets('deshabilitado no responde al toque', (tester) async {
    await montar(tester, const CfButton(label: 'Enviar', onPressed: null));

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
    await tester.tap(find.byType(CfButton));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('se puede enfocar con el teclado (foco visible)', (tester) async {
    await montar(tester, CfButton(label: 'Foco', onPressed: () {}));

    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    final lado = boton.style!.side!.resolve({WidgetState.focused});
    expect(lado?.color, AppColors.complementario);
    expect(lado?.width, 2);
  });
}
