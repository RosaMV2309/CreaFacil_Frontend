import 'package:flutter/widgets.dart';

/// Tamaños de pantalla de CreaFácil [RNF-05].
enum TamanoPantalla { movil, tablet, escritorio }

/// Puntos de corte: móvil < 600, tablet < 1024 y escritorio ≥ 1024 px.
abstract final class PuntosCorte {
  static const double tablet = 600;
  static const double escritorio = 1024;

  static TamanoPantalla de(double ancho) {
    if (ancho >= escritorio) {
      return TamanoPantalla.escritorio;
    }
    if (ancho >= tablet) {
      return TamanoPantalla.tablet;
    }
    return TamanoPantalla.movil;
  }

  /// Tamaño según el ancho de la ventana actual.
  static TamanoPantalla deContexto(BuildContext context) =>
      de(MediaQuery.sizeOf(context).width);
}

/// Elige qué construir según el ancho disponible (no el de la ventana).
/// Si no se indica `tablet`, se usa `movil`; si no se indica `escritorio`,
/// se usa `tablet` (o `movil`).
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    required this.movil,
    this.tablet,
    this.escritorio,
    super.key,
  });

  final WidgetBuilder movil;
  final WidgetBuilder? tablet;
  final WidgetBuilder? escritorio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final constructor = switch (PuntosCorte.de(restricciones.maxWidth)) {
          TamanoPantalla.movil => movil,
          TamanoPantalla.tablet => tablet ?? movil,
          TamanoPantalla.escritorio => escritorio ?? tablet ?? movil,
        };
        return constructor(context);
      },
    );
  }
}
