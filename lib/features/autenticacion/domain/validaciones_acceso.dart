import 'dart:convert';

/// Validaciones de los formularios de acceso [RNF-05].
///
/// Son las mismas reglas que aplica el servidor (`auth.schemas.ts`), con sus
/// mismos mensajes. El servidor vuelve a validarlo todo (RNF-04): esto solo
/// evita viajes inútiles y da respuesta inmediata a la usuaria.
abstract final class ValidacionesAcceso {
  static const nombreMinimo = 2;
  static const nombreMaximo = 120;
  static const emailMaximo = 254;
  static const passwordMinimo = 8;
  static const passwordMaximo = 72;

  /// Mismo patrón que `z.email()` de Zod 4 (el que usa el servidor).
  static final _patronEmail = RegExp(
    r"^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@"
    r'([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$',
  );

  /// `+` opcional y de 7 a 15 dígitos, una vez quitados los separadores.
  static final _patronTelefono = RegExp(r'^\+?\d{7,15}$');
  static final _separadoresTelefono = RegExp(r'[\s\-()]');

  static String? nombre(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return 'El nombre es obligatorio';
    }
    if (texto.length < nombreMinimo) {
      return 'El nombre debe tener al menos $nombreMinimo caracteres';
    }
    if (texto.length > nombreMaximo) {
      return 'El nombre no puede superar $nombreMaximo caracteres';
    }
    return null;
  }

  static String? email(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    if (texto.length > emailMaximo) {
      return 'El correo electrónico no puede superar $emailMaximo caracteres';
    }
    if (!_patronEmail.hasMatch(texto)) {
      return 'El correo electrónico no es válido';
    }
    return null;
  }

  /// Contraseña del registro: de 8 a 72 caracteres y como máximo 72 bytes
  /// (bcrypt solo usa los primeros 72 bytes).
  static String? passwordNueva(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (texto.length < passwordMinimo) {
      return 'La contraseña debe tener al menos $passwordMinimo caracteres';
    }
    if (texto.length > passwordMaximo) {
      return 'La contraseña no puede superar $passwordMaximo caracteres';
    }
    if (utf8.encode(texto).length > passwordMaximo) {
      return 'La contraseña es demasiado larga: usa menos caracteres '
          'especiales (máximo $passwordMaximo bytes)';
    }
    return null;
  }

  /// Contraseña del inicio de sesión: solo se exige que no esté vacía.
  static String? passwordAcceso(String? valor) =>
      (valor ?? '').isEmpty ? 'La contraseña es obligatoria' : null;

  /// La confirmación debe coincidir con la contraseña. No se envía a la API.
  static String? confirmacion(String? valor, String password) {
    if ((valor ?? '').isEmpty) {
      return 'Confirma la contraseña';
    }
    if (valor != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Teléfono opcional: vacío es válido.
  static String? telefono(String? valor) {
    final normalizado = normalizarTelefono(valor);
    if (normalizado == null) {
      return null;
    }
    if (!_patronTelefono.hasMatch(normalizado)) {
      return 'El teléfono debe tener de 7 a 15 dígitos (puede empezar por + '
          'y llevar espacios o guiones)';
    }
    return null;
  }

  /// Quita espacios, guiones y paréntesis. Devuelve `null` si queda vacío.
  static String? normalizarTelefono(String? valor) {
    final limpio = (valor ?? '').replaceAll(_separadoresTelefono, '');
    return limpio.isEmpty ? null : limpio;
  }
}
