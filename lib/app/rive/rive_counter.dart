import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_ui.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Counter` (ver `docs/UI_RIVE.md`).
abstract final class CounterRive {
  static const artboard = 'Counter';
  static const viewModel = 'Counter';

  /// El número ya formateado por Dart.
  static const value = 'value';

  /// Subió: el ícono rebota y el número destella en verde.
  static const gain = 'gain';

  /// Bajó: el número destella en rojo y el ícono tiembla.
  static const loss = 'loss';
}

/// Una pastilla del HUD con ícono y número, animada en Rive. Si el archivo
/// de Rive no está, muestra [fallback] (el aspecto de Flutter).
///
/// El número cambia desde afuera: al subir o bajar dispara la animación,
/// salvo que el teléfono pida menos movimiento.
class RiveCounter extends ConsumerStatefulWidget {
  const new({
    required this.value,
    required this.semanticsLabel,
    required this.fallback,
    this.useSharedTexture = false,
    super.key,
  });

  final int value;
  final String semanticsLabel;
  final Widget fallback;

  /// Dibuja en la textura del `RivePanel` de arriba en lugar de en una
  /// propia. Con el renderer de Flutter no tiene efecto.
  final bool useSharedTexture;

  /// Alto a escala de letra 1; crece con la letra grande (el HUD la limita).
  static const double height = 34;
  static const double _aspect = 104 / 38;

  @override
  ConsumerState<RiveCounter> createState() => _RiveCounterState();
}

class _RiveCounterState extends ConsumerState<RiveCounter> {
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _viewModel;
  rive.ViewModelInstanceString? _value;
  rive.ViewModelInstanceTrigger? _gain;
  rive.ViewModelInstanceTrigger? _loss;

  @override
  void initState() {
    super.initState();
    if (ref.read(riveFileProvider) case final file?) _attach(file);
  }

  void _attach(rive.File file) {
    try {
      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName(CounterRive.artboard),
        stateMachineSelector: rive.StateMachineSelector.byName(
          RiveUi.stateMachine,
        ),
      );
      final viewModel = controller.dataBind(rive.DataBind.auto());
      _controller = controller;
      _viewModel = viewModel;
      _value = viewModel.string(CounterRive.value)?..value = '${widget.value}';
      _gain = viewModel.trigger(CounterRive.gain);
      _loss = viewModel.trigger(CounterRive.loss);
    } on Object catch (error) {
      // Un artboard o una propiedad que falta: mejor el respaldo que nada.
      debugPrint('Rive: ${CounterRive.artboard} no está completo ($error).');
      _detach();
    }
  }

  void _detach() {
    _viewModel?.dispose();
    _controller?.dispose();
    _controller = null;
    _viewModel = null;
    _value = null;
    _gain = null;
    _loss = null;
  }

  @override
  void didUpdateWidget(RiveCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = _value;
    if (value == null || widget.value == oldWidget.value) return;
    value.value = '${widget.value}';
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (widget.value > oldWidget.value) {
      _gain?.trigger();
    } else {
      _loss?.trigger();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final Widget child;
    if (controller == null) {
      child = widget.fallback;
    } else {
      final height = MediaQuery.textScalerOf(context).scale(RiveCounter.height);
      child = SizedBox(
        height: height,
        width: height * RiveCounter._aspect,
        child: rive.RiveWidget(
          controller: controller,
          // La textura compartida solo existe con el renderer de Rive; con
          // el de Flutter, RiveWidget mostraría un error en su lugar.
          useSharedTexture:
              widget.useSharedTexture &&
              controller.artboard.riveFactory != rive.Factory.flutter,
        ),
      );
    }
    return Semantics(
      label: widget.semanticsLabel,
      excludeSemantics: true,
      child: child,
    );
  }
}
