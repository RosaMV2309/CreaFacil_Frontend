import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/autenticacion/presentation/autenticacion_providers.dart';

void main() {
  runApp(
    // La sesión aporta el token JWT al cliente HTTP [RF-01].
    ProviderScope(
      overrides: overridesAutenticacion,
      child: const CreaFacilApp(),
    ),
  );
}
