import 'package:creafacil_app/features/contacto/data/abridor_enlaces.dart';
import 'package:creafacil_app/features/contacto/presentation/boton_whatsapp.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Canal que usa url_launcher en las pruebas (implementación por defecto).
const _canal = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => mensajero.setMockMethodCallHandler(_canal, null));

  group('AbridorEnlacesUrlLauncher', () {
    final enlace = Uri.parse('https://wa.me/593999999999');

    test('abre el enlace fuera de la app y devuelve true', () async {
      final llamadas = <MethodCall>[];
      mensajero.setMockMethodCallHandler(_canal, (llamada) async {
        llamadas.add(llamada);
        return true;
      });

      final abierto = await const AbridorEnlacesUrlLauncher().abrir(enlace);

      expect(abierto, isTrue);
      expect(llamadas, hasLength(1));
      final argumentos = llamadas.single.arguments as Map<Object?, Object?>;
      expect(argumentos['url'], enlace.toString());
    });

    test('devuelve false si la plataforma no puede abrirlo', () async {
      mensajero.setMockMethodCallHandler(_canal, (_) async => false);

      expect(await const AbridorEnlacesUrlLauncher().abrir(enlace), isFalse);
    });

    test('devuelve false (sin lanzar) si la plataforma falla', () async {
      mensajero.setMockMethodCallHandler(
        _canal,
        (_) async => throw PlatformException(code: 'ERROR'),
      );

      expect(await const AbridorEnlacesUrlLauncher().abrir(enlace), isFalse);
    });
  });

  test('abridorEnlacesProvider usa url_launcher por defecto', () {
    final contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);

    expect(
      contenedor.read(abridorEnlacesProvider),
      isA<AbridorEnlacesUrlLauncher>(),
    );
  });
}
