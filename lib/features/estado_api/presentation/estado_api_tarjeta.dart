import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/network/red.dart';
import '../domain/estado_api.dart';
import 'estado_api_providers.dart';

/// Tarjeta con el estado de la conexión con la API [RNF-04].
///
/// - Cargando: `CfSpinner`.
/// - Conectado: mensaje de éxito con la versión y el entorno.
/// - API disponible con la base de datos caída: aviso y «Reintentar».
/// - Sin conexión: `CfErrorState` con el mensaje y «Reintentar».
class EstadoApiTarjeta extends ConsumerWidget {
  const EstadoApiTarjeta({super.key});

  static const titulo = 'Estado del servicio';
  static const textoCargando = 'Comprobando la conexión con la API…';
  static const textoConectado = 'Conectado con la API';
  static const textoDegradado = 'API disponible, base de datos con problemas';
  static const textoSinConexion = 'Sin conexión con la API';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(estadoApiProvider);
    void reintentar() => ref.invalidate(estadoApiProvider);

    final Widget contenido;
    if (estado.isLoading) {
      contenido = const Center(
        child: CfSpinner(size: 32, label: textoCargando),
      );
    } else if (estado.hasError) {
      final error = estado.error;
      contenido = CfErrorState(
        title: textoSinConexion,
        message: error is ApiException
            ? error.mensaje
            : ConversorErrores.mensajeDesconocido,
        onRetry: reintentar,
      );
    } else {
      final api = estado.requireValue;
      contenido = api.baseDatosConProblemas
          ? _Degradado(api: api, onRetry: reintentar)
          : _Conectado(api: api);
    }

    return CfCard(
      title: titulo,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(
            estado.isLoading
                ? 'cargando'
                : estado.hasError
                ? 'error'
                : 'datos',
          ),
          child: contenido,
        ),
      ),
    );
  }
}

class _Conectado extends StatelessWidget {
  const _Conectado({required this.api});

  final EstadoApi api;

  @override
  Widget build(BuildContext context) {
    final partes = [
      'Versión ${api.version}',
      'Entorno: ${api.entorno}',
      if (api.baseDatos == EstadoBaseDatos.ok) 'Base de datos en línea',
    ];
    return CfMessage(
      severity: CfMessageSeverity.success,
      title: EstadoApiTarjeta.textoConectado,
      text: partes.join(' · '),
    );
  }
}

class _Degradado extends StatelessWidget {
  const _Degradado({required this.api, required this.onRetry});

  final EstadoApi api;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CfMessage(
          severity: CfMessageSeverity.warning,
          title: EstadoApiTarjeta.textoDegradado,
          text:
              'La API responde (versión ${api.version}), pero la base de '
              'datos no está disponible. Algunas funciones pueden fallar.',
        ),
        SizedBox(height: tokens.espacioLg),
        Align(
          child: CfButton(
            label: 'Reintentar',
            icon: Icons.refresh_rounded,
            variant: CfButtonVariant.outlined,
            onPressed: onRetry,
          ),
        ),
      ],
    );
  }
}
