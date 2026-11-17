import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/cf_tokens.dart';
import 'cf_button.dart';

/// Diálogo de confirmación al estilo del ConfirmDialog de PrimeNG.
///
/// Se abre con [CfConfirmDialog.mostrar], que devuelve `true` si la usuaria
/// confirma y `false` si cancela o cierra el diálogo.
class CfConfirmDialog extends StatelessWidget {
  const CfConfirmDialog({
    required this.titulo,
    required this.mensaje,
    this.textoConfirmar = 'Aceptar',
    this.textoCancelar = 'Cancelar',
    this.peligro = false,
    this.icono,
    super.key,
  });

  final String titulo;
  final String mensaje;
  final String textoConfirmar;
  final String textoCancelar;

  /// Acción delicada (cerrar sesión, eliminar…): botón de peligro.
  final bool peligro;
  final IconData? icono;

  static const claveConfirmar = ValueKey('cf-confirm-aceptar');
  static const claveCancelar = ValueKey('cf-confirm-cancelar');

  /// Muestra el diálogo y espera la respuesta.
  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Aceptar',
    String textoCancelar = 'Cancelar',
    bool peligro = false,
    IconData? icono,
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (_) => CfConfirmDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoConfirmar: textoConfirmar,
        textoCancelar: textoCancelar,
        peligro: peligro,
        icono: icono,
      ),
    );
    return respuesta ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;
    final simbolo =
        icono ??
        (peligro ? Icons.warning_amber_rounded : Icons.help_outline_rounded);

    return Dialog(
      insetPadding: EdgeInsets.all(tokens.espacioXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.all(tokens.espacioXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      simbolo,
                      size: 28,
                      color: peligro
                          ? AppColors.primario
                          : AppColors.complementario,
                    ),
                  ),
                  SizedBox(width: tokens.espacioMd),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(titulo, style: textos.titleLarge),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.espacioLg),
              Text(mensaje, style: textos.bodyLarge),
              SizedBox(height: tokens.espacioXl),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: tokens.espacioSm,
                runSpacing: tokens.espacioSm,
                children: [
                  CfButton(
                    key: claveCancelar,
                    label: textoCancelar,
                    variant: CfButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  CfButton(
                    key: claveConfirmar,
                    label: textoConfirmar,
                    variant: peligro
                        ? CfButtonVariant.danger
                        : CfButtonVariant.primary,
                    icon: peligro ? simbolo : null,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
