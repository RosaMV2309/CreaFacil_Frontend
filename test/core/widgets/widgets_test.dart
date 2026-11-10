import 'package:creafacil_app/core/widgets/cf_logo.dart';
import 'package:creafacil_app/core/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('CfLogo completo usa logo.png y se anuncia como «CreaFácil»', (
    tester,
  ) async {
    await montar(tester, const CfLogo(size: 200));
    final imagen = tester.widget<Image>(find.byType(Image));
    expect(_assetDe(imagen), CfLogo.assetCompleto);
    expect(find.bySemanticsLabel('CreaFácil'), findsOneWidget);
    expect(tester.getSize(find.byType(CfLogo)), const Size(200, 200));
  });

  testWidgets('CfLogo icono usa la ilustración recortada', (tester) async {
    await montar(tester, const CfLogo(variant: CfLogoVariant.icono, size: 48));
    final imagen = tester.widget<Image>(find.byType(Image));
    expect(_assetDe(imagen), CfLogo.assetIcono);
    expect(find.bySemanticsLabel('CreaFácil'), findsOneWidget);
  });

  testWidgets('CfLogo muestra la marca de texto si la imagen no carga', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: _BundleSinImagenes(),
            child: const Scaffold(body: Center(child: CfLogo())),
          ),
        ),
      );
      // Deja que la carga fallida de la imagen llegue al errorBuilder.
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byType(CfMarcaTexto), findsOneWidget);
    expect(find.text('CreaFácil'), findsOneWidget);
    expect(find.bySemanticsLabel('CreaFácil'), findsOneWidget);
  });

  testWidgets('CfMarcaTexto sin acento ni tamaños menores de 24 px', (
    tester,
  ) async {
    await montar(tester, const CfMarcaTexto(size: 12, showAccent: false));
    final texto = tester.widget<Text>(find.text('CreaFácil'));
    expect(texto.style?.fontSize, 24);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('CfMarcaEncabezado une la ilustración y el nombre', (
    tester,
  ) async {
    await montar(tester, const CfMarcaEncabezado());
    final logo = tester.widget<CfLogo>(find.byType(CfLogo));
    expect(logo.variant, CfLogoVariant.icono);
    expect(find.text('CreaFácil'), findsOneWidget);
    // Un solo anuncio para el lector de pantalla, no dos.
    expect(find.bySemanticsLabel('CreaFácil'), findsOneWidget);
  });
}

String? _assetDe(Image imagen) {
  final proveedor = imagen.image;
  if (proveedor is ResizeImage) {
    return (proveedor.imageProvider as AssetImage).assetName;
  }
  return (proveedor as AssetImage).assetName;
}

/// Paquete de recursos que no encuentra ninguna imagen, para probar el
/// respaldo de [CfLogo].
class _BundleSinImagenes extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future<ByteData>.error(FlutterError('Recurso no disponible: $key'));
}
