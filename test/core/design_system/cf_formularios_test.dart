import 'package:creafacil_app/core/design_system/cf_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/envolver.dart';

void main() {
  group('CfInputText', () {
    testWidgets('muestra etiqueta, ayuda, valida y envía con Enter', (
      tester,
    ) async {
      final formulario = GlobalKey<FormState>();
      String? enviado;
      final controlador = TextEditingController();
      addTearDown(controlador.dispose);
      await montar(
        tester,
        SizedBox(
          width: 320,
          child: Form(
            key: formulario,
            child: CfInputText(
              label: 'Nombre',
              helper: 'Tu nombre completo',
              controller: controlador,
              prefixIcon: Icons.person,
              maxLength: 5,
              validator: (v) => (v ?? '').isEmpty ? 'Obligatorio' : null,
              onSubmitted: (v) => enviado = v,
            ),
          ),
        ),
      );
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Tu nombre completo'), findsOneWidget);

      formulario.currentState!.validate();
      await tester.pump();
      expect(find.text('Obligatorio'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Ana Pérez');
      expect(controlador.text, 'Ana P', reason: 'respeta maxLength');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(enviado, 'Ana P');
    });

    testWidgets('el error del servidor se muestra en el campo', (tester) async {
      await montar(
        tester,
        const SizedBox(
          width: 320,
          child: CfInputText(label: 'Correo', errorText: 'Ya existe'),
        ),
      );
      expect(find.text('Ya existe'), findsOneWidget);
    });
  });

  group('CfPassword', () {
    testWidgets('oculta el texto y lo muestra u oculta con el botón', (
      tester,
    ) async {
      await montar(
        tester,
        const SizedBox(width: 320, child: CfPassword(label: 'Contraseña')),
      );
      EditableText campo() => tester.widget(find.byType(EditableText));

      expect(campo().obscureText, isTrue);
      expect(campo().autocorrect, isFalse);
      await tester.tap(find.byTooltip(CfPassword.textoMostrar));
      await tester.pump();
      expect(campo().obscureText, isFalse);
      expect(find.byTooltip(CfPassword.textoOcultar), findsOneWidget);
      await tester.tap(find.byTooltip(CfPassword.textoOcultar));
      await tester.pump();
      expect(campo().obscureText, isTrue);
    });

    testWidgets('deshabilitado no deja mostrar la contraseña', (tester) async {
      await montar(
        tester,
        const SizedBox(
          width: 320,
          child: CfPassword(label: 'Contraseña', enabled: false),
        ),
      );
      final boton = tester.widget<IconButton>(find.byType(IconButton));
      expect(boton.onPressed, isNull);
    });
  });

  group('CfConfirmDialog', () {
    Future<bool?> abrir(WidgetTester tester, {required bool peligro}) async {
      bool? respuesta;
      await montar(
        tester,
        Builder(
          builder: (context) => CfButton(
            label: 'Abrir',
            onPressed: () async => respuesta = await CfConfirmDialog.mostrar(
              context,
              titulo: 'Cerrar sesión',
              mensaje: '¿Seguro?',
              textoConfirmar: 'Sí, cerrar',
              peligro: peligro,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('¿Seguro?'), findsOneWidget);
      return respuesta;
    }

    testWidgets('confirmar devuelve true', (tester) async {
      bool? respuesta;
      await montar(
        tester,
        Builder(
          builder: (context) => CfButton(
            label: 'Abrir',
            onPressed: () async => respuesta = await CfConfirmDialog.mostrar(
              context,
              titulo: 'Título',
              mensaje: 'Mensaje',
              peligro: true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CfConfirmDialog.claveConfirmar));
      await tester.pumpAndSettle();
      expect(respuesta, isTrue);
    });

    testWidgets('cancelar devuelve false', (tester) async {
      await abrir(tester, peligro: false);
      await tester.tap(find.byKey(CfConfirmDialog.claveCancelar));
      await tester.pumpAndSettle();
      expect(find.text('¿Seguro?'), findsNothing);
    });

    testWidgets('cerrar tocando fuera equivale a cancelar', (tester) async {
      await abrir(tester, peligro: true);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('¿Seguro?'), findsNothing);
    });
  });
}
