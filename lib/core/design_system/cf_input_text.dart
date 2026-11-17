import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de texto al estilo del InputText de PrimeNG [RNF-05].
///
/// - Etiqueta, ayuda y error visibles (con el tema de CreaFácil).
/// - [validator] para la validación en el cliente y [errorText] para un error
///   que llega del servidor (por ejemplo, los detalles por campo de un 400).
/// - Admite *autofill* ([autofillHints]), acción del teclado y envío con
///   Enter ([onSubmitted]).
class CfInputText extends StatelessWidget {
  const CfInputText({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffix,
    this.focusNode,
    this.enabled = true,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.inputFormatters,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// Texto de ayuda bajo el campo (por ejemplo, el formato esperado).
  final String? helper;

  /// Error impuesto desde fuera (servidor). Tiene prioridad sobre [validator].
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;

  /// Widget al final del campo (por ejemplo, mostrar u ocultar la contraseña).
  final Widget? suffix;
  final FocusNode? focusNode;
  final bool enabled;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;

  /// Longitud máxima que se deja escribir (sin contador visible).
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: enabled ? autofillHints : null,
      validator: validator,
      forceErrorText: errorText,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }
}
