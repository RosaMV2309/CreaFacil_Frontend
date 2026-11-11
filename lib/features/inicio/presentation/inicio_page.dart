import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/cf_logo.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../contacto/presentation/boton_whatsapp.dart';
import '../../estado_api/presentation/estado_api_tarjeta.dart';

/// Pantalla de bienvenida de la app del cliente: logotipo, accesos y el
/// estado de la conexión con la API [RNF-04][RNF-05].
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  static const subtitulo = 'Manualidades, decoraciones y murales por encargo';

  /// Clave de la tarjeta de bienvenida (la del logotipo).
  static const claveBienvenida = ValueKey('inicio-bienvenida');

  /// Lado del logotipo completo según el tamaño de pantalla [RNF-05].
  static double tamanoLogo(TamanoPantalla tamano) => switch (tamano) {
    TamanoPantalla.movil => 180,
    TamanoPantalla.tablet => 220,
    TamanoPantalla.escritorio => 260,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final tamano = PuntosCorte.deContexto(context);
    final movil = tamano == TamanoPantalla.movil;

    return Scaffold(
      appBar: AppBar(title: const CfMarcaEncabezado()),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              movil ? tokens.espacioLg : tokens.espacioXl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CfCard(
                    key: claveBienvenida,
                    padding: EdgeInsets.all(
                      movil ? tokens.espacioXl : tokens.espacioXxl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CfLogo(size: tamanoLogo(tamano)),
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
                        SizedBox(height: tokens.espacioMd),
                        BotonWhatsApp(expanded: movil),
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
                  SizedBox(height: tokens.espacioLg),
                  const EstadoApiTarjeta(),
                ],
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
