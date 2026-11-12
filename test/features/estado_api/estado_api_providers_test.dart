import 'package:creafacil_app/features/estado_api/data/estado_api_repository_impl.dart';
import 'package:creafacil_app/features/estado_api/presentation/estado_api_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el repositorio por defecto consulta la API real con Dio', () {
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    expect(
      contenedor.read(estadoApiRepositoryProvider),
      isA<EstadoApiRepositoryImpl>(),
    );
  });
}
