import 'package:flutter_test/flutter_test.dart';

import '../../tool/cobertura.dart';

void main() {
  group('normalizarRuta', () {
    test('convierte rutas de Windows y absolutas a lib/...', () {
      expect(normalizarRuta(r'lib\core\app.dart'), 'lib/core/app.dart');
      expect(
        normalizarRuta(r'C:\Proyectos\repo\lib\main.dart'),
        'lib/main.dart',
      );
      expect(normalizarRuta('/home/runner/repo/lib/a.dart'), 'lib/a.dart');
      expect(normalizarRuta('lib/a.dart'), 'lib/a.dart');
    });
  });

  group('estaExcluido', () {
    test('excluye solo el código generado', () {
      expect(estaExcluido('lib/modelo.g.dart'), isTrue);
      expect(estaExcluido('lib/modelo.freezed.dart'), isTrue);
      expect(estaExcluido('lib/generated/intl.dart'), isTrue);
      expect(estaExcluido('lib/core/network/api_client.dart'), isFalse);
      expect(estaExcluido('lib/features/dev/componentes_page.dart'), isFalse);
    });
  });

  group('analizarLcov', () {
    const lcov = '''
SF:lib\\core\\a.dart
DA:1,3
DA:2,0
DA:3,1
LF:3
LH:2
end_of_record
SF:lib/modelo.g.dart
DA:1,0
end_of_record
SF:test/helpers/x.dart
DA:1,0
end_of_record
SF:lib/b.dart
DA:5,0
DA:6,0,abc123
end_of_record
''';

    test('cuenta las líneas de lib/ sin generados ni pruebas', () {
      final archivos = analizarLcov(lcov);

      expect(archivos.map((a) => a.ruta), ['lib/b.dart', 'lib/core/a.dart']);
      final a = archivos.last;
      expect(a.lineas, 3);
      expect(a.cubiertas, 2);
      expect(a.porcentaje, closeTo(66.67, 0.01));
      expect(archivos.first.cubiertas, 0);
      expect(archivos.first.lineas, 2);
    });

    test('un archivo sin líneas cuenta como cubierto', () {
      expect(CoberturaArchivo('lib/vacio.dart').porcentaje, 100);
      expect(analizarLcov(''), isEmpty);
    });
  });
}
