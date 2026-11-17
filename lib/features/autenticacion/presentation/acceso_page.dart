import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/router/rutas.dart';
import 'autenticacion_providers.dart';
import 'widgets/formulario_acceso.dart';
import 'widgets/plantilla_acceso.dart';

/// Pantalla «Iniciar sesión» del cliente [RF-01].
///
/// Mientras se restaura la sesión guardada muestra un indicador; después, el
/// formulario. Si ya hay sesión, el router redirige al destino o al inicio.
class AccesoPage extends ConsumerWidget {
  const AccesoPage({this.desde, super.key});

  /// Ruta a la que volver tras iniciar sesión (la conserva el router).
  final String? desde;

  static const textoRestaurando = 'Comprobando tu sesión…';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurando = ref.watch(sesionControllerProvider).isLoading;

    return PlantillaAcceso(
      titulo: 'Iniciar sesión',
      subtitulo: 'Entra para pedir cotizaciones y seguir tus pedidos.',
      child: restaurando
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CfSpinner(label: textoRestaurando)),
            )
          : FormularioAcceso(
              onCrearCuenta: () => context.go(_conDesde(Rutas.registro)),
            ),
    );
  }

  String _conDesde(String ruta) => desde == null
      ? ruta
      : Uri(
          path: ruta,
          queryParameters: {Rutas.parametroDesde: desde},
        ).toString();
}
