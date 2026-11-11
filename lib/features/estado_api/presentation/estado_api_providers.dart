import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/red.dart';
import '../data/estado_api_repository_impl.dart';
import '../domain/estado_api.dart';
import '../domain/estado_api_repository.dart';

final estadoApiRepositoryProvider = Provider<EstadoApiRepository>(
  (ref) => EstadoApiRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Estado actual de la API. Para volver a consultar:
/// `ref.invalidate(estadoApiProvider)`.
///
/// Sin reintentos automáticos de Riverpod: la usuaria decide con el botón
/// «Reintentar» y así no se satura una API caída.
final estadoApiProvider = FutureProvider<EstadoApi>(
  (ref) => ref.watch(estadoApiRepositoryProvider).consultar(),
  retry: (intentos, error) => null,
);
