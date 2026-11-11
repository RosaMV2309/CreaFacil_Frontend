// Comprueba el umbral de cobertura de líneas de `lib/` a partir de
// `coverage/lcov.info` (generado con `flutter test --coverage`).
//
// Uso:
//   dart run tool/cobertura.dart                 # umbral por defecto (80 %)
//   dart run tool/cobertura.dart --minimo=85     # otro umbral
//   dart run tool/cobertura.dart --detalle       # cobertura por archivo
//   dart run tool/cobertura.dart --lcov=ruta/lcov.info
//
// Sale con código 0 si se alcanza el umbral, 1 si no se alcanza y 2 si
// falta el informe o los argumentos no son válidos. No usa dependencias
// externas para que funcione igual en Windows y en la CI (RNF-06).
import 'dart:io';

/// Umbral mínimo de cobertura de líneas, en porcentaje.
const double umbralPorDefecto = 80;

/// Archivos que no cuentan para la cobertura.
///
/// Solo se excluye código generado automáticamente: no lo escribe nadie a
/// mano y no tiene sentido exigirle pruebas.
final List<RegExp> exclusiones = <RegExp>[
  RegExp(r'\.g\.dart$'),
  RegExp(r'\.freezed\.dart$'),
  RegExp(r'\.gr\.dart$'),
  RegExp(r'\.mocks\.dart$'),
  RegExp(r'(^|/)generated/'),
  RegExp(r'(^|/)l10n/app_localizations.*\.dart$'),
];

/// Cobertura de un archivo de `lib/`.
class CoberturaArchivo {
  CoberturaArchivo(this.ruta);

  final String ruta;
  int lineas = 0;
  int cubiertas = 0;

  double get porcentaje => lineas == 0 ? 100 : cubiertas * 100 / lineas;
}

/// Normaliza las rutas de Windows (`lib\core\x.dart`) y las absolutas para
/// que queden relativas al proyecto (`lib/core/x.dart`).
String normalizarRuta(String ruta) {
  final unix = ruta.replaceAll(r'\', '/');
  final indice = unix.lastIndexOf('/lib/');
  if (unix.startsWith('lib/')) return unix;
  return indice >= 0 ? unix.substring(indice + 1) : unix;
}

bool estaExcluido(String ruta) => exclusiones.any((e) => e.hasMatch(ruta));

/// Lee el contenido de un `lcov.info` y devuelve la cobertura por archivo de
/// `lib/`, sin los archivos excluidos.
List<CoberturaArchivo> analizarLcov(String contenido) {
  final archivos = <String, CoberturaArchivo>{};
  CoberturaArchivo? actual;
  for (final linea in contenido.split(RegExp(r'\r?\n'))) {
    if (linea.startsWith('SF:')) {
      final ruta = normalizarRuta(linea.substring(3).trim());
      actual = (ruta.startsWith('lib/') && !estaExcluido(ruta))
          ? archivos.putIfAbsent(ruta, () => CoberturaArchivo(ruta))
          : null;
    } else if (linea.startsWith('DA:') && actual != null) {
      // DA:<línea>,<veces ejecutada>[,<checksum>]
      final partes = linea.substring(3).split(',');
      if (partes.length < 2) continue;
      actual.lineas++;
      if ((int.tryParse(partes[1]) ?? 0) > 0) actual.cubiertas++;
    } else if (linea == 'end_of_record') {
      actual = null;
    }
  }
  final lista = archivos.values.toList()
    ..sort((a, b) => a.ruta.compareTo(b.ruta));
  return lista;
}

void main(List<String> args) {
  var minimo = umbralPorDefecto;
  var rutaLcov = 'coverage/lcov.info';
  var detalle = false;

  for (final arg in args) {
    if (arg.startsWith('--minimo=')) {
      final valor = double.tryParse(arg.substring('--minimo='.length));
      if (valor == null || valor < 0 || valor > 100) {
        stderr.writeln('El umbral debe ser un número entre 0 y 100: $arg');
        exit(2);
      }
      minimo = valor;
    } else if (arg.startsWith('--lcov=')) {
      rutaLcov = arg.substring('--lcov='.length);
    } else if (arg == '--detalle') {
      detalle = true;
    } else {
      stderr.writeln('Argumento no reconocido: $arg');
      exit(2);
    }
  }

  final archivo = File(rutaLcov);
  if (!archivo.existsSync()) {
    stderr.writeln(
      'No se encontró $rutaLcov. Ejecuta antes: flutter test --coverage',
    );
    exit(2);
  }

  final cobertura = analizarLcov(archivo.readAsStringSync());
  if (cobertura.isEmpty) {
    stderr.writeln('El informe $rutaLcov no contiene archivos de lib/.');
    exit(2);
  }

  final lineas = cobertura.fold<int>(0, (s, a) => s + a.lineas);
  final cubiertas = cobertura.fold<int>(0, (s, a) => s + a.cubiertas);
  final total = lineas == 0 ? 100.0 : cubiertas * 100 / lineas;

  if (detalle) {
    for (final a in cobertura) {
      final pct = a.porcentaje.toStringAsFixed(1).padLeft(5);
      stdout.writeln('$pct %  ${a.cubiertas}/${a.lineas}  ${a.ruta}');
    }
    stdout.writeln('');
  }

  final texto = total.toStringAsFixed(2);
  final umbral = minimo.toStringAsFixed(0);
  stdout.writeln(
    'Cobertura de líneas de lib/: $texto % '
    '($cubiertas de $lineas líneas, ${cobertura.length} archivos). '
    'Umbral: $umbral %.',
  );
  if (total < minimo) {
    stderr.writeln('ERROR: la cobertura no alcanza el umbral del $umbral %.');
    exit(1);
  }
  stdout.writeln('OK: se alcanza el umbral.');
}
