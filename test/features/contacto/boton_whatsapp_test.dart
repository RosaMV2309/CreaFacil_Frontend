import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:creafacil_app/core/theme/app_theme.dart';
import 'package:creafacil_app/features/contacto/data/abridor_enlaces.dart';
import 'package:creafacil_app/features/contacto/domain/enlace_whatsapp.dart';
import 'package:creafacil_app/features/contacto/presentation/boton_whatsapp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _AbridorFalso implements AbridorEnlaces {
  _AbridorFalso({this.resultado = true});
  final bool resultado;
  final abiertos = <Uri>[];

  @override
  Future<bool> abrir(Uri enlace) async {
    abiertos.add(enlace);
    return resultado;
  }
}

Future<void> montarBoton(
  WidgetTester tester, {
  required String numero,
  required AbridorEnlaces abridor,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        whatsappNumeroProvider.overrideWithValue(numero),
        abridorEnlacesProvider.overrideWithValue(abridor),
      ],
      child: MaterialApp(
        theme: AppTheme.claro(),
        home: const Scaffold(body: Center(child: BotonWhatsApp())),
      ),
    ),
  );
}

void main() {
  group('enlaceWhatsApp', () {
    test('construye https://wa.me/<numero> solo con dígitos', () {
      expect(
        enlaceWhatsApp('+593 99-123 4567').toString(),
        'https://wa.me/593991234567',
      );
      expect(
        enlaceWhatsApp('593000000000').toString(),
        'https://wa.me/593000000000',
      );
    });

    test('sin número devuelve null', () {
      expect(enlaceWhatsApp(''), isNull);
      expect(enlaceWhatsApp(' + - '), isNull);
    });
  });

  testWidgets('con número: el botón abre WhatsApp', (tester) async {
    final abridor = _AbridorFalso();
    await montarBoton(tester, numero: '593000000000', abridor: abridor);

    expect(find.text(BotonWhatsApp.textoSinNumero), findsNothing);
    final boton = tester.widget<CfButton>(find.byType(CfButton));
    expect(boton.onPressed, isNotNull);

    await tester.tap(find.text(BotonWhatsApp.etiqueta));
    await tester.pump();

    expect(abridor.abiertos, [Uri.parse('https://wa.me/593000000000')]);
  });

  testWidgets('si no se puede abrir, avisa con un SnackBar', (tester) async {
    await montarBoton(
      tester,
      numero: '593000000000',
      abridor: _AbridorFalso(resultado: false),
    );

    await tester.tap(find.text(BotonWhatsApp.etiqueta));
    await tester.pump();

    expect(find.text(BotonWhatsApp.textoError), findsOneWidget);
  });

  testWidgets('sin número: deshabilitado y con la explicación', (tester) async {
    final abridor = _AbridorFalso();
    await montarBoton(tester, numero: '', abridor: abridor);

    expect(find.text(BotonWhatsApp.etiqueta), findsOneWidget);
    expect(find.text(BotonWhatsApp.textoSinNumero), findsOneWidget);
    final boton = tester.widget<CfButton>(find.byType(CfButton));
    expect(boton.onPressed, isNull);

    await tester.tap(find.text(BotonWhatsApp.etiqueta), warnIfMissed: false);
    await tester.pump();
    expect(abridor.abiertos, isEmpty);
  });
}
