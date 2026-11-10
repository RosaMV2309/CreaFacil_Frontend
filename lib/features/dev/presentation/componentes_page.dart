import 'package:flutter/material.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/cf_logo.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Catálogo de componentes Cf* para revisarlos visualmente.
/// Solo se registra en modo debug (ver `app_router.dart`).
class ComponentesPage extends StatefulWidget {
  const ComponentesPage({super.key});

  @override
  State<ComponentesPage> createState() => _ComponentesPageState();
}

class _ComponentesPageState extends State<ComponentesPage> {
  bool _cargando = false;
  bool _mensajeVisible = true;

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final tamano = PuntosCorte.deContexto(context);
    final separacion = SizedBox(height: tokens.espacioXl);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de componentes')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          tamano == TamanoPantalla.movil ? tokens.espacioLg : tokens.espacioXl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CfCard(
                  title: 'Marca y diseño adaptable',
                  subtitle: 'Tamaño de pantalla actual: ${tamano.name}',
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: CfLogo(),
                  ),
                ),
                separacion,
                CfCard(
                  title: 'Paleta oficial',
                  child: Wrap(
                    spacing: tokens.espacioMd,
                    runSpacing: tokens.espacioMd,
                    children: const [
                      _Muestra('Primario', AppColors.primario),
                      _Muestra('Secundario', AppColors.secundario),
                      _Muestra('Terciario', AppColors.terciario),
                      _Muestra('Complementario', AppColors.complementario),
                      _Muestra('Fondo', AppColors.fondo),
                      _Muestra('Texto', AppColors.texto),
                      _Muestra('Blanco', AppColors.blanco),
                      _Muestra('Borde', AppColors.borde),
                    ],
                  ),
                ),
                separacion,
                CfCard(
                  title: 'Tipografía',
                  subtitle: 'Poppins para títulos y Nunito para el cuerpo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Título grande', style: textos.headlineMedium),
                      Text('Título de sección', style: textos.titleLarge),
                      Text(
                        'Texto de cuerpo en Nunito, regular.',
                        style: textos.bodyLarge,
                      ),
                      Text(
                        'Texto de cuerpo en Nunito, negrita.',
                        style: textos.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                separacion,
                CfCard(
                  title: 'CfButton',
                  child: Wrap(
                    spacing: tokens.espacioMd,
                    runSpacing: tokens.espacioMd,
                    children: [
                      CfButton(
                        label: 'Principal',
                        onPressed: () => _avisar('Botón principal'),
                      ),
                      CfButton(
                        label: 'Secundario',
                        variant: CfButtonVariant.secondary,
                        onPressed: () => _avisar('Botón secundario'),
                      ),
                      CfButton(
                        label: 'Contorno',
                        variant: CfButtonVariant.outlined,
                        onPressed: () => _avisar('Botón de contorno'),
                      ),
                      CfButton(
                        label: 'Texto',
                        variant: CfButtonVariant.text,
                        onPressed: () => _avisar('Botón de texto'),
                      ),
                      CfButton(
                        label: 'Eliminar',
                        variant: CfButtonVariant.danger,
                        icon: Icons.delete_outline_rounded,
                        onPressed: () => _avisar('Botón de peligro'),
                      ),
                      CfButton(
                        label: 'Con ícono',
                        icon: Icons.add_rounded,
                        onPressed: () => _avisar('Botón con ícono'),
                      ),
                      CfButton(
                        label: _cargando ? 'Guardando' : 'Probar carga',
                        loading: _cargando,
                        variant: CfButtonVariant.secondary,
                        onPressed: () => setState(() => _cargando = true),
                      ),
                      const CfButton(label: 'Deshabilitado', onPressed: null),
                      if (_cargando)
                        CfButton(
                          label: 'Detener carga',
                          variant: CfButtonVariant.text,
                          onPressed: () => setState(() => _cargando = false),
                        ),
                    ],
                  ),
                ),
                separacion,
                Wrap(
                  spacing: tokens.espacioXl,
                  runSpacing: tokens.espacioXl,
                  children: [
                    for (final variante in CfCardVariant.values)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: CfCard(
                          variant: variante,
                          title: 'CfCard ${variante.name}',
                          subtitle: 'Título y subtítulo opcionales',
                          child: const Text(
                            'Contenido de la tarjeta con radio de 16 px, '
                            'borde suave y sombra discreta.',
                          ),
                        ),
                      ),
                  ],
                ),
                separacion,
                CfCard(
                  title: 'CfTag',
                  child: Wrap(
                    spacing: tokens.espacioSm,
                    runSpacing: tokens.espacioSm,
                    children: const [
                      CfTag(label: 'Estimada', severity: CfTagSeverity.primary),
                      CfTag(label: 'Enviada', severity: CfTagSeverity.info),
                      CfTag(
                        label: 'Entregado',
                        severity: CfTagSeverity.success,
                        icon: Icons.check_rounded,
                      ),
                      CfTag(
                        label: 'Pendiente',
                        severity: CfTagSeverity.warning,
                      ),
                      CfTag(
                        label: 'Cancelado',
                        severity: CfTagSeverity.danger,
                        icon: Icons.close_rounded,
                      ),
                      CfTag(label: 'Tentativa', rounded: true),
                    ],
                  ),
                ),
                separacion,
                CfCard(
                  title: 'CfMessage',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_mensajeVisible)
                        CfMessage(
                          title: 'Información',
                          text:
                              'La cotización es estimada hasta que la '
                              'administradora confirme el precio.',
                          onClose: () =>
                              setState(() => _mensajeVisible = false),
                        ),
                      SizedBox(height: tokens.espacioMd),
                      const CfMessage(
                        severity: CfMessageSeverity.success,
                        text: 'Solicitud enviada correctamente.',
                      ),
                      SizedBox(height: tokens.espacioMd),
                      const CfMessage(
                        severity: CfMessageSeverity.warning,
                        text: 'Hay otro pedido programado para esa fecha.',
                      ),
                      SizedBox(height: tokens.espacioMd),
                      const CfMessage(
                        severity: CfMessageSeverity.error,
                        text: 'No se pudo guardar. Inténtalo de nuevo.',
                      ),
                    ],
                  ),
                ),
                separacion,
                Wrap(
                  spacing: tokens.espacioXl,
                  runSpacing: tokens.espacioXl,
                  children: [
                    const SizedBox(
                      width: 320,
                      child: CfCard(
                        title: 'CfSpinner',
                        child: Center(
                          child: CfSpinner(label: 'Cargando servicios…'),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 320,
                      child: CfCard(
                        child: CfEmptyState(
                          title: 'Aún no tienes pedidos',
                          message: 'Cuando hagas un pedido aparecerá aquí.',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: CfCard(
                        child: CfErrorState(
                          onRetry: () => _avisar('Reintentando…'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Muestra extends StatelessWidget {
  const _Muestra(this.nombre, this.color);

  final String nombre;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borde),
            ),
          ),
          const SizedBox(height: 4),
          Text(nombre, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
