import 'package:creafacil_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta [hijo] dentro de una app con el tema de CreaFácil.
Future<void> montar(WidgetTester tester, Widget hijo) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: SingleChildScrollView(child: Center(child: hijo)),
      ),
    ),
  );
}

/// Fija el tamaño lógico de la ventana de prueba.
void fijarVentana(WidgetTester tester, double ancho, [double alto = 800]) {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
