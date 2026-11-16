import 'package:flutter/material.dart';

import 'cf_input_text.dart';

/// Campo de contraseña al estilo del Password de PrimeNG (con `toggleMask`).
///
/// Oculta el texto por defecto y tiene un botón accesible para mostrarlo u
/// ocultarlo. Desactiva la autocorrección y las sugerencias del teclado.
class CfPassword extends StatefulWidget {
  const CfPassword({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLength,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final int? maxLength;

  static const textoMostrar = 'Mostrar contraseña';
  static const textoOcultar = 'Ocultar contraseña';

  @override
  State<CfPassword> createState() => _CfPasswordState();
}

class _CfPasswordState extends State<CfPassword> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final texto = _visible ? CfPassword.textoOcultar : CfPassword.textoMostrar;
    return CfInputText(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      helper: widget.helper,
      errorText: widget.errorText,
      validator: widget.validator,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      obscureText: !_visible,
      autocorrect: false,
      enableSuggestions: false,
      prefixIcon: Icons.lock_outline_rounded,
      // Accesible con el teclado (Tab) y con lector de pantalla.
      suffix: IconButton(
        tooltip: texto,
        onPressed: widget.enabled
            ? () => setState(() => _visible = !_visible)
            : null,
        icon: Icon(
          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          semanticLabel: texto,
        ),
      ),
    );
  }
}
