import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/network/red.dart';
import '../../../core/router/rutas.dart';
import '../domain/autenticacion_repository.dart';
import '../domain/politica_acceso.dart';
import '../domain/validaciones_acceso.dart';
import 'autenticacion_providers.dart';
import 'widgets/mensaje_error_api.dart';
import 'widgets/plantilla_acceso.dart';

/// Pantalla «Crear cuenta» del cliente [RF-01][RNF-05].
///
/// Nombre, correo, teléfono opcional, contraseña y confirmación (que solo
/// existe aquí: no se envía a la API). Valida igual que el servidor y muestra
/// los errores por campo del 400 en su campo. Al registrarse, la sesión queda
/// iniciada y el router lleva al destino o al inicio.
class RegistroPage extends ConsumerStatefulWidget {
  const RegistroPage({this.desde, super.key});

  final String? desde;

  static const claveNombre = ValueKey('registro-nombre');
  static const claveEmail = ValueKey('registro-email');
  static const claveTelefono = ValueKey('registro-telefono');
  static const clavePassword = ValueKey('registro-password');
  static const claveConfirmar = ValueKey('registro-confirmar');
  static const claveEnviar = ValueKey('registro-enviar');
  static const claveError = ValueKey('registro-error');
  static const claveIrAcceso = ValueKey('registro-ir-acceso');

  @override
  ConsumerState<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends ConsumerState<RegistroPage> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();

  bool _enviando = false;
  MensajeErrorApi? _error;
  Map<String, String> _erroresCampo = const {};

  @override
  void dispose() {
    for (final c in [_nombre, _email, _telefono, _password, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  void _quitarErrorCampo(String campo) {
    if (_erroresCampo.containsKey(campo)) {
      setState(() => _erroresCampo = {..._erroresCampo}..remove(campo));
    }
  }

  Future<void> _enviar() async {
    if (_enviando) {
      return;
    }
    setState(() {
      _error = null;
      _erroresCampo = const {};
    });
    if (!(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _enviando = true);
    try {
      await ref
          .read(sesionControllerProvider.notifier)
          .registrar(
            DatosRegistro(
              nombre: _nombre.text,
              email: _email.text,
              password: _password.text,
              telefono: _telefono.text,
            ),
          );
      TextInput.finishAutofillContext();
    } on AccesoRechazadoException catch (e) {
      _mostrar(MensajeErrorApi.rechazo(e.mensaje));
    } on ApiException catch (e) {
      _mostrar(MensajeErrorApi.desde(e), e.erroresPorCampo);
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrar(
    MensajeErrorApi error, [
    Map<String, String> campos = const {},
  ]) {
    if (mounted) {
      setState(() {
        _error = error;
        _erroresCampo = campos;
      });
    }
  }

  void _irAcceso() {
    final desde = widget.desde;
    context.go(
      desde == null
          ? Rutas.acceso
          : Uri(
              path: Rutas.acceso,
              queryParameters: {Rutas.parametroDesde: desde},
            ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final espacio = SizedBox(height: tokens.espacioLg);
    final conflicto = _error?.codigo == 'CONFLICTO';

    return PlantillaAcceso(
      titulo: 'Crear cuenta',
      subtitulo: 'Regístrate para pedir cotizaciones y seguir tus pedidos.',
      child: AutofillGroup(
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                CfMessage(
                  key: RegistroPage.claveError,
                  severity: CfMessageSeverity.error,
                  title: _error!.titulo,
                  text: _error!.texto,
                ),
                if (conflicto)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CfButton(
                      key: RegistroPage.claveIrAcceso,
                      label: 'Iniciar sesión con ese correo',
                      icon: Icons.login_rounded,
                      variant: CfButtonVariant.text,
                      onPressed: _irAcceso,
                    ),
                  ),
                espacio,
              ],
              CfInputText(
                key: RegistroPage.claveNombre,
                label: 'Nombre',
                hint: 'Tu nombre y apellido',
                controller: _nombre,
                prefixIcon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                enabled: !_enviando,
                maxLength: ValidacionesAcceso.nombreMaximo,
                validator: ValidacionesAcceso.nombre,
                errorText: _erroresCampo['nombre'],
                onChanged: (_) => _quitarErrorCampo('nombre'),
              ),
              espacio,
              CfInputText(
                key: RegistroPage.claveEmail,
                label: 'Correo electrónico',
                hint: 'nombre@correo.com',
                controller: _email,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enabled: !_enviando,
                maxLength: ValidacionesAcceso.emailMaximo,
                validator: ValidacionesAcceso.email,
                errorText: _erroresCampo['email'],
                onChanged: (_) => _quitarErrorCampo('email'),
              ),
              espacio,
              CfInputText(
                key: RegistroPage.claveTelefono,
                label: 'Teléfono (opcional)',
                hint: '+593 99 123 4567',
                helper: 'De 7 a 15 dígitos; puede empezar por +.',
                controller: _telefono,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                enabled: !_enviando,
                maxLength: 30,
                validator: ValidacionesAcceso.telefono,
                errorText: _erroresCampo['telefono'],
                onChanged: (_) => _quitarErrorCampo('telefono'),
              ),
              espacio,
              CfPassword(
                key: RegistroPage.clavePassword,
                label: 'Contraseña',
                helper: 'De 8 a 72 caracteres.',
                controller: _password,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_enviando,
                maxLength: ValidacionesAcceso.passwordMaximo,
                validator: ValidacionesAcceso.passwordNueva,
                errorText: _erroresCampo['password'],
                onChanged: (_) => _quitarErrorCampo('password'),
              ),
              espacio,
              CfPassword(
                key: RegistroPage.claveConfirmar,
                label: 'Confirmar contraseña',
                controller: _confirmar,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                enabled: !_enviando,
                maxLength: ValidacionesAcceso.passwordMaximo,
                validator: (v) =>
                    ValidacionesAcceso.confirmacion(v, _password.text),
                onSubmitted: (_) => _enviar(),
              ),
              SizedBox(height: tokens.espacioXl),
              CfButton(
                key: RegistroPage.claveEnviar,
                label: _enviando ? 'Creando cuenta…' : 'Crear cuenta',
                icon: Icons.person_add_alt_1_rounded,
                expanded: true,
                loading: _enviando,
                onPressed: _enviar,
              ),
              espacio,
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '¿Ya tienes cuenta?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  CfButton(
                    label: 'Iniciar sesión',
                    variant: CfButtonVariant.text,
                    onPressed: _enviando ? null : _irAcceso,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
