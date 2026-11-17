import 'package:creafacil_app/features/autenticacion/domain/politica_acceso.dart';
import 'package:creafacil_app/features/autenticacion/domain/usuario.dart';
import 'package:creafacil_app/features/autenticacion/domain/validaciones_acceso.dart';
import 'package:creafacil_app/features/autenticacion/presentation/configuracion_acceso.dart';
import 'package:creafacil_app/features/autenticacion/presentation/estado_sesion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/sesion_falsa.dart';

void main() {
  group('RolUsuario y Usuario', () {
    test('lee los roles del contrato de la API', () {
      expect(RolUsuario.desdeApi('ADMIN'), RolUsuario.admin);
      expect(RolUsuario.desdeApi('CLIENTE'), RolUsuario.cliente);
      expect(RolUsuario.desdeApi('admin'), isNull);
      expect(RolUsuario.desdeApi(null), isNull);
      expect(RolUsuario.cliente.etiqueta, 'Cliente');
      expect(RolUsuario.admin.etiqueta, 'Administradora');
    });

    test('igualdad, roles y texto', () {
      final copia = Usuario(
        id: clientePrueba.id,
        nombre: clientePrueba.nombre,
        email: clientePrueba.email,
        telefono: clientePrueba.telefono,
        rol: RolUsuario.values.byName('cliente'),
      );
      expect(copia, clientePrueba);
      expect(copia.hashCode, clientePrueba.hashCode);
      expect(copia.esCliente, isTrue);
      expect(copia.esAdmin, isFalse);
      expect(adminPrueba.esAdmin, isTrue);
      expect(copia.toString(), contains('CLIENTE'));
    });
  });

  group('Sesion', () {
    test('caduca al llegar a expiraEn', () {
      final sesion = sesionPrueba();
      expect(sesion.expiradaEn(ahoraPrueba), isFalse);
      expect(sesion.expiradaEn(sesion.expiraEn), isTrue);
      expect(
        sesion.expiradaEn(sesion.expiraEn.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('conUsuario conserva token y caducidad', () {
      final sesion = sesionPrueba();
      final otra = sesion.conUsuario(adminPrueba);
      expect(otra.token, sesion.token);
      expect(otra.expiraEn, sesion.expiraEn);
      expect(otra.usuario, adminPrueba);
      expect(otra == sesion, isFalse);
      expect(sesion, sesionPrueba());
      expect(sesion.hashCode, sesionPrueba().hashCode);
    });

    test('nunca muestra el token completo', () {
      final sesion = sesionPrueba(token: 'abcdefghijklmnop');
      expect(sesion.toString(), isNot(contains('abcdefghijklmnop')));
      expect(sesion.tokenEnmascarado, 'abcd…(oculto)');
      expect(sesionPrueba(token: 'corto').tokenEnmascarado, '****');
    });
  });

  group('PoliticaAcceso de la app móvil', () {
    test('solo clientes; la ADMIN recibe el mensaje aprobado', () {
      final politica = PoliticaAcceso(
        rolPermitido: politicaAccesoDeLaApp.rolPermitido,
        mensajeRechazo: politicaAccesoDeLaApp.mensajeRechazo,
      );
      expect(politica.permite(RolUsuario.cliente), isTrue);
      expect(politica.permite(RolUsuario.admin), isFalse);
      expect(
        politica.mensajeRechazo,
        'Esta app es para clientes. Usa el panel administrativo.',
      );
      final error = AccesoRechazadoException(politica.mensajeRechazo);
      expect(error.toString(), contains('panel administrativo'));
    });
  });

  test('EstadoSesion', () {
    final estado = EstadoSesion(sesion: sesionPrueba(), aviso: 'x');
    expect(estado.iniciada, isTrue);
    expect(estado.usuario, clientePrueba);
    expect(estado, EstadoSesion(sesion: sesionPrueba(), aviso: 'x'));
    expect(
      estado.hashCode,
      EstadoSesion(sesion: sesionPrueba(), aviso: 'x').hashCode,
    );
    expect(const EstadoSesion().iniciada, isFalse);
    expect(const EstadoSesion().toString(), contains('sin sesión'));
  });

  group('ValidacionesAcceso (mismas reglas que el servidor)', () {
    test('nombre de 2 a 120 caracteres', () {
      expect(ValidacionesAcceso.nombre(''), 'El nombre es obligatorio');
      expect(ValidacionesAcceso.nombre(null), 'El nombre es obligatorio');
      expect(ValidacionesAcceso.nombre(' a '), contains('al menos 2'));
      expect(ValidacionesAcceso.nombre('a' * 121), contains('120'));
      expect(ValidacionesAcceso.nombre('Ana'), isNull);
    });

    test('correo', () {
      expect(
        ValidacionesAcceso.email(''),
        'El correo electrónico es obligatorio',
      );
      expect(
        ValidacionesAcceso.email('ana@'),
        'El correo electrónico no es válido',
      );
      expect(ValidacionesAcceso.email('ana..x@correo.com'), isNotNull);
      expect(ValidacionesAcceso.email('${'a' * 250}@x.com'), contains('254'));
      expect(ValidacionesAcceso.email(' Ana.P+1@Correo.com '), isNull);
    });

    test('contraseña nueva de 8 a 72 caracteres y 72 bytes', () {
      expect(
        ValidacionesAcceso.passwordNueva(''),
        'La contraseña es obligatoria',
      );
      expect(
        ValidacionesAcceso.passwordNueva('1234567'),
        'La contraseña debe tener al menos 8 caracteres',
      );
      expect(ValidacionesAcceso.passwordNueva('a' * 73), contains('72'));
      expect(ValidacionesAcceso.passwordNueva('ñ' * 40), contains('bytes'));
      expect(ValidacionesAcceso.passwordNueva('secreta123'), isNull);
    });

    test('contraseña de acceso y confirmación', () {
      expect(ValidacionesAcceso.passwordAcceso(''), isNotNull);
      expect(ValidacionesAcceso.passwordAcceso('x'), isNull);
      expect(
        ValidacionesAcceso.confirmacion('', 'a'),
        'Confirma la contraseña',
      );
      expect(
        ValidacionesAcceso.confirmacion('b', 'a'),
        'Las contraseñas no coinciden',
      );
      expect(ValidacionesAcceso.confirmacion('a', 'a'), isNull);
    });

    test('teléfono opcional: + y de 7 a 15 dígitos, sin separadores', () {
      expect(ValidacionesAcceso.telefono(''), isNull);
      expect(ValidacionesAcceso.telefono(null), isNull);
      expect(ValidacionesAcceso.telefono('+593 99 123-4567'), isNull);
      expect(ValidacionesAcceso.telefono('(04) 234-5678'), isNull);
      expect(ValidacionesAcceso.telefono('123'), contains('7 a 15'));
      expect(ValidacionesAcceso.telefono('09912abc'), isNotNull);
      expect(
        ValidacionesAcceso.normalizarTelefono('+593 (99) 123-4567'),
        '+593991234567',
      );
      expect(ValidacionesAcceso.normalizarTelefono(' - '), isNull);
    });
  });
}
