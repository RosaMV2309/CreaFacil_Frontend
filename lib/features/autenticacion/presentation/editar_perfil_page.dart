import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/cf_components.dart';
import '../../../core/network/red.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../domain/cambios_perfil.dart';
import '../domain/usuario.dart';
import '../domain/validaciones_acceso.dart';
import 'autenticacion_providers.dart';
import 'proteccion_salida.dart';
import 'widgets/mensaje_error_api.dart';
import 'widgets/plantilla_acceso.dart';

/// «Editar perfil» del cliente (`/perfil/editar`) [RF-01][RN-05][RNF-05].
///
/// - Nombre y teléfono precargados, con las mismas validaciones que el
///   registro (y que el servidor). El correo es de solo lectura.
/// - Envía **solo** lo que cambió (`PATCH /auth/perfil`); sin cambios,
///   «Guardar cambios» queda deshabilitado y no se llama a la API.
/// - «Borrar teléfono» vacía el campo: al guardar se envía `telefono: null`.
/// - Los errores por campo del 400 se muestran en su campo y el resto con
///   [CfMessage]. Un 401 cierra la sesión (lo hace el controlador).
/// - Si hay cambios sin guardar, salir pide confirmación (ver
///   [confirmarSalida] y el `onExit` de la ruta).
class EditarPerfilPage extends ConsumerStatefulWidget {
  const EditarPerfilPage({super.key});

  static const claveNombre = ValueKey('editar-perfil-nombre');
  static const claveTelefono = ValueKey('editar-perfil-telefono');
  static const claveCorreo = ValueKey('editar-perfil-correo');
  static const claveBorrarTelefono = ValueKey('editar-perfil-borrar-telefono');
  static const claveGuardar = ValueKey('editar-perfil-guardar');
  static const claveCancelar = ValueKey('editar-perfil-cancelar');
  static const claveError = ValueKey('editar-perfil-error');
  static const claveSinCambios = ValueKey('editar-perfil-sin-cambios');
  static const claveAvisoGuardado = ValueKey('editar-perfil-aviso-guardado');

  static const notaCorreo = 'El correo no se puede cambiar.';
  static const textoSinCambios = 'No hay cambios para guardar.';
  static const avisoGuardado = 'Tus datos se guardaron correctamente.';
  static const ayudaTelefono = 'De 7 a 15 dígitos; puede empezar por +.';
  static const ayudaTelefonoBorrado =
      'Se borrará tu teléfono al guardar los cambios.';

  /// Pregunta si se descartan los cambios sin guardar. Devuelve `true` si la
  /// persona decide salir.
  static Future<bool> confirmarSalida(BuildContext context) =>
      CfConfirmDialog.mostrar(
        context,
        titulo: '¿Salir sin guardar?',
        mensaje:
            'Tienes cambios sin guardar en tu perfil. Si sales ahora, se '
            'perderán.',
        textoConfirmar: 'Salir sin guardar',
        textoCancelar: 'Seguir editando',
        peligro: true,
      );

  @override
  ConsumerState<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends ConsumerState<EditarPerfilPage> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();

  late final ProteccionSalida _proteccion;

  /// Datos con los que se abrió el formulario (para comparar).
  Usuario? _original;
  bool _enviando = false;
  bool _guardado = false;
  MensajeErrorApi? _error;
  Map<String, String> _erroresCampo = const {};

  static const _camposDelFormulario = {'nombre', 'telefono'};

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(usuarioActualProvider);
    if (usuario != null) {
      _original = usuario;
      _nombre.text = usuario.nombre;
      _telefono.text = usuario.telefono ?? '';
    }
    _nombre.addListener(_alCambiar);
    _telefono.addListener(_alCambiar);
    _proteccion = ref.read(proteccionSalidaPerfilProvider)
      ..registrar(_consultaCambios);
  }

  @override
  void dispose() {
    _proteccion.liberar(_consultaCambios);
    _nombre.dispose();
    _telefono.dispose();
    super.dispose();
  }

  CambiosPerfil? get _cambios {
    final original = _original;
    return original == null
        ? null
        : CambiosPerfil.desdeFormulario(
            original,
            nombre: _nombre.text,
            telefono: _telefono.text,
          );
  }

  bool get _hayCambios => _cambios?.hayCambios ?? false;

  /// Consulta del `onExit` de la ruta: tras guardar ya no hay nada pendiente.
  bool _consultaCambios() => !_guardado && _hayCambios;

  void _alCambiar() {
    if (mounted) {
      setState(() {});
    }
  }

  void _quitarErrorCampo(String campo) {
    if (_erroresCampo.containsKey(campo)) {
      setState(() => _erroresCampo = {..._erroresCampo}..remove(campo));
    }
  }

  void _borrarTelefono() {
    _telefono.clear();
    _quitarErrorCampo('telefono');
  }

  Future<void> _guardar() async {
    final cambios = _cambios;
    if (_enviando || cambios == null || !cambios.hayCambios) {
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
          .actualizarPerfil(cambios);
      if (!mounted) {
        return;
      }
      TextInput.finishAutofillContext();
      _guardado = true;
      final mensajero = ScaffoldMessenger.of(context);
      context.go(Rutas.perfil);
      mensajero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            key: EditarPerfilPage.claveAvisoGuardado,
            content: Text(EditarPerfilPage.avisoGuardado),
          ),
        );
    } on ApiException catch (e) {
      _mostrarError(e);
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  /// Los detalles de `nombre` y `telefono` van a su campo; los demás (por
  /// ejemplo, «Envía al menos un campo…») se añaden al mensaje general.
  void _mostrarError(ApiException e) {
    if (!mounted) {
      return;
    }
    final otros = [
      for (final d in e.detalles)
        if (!_camposDelFormulario.contains(d.campo)) d.mensaje,
    ];
    final base = MensajeErrorApi.desde(e);
    setState(() {
      _erroresCampo = {
        for (final MapEntry(:key, :value) in e.erroresPorCampo.entries)
          if (_camposDelFormulario.contains(key)) key: value,
      };
      _error = otros.isEmpty
          ? base
          : MensajeErrorApi(
              titulo: base.titulo,
              codigo: base.codigo,
              texto: [base.texto, ...otros].join('\n'),
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    final original = _original;
    return PlantillaAcceso(
      titulo: 'Editar perfil',
      subtitulo: 'Actualiza tu nombre y tu teléfono.',
      anchoMaximo: 560,
      volverA: Rutas.perfil,
      textoVolver: 'Volver a Mi perfil',
      child: original == null
          ? const Center(child: CfSpinner(label: 'Cargando tu perfil…'))
          : _formularioEdicion(context, original),
    );
  }

  Widget _formularioEdicion(BuildContext context, Usuario original) {
    final tokens = CfTokens.of(context);
    final espacio = SizedBox(height: tokens.espacioLg);
    final borraTelefono = _cambios?.borraTelefono ?? false;

    return AutofillGroup(
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              CfMessage(
                key: EditarPerfilPage.claveError,
                severity: CfMessageSeverity.error,
                title: _error!.titulo,
                text: _error!.texto,
                onClose: () => setState(() => _error = null),
              ),
              espacio,
            ],
            CfInputText(
              key: EditarPerfilPage.claveNombre,
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
            _CorreoSoloLectura(email: original.email),
            espacio,
            CfInputText(
              key: EditarPerfilPage.claveTelefono,
              label: 'Teléfono (opcional)',
              hint: '+593 99 123 4567',
              helper: borraTelefono
                  ? EditarPerfilPage.ayudaTelefonoBorrado
                  : EditarPerfilPage.ayudaTelefono,
              controller: _telefono,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              enabled: !_enviando,
              maxLength: 30,
              validator: ValidacionesAcceso.telefono,
              errorText: _erroresCampo['telefono'],
              onChanged: (_) => _quitarErrorCampo('telefono'),
              onSubmitted: (_) => _guardar(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CfButton(
                key: EditarPerfilPage.claveBorrarTelefono,
                label: 'Borrar teléfono',
                icon: Icons.phone_disabled_outlined,
                variant: CfButtonVariant.text,
                onPressed: _enviando || _telefono.text.isEmpty
                    ? null
                    : _borrarTelefono,
              ),
            ),
            SizedBox(height: tokens.espacioMd),
            _Acciones(
              enviando: _enviando,
              hayCambios: _hayCambios,
              onGuardar: _guardar,
              onCancelar: () => context.go(Rutas.perfil),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Guardar cambios» (coral) y «Cancelar»: en fila en tablet y escritorio, y
/// apilados a todo el ancho en el móvil.
class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.enviando,
    required this.hayCambios,
    required this.onGuardar,
    required this.onCancelar,
  });

  final bool enviando;
  final bool hayCambios;
  final VoidCallback onGuardar;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final movil = PuntosCorte.deContexto(context) == TamanoPantalla.movil;

    final guardar = CfButton(
      key: EditarPerfilPage.claveGuardar,
      label: enviando ? 'Guardando…' : 'Guardar cambios',
      icon: Icons.save_outlined,
      expanded: movil,
      loading: enviando,
      onPressed: hayCambios ? onGuardar : null,
    );
    final cancelar = CfButton(
      key: EditarPerfilPage.claveCancelar,
      label: 'Cancelar',
      variant: CfButtonVariant.outlined,
      expanded: movil,
      onPressed: enviando ? null : onCancelar,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (movil) ...[
          guardar,
          SizedBox(height: tokens.espacioMd),
          cancelar,
        ] else
          Wrap(
            alignment: WrapAlignment.end,
            spacing: tokens.espacioMd,
            runSpacing: tokens.espacioMd,
            children: [cancelar, guardar],
          ),
        if (!hayCambios && !enviando) ...[
          SizedBox(height: tokens.espacioSm),
          Text(
            EditarPerfilPage.textoSinCambios,
            key: EditarPerfilPage.claveSinCambios,
            textAlign: movil ? TextAlign.center : TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// El correo se muestra pero no se edita (la API no permite cambiarlo).
class _CorreoSoloLectura extends StatelessWidget {
  const _CorreoSoloLectura({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final tokens = CfTokens.of(context);
    final textos = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Container(
        key: EditarPerfilPage.claveCorreo,
        padding: EdgeInsets.symmetric(
          horizontal: tokens.espacioLg,
          vertical: tokens.espacioMd,
        ),
        decoration: BoxDecoration(
          color: AppColors.fondo,
          borderRadius: BorderRadius.circular(tokens.radioSm),
          border: Border.all(color: AppColors.borde),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.complementario,
            ),
            SizedBox(width: tokens.espacioMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Correo electrónico', style: textos.bodySmall),
                  Text(email, style: textos.bodyLarge),
                  SizedBox(height: tokens.espacioXs),
                  Text(EditarPerfilPage.notaCorreo, style: textos.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
