import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/usuario.dart';
import 'autenticacion_providers.dart';
import 'widgets/plantilla_acceso.dart';

/// «Mi perfil» del cliente, de solo lectura [RF-01].
///
/// La edición (`PATCH /auth/perfil`) llegará con la subfase 1.2 del backend:
/// mientras tanto, «Editar perfil» aparece deshabilitado con el texto
/// «Disponible próximamente».
class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  static const claveCerrarSesion = ValueKey('perfil-cerrar-sesion');
  static const claveEditar = ValueKey('perfil-editar');
  static const textoSinTelefono = 'No indicado';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    final tokens = CfTokens.of(context);

    return PlantillaAcceso(
      titulo: 'Mi perfil',
      anchoMaximo: 560,
      child: usuario == null
          ? const Center(child: CfSpinner(label: 'Cargando tu perfil…'))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cabecera(usuario: usuario),
                SizedBox(height: tokens.espacioXl),
                _Dato(
                  icono: Icons.person_outline_rounded,
                  etiqueta: 'Nombre',
                  valor: usuario.nombre,
                ),
                _Dato(
                  icono: Icons.mail_outline_rounded,
                  etiqueta: 'Correo electrónico',
                  valor: usuario.email,
                ),
                _Dato(
                  icono: Icons.phone_outlined,
                  etiqueta: 'Teléfono',
                  valor: usuario.telefono ?? textoSinTelefono,
                ),
                SizedBox(height: tokens.espacioXl),
                Wrap(
                  spacing: tokens.espacioMd,
                  runSpacing: tokens.espacioMd,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const CfButton(
                      key: claveEditar,
                      label: 'Editar perfil',
                      icon: Icons.edit_outlined,
                      variant: CfButtonVariant.outlined,
                      tooltip: 'Disponible próximamente',
                      onPressed: null,
                    ),
                    Text(
                      'Disponible próximamente',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                SizedBox(height: tokens.espacioMd),
                CfButton(
                  key: claveCerrarSesion,
                  label: 'Cerrar sesión',
                  icon: Icons.logout_rounded,
                  variant: CfButtonVariant.danger,
                  expanded: true,
                  onPressed: () => _cerrarSesion(context, ref),
                ),
              ],
            ),
    );
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final confirmado = await CfConfirmDialog.mostrar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres cerrar tu sesión en CreaFácil?',
      textoConfirmar: 'Cerrar sesión',
      peligro: true,
      icono: Icons.logout_rounded,
    );
    if (!confirmado || !context.mounted) {
      return;
    }
    final controlador = ref.read(sesionControllerProvider.notifier);
    context.go(Rutas.inicio);
    await controlador.cerrarSesion();
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final inicial = usuario.nombre.trim().isEmpty
        ? '?'
        : usuario.nombre.trim().substring(0, 1).toUpperCase();

    return Row(
      children: [
        ExcludeSemantics(
          child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.secundario,
            foregroundColor: AppColors.texto,
            child: Text(inicial, style: textos.titleLarge),
          ),
        ),
        SizedBox(width: tokens.espacioLg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                usuario.nombre,
                style: textos.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              SizedBox(height: tokens.espacioXs),
              CfTag(
                label: usuario.rol.etiqueta,
                severity: CfTagSeverity.primary,
                icon: Icons.verified_user_outlined,
                rounded: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: tokens.espacioMd),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borde)),
        ),
        child: Row(
          children: [
            Icon(icono, color: AppColors.complementario),
            SizedBox(width: tokens.espacioMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta, style: textos.bodySmall),
                  Text(valor, style: textos.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
