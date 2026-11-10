import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/cf_logo.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Pantalla de inicio provisional con la identidad visual de CreaFácil.
/// Todavía no consulta la API (eso llega en la subfase 0.8).
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  static const subtitulo = 'Manualidades, decoraciones y murales por encargo';

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final movil = PuntosCorte.deContexto(context) == TamanoPantalla.movil;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              movil ? tokens.espacioLg : tokens.espacioXl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: CfCard(
                padding: EdgeInsets.all(
                  movil ? tokens.espacioXl : tokens.espacioXxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CfLogo(size: movil ? 36 : 44),
                    SizedBox(height: tokens.espacioLg),
                    Text(
                      subtitulo,
                      textAlign: TextAlign.center,
                      style: textos.bodyLarge,
                    ),
                    SizedBox(height: tokens.espacioXl),
                    CfButton(
                      label: 'Explorar el catálogo',
                      icon: Icons.palette_outlined,
                      expanded: movil,
                      onPressed: () => _avisoProximamente(context),
                    ),
                    if (kDebugMode) ...[
                      SizedBox(height: tokens.espacioSm),
                      CfButton(
                        label: 'Ver componentes',
                        variant: CfButtonVariant.text,
                        icon: Icons.widgets_outlined,
                        tooltip: 'Solo en modo desarrollo',
                        onPressed: () => context.push(Rutas.componentes),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _avisoProximamente(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('El catálogo estará disponible muy pronto.'),
        ),
      );
  }
}
