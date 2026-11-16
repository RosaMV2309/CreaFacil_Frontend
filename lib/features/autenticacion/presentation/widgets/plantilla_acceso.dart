import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/router/rutas.dart';
import '../../../../core/widgets/cf_logo.dart';
import '../../../../core/widgets/responsive_layout.dart';

/// Estructura común de las pantallas de cuenta de la app [RNF-05]:
/// encabezado azul con la marca, botón para volver al inicio y una tarjeta
/// centrada de ancho máximo legible (móvil, tablet y escritorio).
class PlantillaAcceso extends StatelessWidget {
  const PlantillaAcceso({
    required this.titulo,
    required this.child,
    this.subtitulo,
    this.anchoMaximo = 480,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;
  final double anchoMaximo;

  static const claveTarjeta = ValueKey('plantilla-acceso-tarjeta');

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final movil = PuntosCorte.deContexto(context) == TamanoPantalla.movil;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver al inicio',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Rutas.inicio),
        ),
        title: const CfMarcaEncabezado(),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              movil ? tokens.espacioLg : tokens.espacioXl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: anchoMaximo),
              child: CfCard(
                key: claveTarjeta,
                title: titulo,
                subtitle: subtitulo,
                padding: EdgeInsets.all(
                  movil ? tokens.espacioXl : tokens.espacioXxl,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
