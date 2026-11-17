import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/router/rutas.dart';
import '../autenticacion_providers.dart';

/// Acción del AppBar: «Mi perfil» con sesión o «Iniciar sesión» sin ella.
class AccionCuenta extends ConsumerWidget {
  const AccionCuenta({super.key});

  static const clavePerfil = ValueKey('appbar-perfil');
  static const claveAcceso = ValueKey('appbar-acceso');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActualProvider);
    return usuario == null
        ? IconButton(
            key: claveAcceso,
            tooltip: 'Iniciar sesión',
            icon: const Icon(Icons.login_rounded),
            onPressed: () => context.go(Rutas.acceso),
          )
        : IconButton(
            key: clavePerfil,
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go(Rutas.perfil),
          );
  }
}

/// Tarjeta «Tu cuenta» del inicio [RF-01]:
/// - sin sesión: «Iniciar sesión» y «Crear cuenta»;
/// - con sesión: «Hola, `nombre`» y acceso a «Mi perfil».
class TarjetaCuenta extends ConsumerWidget {
  const TarjetaCuenta({this.expandido = false, super.key});

  /// Botones a todo el ancho (móvil).
  final bool expandido;

  static const claveTarjeta = ValueKey('inicio-cuenta');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = CfTokens.of(context);
    final estado = ref.watch(sesionControllerProvider);
    final usuario = estado.value?.usuario;

    if (estado.isLoading) {
      return const CfCard(
        key: claveTarjeta,
        child: Center(
          child: CfSpinner(size: 24, label: 'Comprobando tu sesión…'),
        ),
      );
    }

    if (usuario != null) {
      return CfCard(
        key: claveTarjeta,
        variant: CfCardVariant.pastel,
        title: 'Hola, ${usuario.nombre}',
        subtitle: 'Ya puedes consultar tu perfil.',
        child: Align(
          alignment: Alignment.centerLeft,
          child: CfButton(
            label: 'Mi perfil',
            icon: Icons.account_circle_outlined,
            variant: CfButtonVariant.secondary,
            expanded: expandido,
            onPressed: () => context.go(Rutas.perfil),
          ),
        ),
      );
    }

    final botones = [
      CfButton(
        label: 'Iniciar sesión',
        icon: Icons.login_rounded,
        variant: CfButtonVariant.secondary,
        expanded: expandido,
        onPressed: () => context.go(Rutas.acceso),
      ),
      CfButton(
        label: 'Crear cuenta',
        icon: Icons.person_add_alt_1_rounded,
        variant: CfButtonVariant.outlined,
        expanded: expandido,
        onPressed: () => context.go(Rutas.registro),
      ),
    ];

    return CfCard(
      key: claveTarjeta,
      title: 'Tu cuenta',
      subtitle:
          'Inicia sesión o crea una cuenta para pedir cotizaciones y seguir '
          'tus pedidos.',
      child: expandido
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                botones[0],
                SizedBox(height: tokens.espacioMd),
                botones[1],
              ],
            )
          : Wrap(
              spacing: tokens.espacioMd,
              runSpacing: tokens.espacioMd,
              children: botones,
            ),
    );
  }
}
