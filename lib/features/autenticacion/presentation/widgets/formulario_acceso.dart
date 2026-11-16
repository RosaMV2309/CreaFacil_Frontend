import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cf_components.dart';
import '../../../../core/network/red.dart';
import '../../domain/politica_acceso.dart';
import '../../domain/validaciones_acceso.dart';
import '../autenticacion_providers.dart';
import 'mensaje_error_api.dart';

/// Formulario de inicio de sesión [RF-01][RNF-05].
///
/// Compartido por la app móvil y el panel: correo, contraseña (con botón para
/// mostrarla), validación en el cliente, errores de la API con [CfMessage] y
/// aviso de sesión expirada. Tras iniciar sesión, el router redirige solo.
class FormularioAcceso extends ConsumerStatefulWidget {
  const FormularioAcceso({this.onCrearCuenta, super.key});

  /// Si se indica, muestra «¿No tienes cuenta? Crear cuenta» (solo la app).
  final VoidCallback? onCrearCuenta;

  static const claveEmail = ValueKey('acceso-email');
  static const clavePassword = ValueKey('acceso-password');
  static const claveEnviar = ValueKey('acceso-enviar');
  static const claveAviso = ValueKey('acceso-aviso');
  static const claveError = ValueKey('acceso-error');

  @override
  ConsumerState<FormularioAcceso> createState() => _FormularioAccesoState();
}

class _FormularioAccesoState extends ConsumerState<FormularioAcceso> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _enviando = false;
  String? _aviso;
  MensajeErrorApi? _error;
  Map<String, String> _erroresCampo = const {};

  @override
  void initState() {
    super.initState();
    _tomarAviso(ref.read(sesionControllerProvider).value?.aviso);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Muestra el aviso una vez y lo descarta del controlador.
  void _tomarAviso(String? aviso) {
    if (aviso == null) {
      return;
    }
    _aviso = aviso;
    Future.microtask(() {
      if (mounted) {
        ref.read(sesionControllerProvider.notifier).descartarAviso();
      }
    });
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
          .iniciarSesion(email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
    } on AccesoRechazadoException catch (e) {
      _mostrarError(MensajeErrorApi.rechazo(e.mensaje));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _erroresCampo = e.erroresPorCampo);
      }
      _mostrarError(MensajeErrorApi.desde(e));
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarError(MensajeErrorApi error) {
    if (mounted) {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    ref.listen(sesionControllerProvider, (_, siguiente) {
      final aviso = siguiente.value?.aviso;
      if (aviso != null && aviso != _aviso) {
        setState(() => _tomarAviso(aviso));
      }
    });

    return AutofillGroup(
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_aviso != null) ...[
              CfMessage(
                key: FormularioAcceso.claveAviso,
                severity: CfMessageSeverity.warning,
                text: _aviso!,
                onClose: () => setState(() => _aviso = null),
              ),
              SizedBox(height: tokens.espacioLg),
            ],
            if (_error != null) ...[
              CfMessage(
                key: FormularioAcceso.claveError,
                severity: CfMessageSeverity.error,
                title: _error!.titulo,
                text: _error!.texto,
              ),
              SizedBox(height: tokens.espacioLg),
            ],
            CfInputText(
              key: FormularioAcceso.claveEmail,
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
            SizedBox(height: tokens.espacioLg),
            CfPassword(
              key: FormularioAcceso.clavePassword,
              label: 'Contraseña',
              controller: _password,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !_enviando,
              maxLength: 200,
              validator: ValidacionesAcceso.passwordAcceso,
              errorText: _erroresCampo['password'],
              onChanged: (_) => _quitarErrorCampo('password'),
              onSubmitted: (_) => _enviar(),
            ),
            SizedBox(height: tokens.espacioXl),
            CfButton(
              key: FormularioAcceso.claveEnviar,
              label: _enviando ? 'Iniciando sesión…' : 'Iniciar sesión',
              icon: Icons.login_rounded,
              expanded: true,
              loading: _enviando,
              onPressed: _enviar,
            ),
            if (widget.onCrearCuenta != null) ...[
              SizedBox(height: tokens.espacioLg),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  CfButton(
                    label: 'Crear cuenta',
                    variant: CfButtonVariant.text,
                    onPressed: _enviando ? null : widget.onCrearCuenta,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
