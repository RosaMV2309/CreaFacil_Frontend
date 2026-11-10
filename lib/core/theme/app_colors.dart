import 'package:flutter/painting.dart';

/// Paleta oficial de CreaFácil. Es el único lugar donde se definen colores.
abstract final class AppColors {
  /// Rosa coral: botones principales y acciones importantes.
  static const primario = Color(0xFFE95778);

  /// Rosa pastel: tarjetas, fondos secundarios y elementos decorativos.
  static const secundario = Color(0xFFF7B8CE);

  /// Amarillo dorado: solo detalles y acentos, nunca como texto.
  static const terciario = Color(0xFFE8B94F);

  /// Azul artesanal: navegación y elementos que necesitan contraste.
  static const complementario = Color(0xFF244A68);

  /// Crema: fondo general.
  static const fondo = Color(0xFFFFF8F5);

  /// Texto principal.
  static const texto = Color(0xFF51434A);

  static const blanco = Color(0xFFFFFFFF);

  /// Bordes y divisores.
  static const borde = Color(0xFFEADCE1);
}
