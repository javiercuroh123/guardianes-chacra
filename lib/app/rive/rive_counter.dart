import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Counter` (ver `docs/UI_RIVE.md`).
abstract final class CounterRive {
  static const artboard = 'Counter';
  static const viewModel = 'Counter';

  /// El número ya formateado por Dart.
  static const value = 'value';

  /// Subió: el ícono rebota, el número destella en verde y flota [delta].
  static const gain = 'gain';

  /// Bajó: el número destella en rojo y el ícono tiembla.
  static const loss = 'loss';

  /// El `IconSet` anidado (maíz, papa…).
  static const icon = 'icon';

  /// El "+N" que flota al subir, ya formateado.
  static const delta = 'delta';

  /// Aviso de peligro (pocas papas): un pulso rojo, quieto si se pidió
  /// menos movimiento.
  static const danger = 'danger';
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
    this.icon = RiveIcon.corn,
    this.danger = false,
    this.useSharedTexture = false,
    super.key,
  });

  final int value;
  final String semanticsLabel;
  final Widget fallback;
  final RiveIcon icon;
  final bool danger;

  /// Dibuja en la textura del `RivePanel` de arriba en lugar de en una
  /// propia. Con el renderer de Flutter no tiene efecto.
  final bool useSharedTexture;

  /// Alto de la pastilla a escala de letra 1; crece con la letra grande (el
  /// HUD la limita). El "+N" flota debajo, fuera de ese alto, sin empujar
  /// lo que haya alrededor.
  static const double height = 34;

  // El artboard mide 104 × 60: la pastilla ocupa los 35 de arriba y el
  // "+N" sale en el resto.
  static const double _pillAspect = 104 / 35;
  static const double _fullHeight = 60 / 35;

  @override
  ConsumerState<RiveCounter> createState() => _RiveCounterState();
}

class _RiveCounterState extends ConsumerState<RiveCounter>
    with RiveBindingState<RiveCounter> {
  rive.ViewModelInstanceString? _value;
  rive.ViewModelInstanceString? _delta;
  rive.ViewModelInstanceBoolean? _danger;
  rive.ViewModelInstanceEnum? _icon;
  rive.ViewModelInstanceTrigger? _gain;
  rive.ViewModelInstanceTrigger? _loss;

  @override
  String get artboardName => CounterRive.artboard;

  @override
  void bind(RiveBinding binding) {
    _value = binding.string(CounterRive.value)..value = '${widget.value}';
    _delta = binding.string(CounterRive.delta);
    _danger = binding.boolean(CounterRive.danger)..value = widget.danger;
    _icon = binding.icon(CounterRive.icon)..value = widget.icon.name;
    _gain = binding.trigger(CounterRive.gain);
    _loss = binding.trigger(CounterRive.loss);
  }

  @override
  void didUpdateWidget(RiveCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding == null) return;
    if (widget.icon != oldWidget.icon) _icon?.value = widget.icon.name;
    if (widget.danger != oldWidget.danger) _danger?.value = widget.danger;
    final change = widget.value - oldWidget.value;
    if (change == 0) return;
    _value?.value = '${widget.value}';
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (change > 0) {
      _delta?.value = '+$change';
      _gain?.trigger();
    } else {
      _loss?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final Widget child;
    if (binding == null) {
      child = widget.fallback;
    } else {
      final height = MediaQuery.textScalerOf(context).scale(RiveCounter.height);
      final width = height * RiveCounter._pillAspect;
      final controller = binding.controller;
      child = SizedBox(
        width: width,
        height: height,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: height * RiveCounter._fullHeight,
          child: rive.RiveWidget(
            controller: controller,
            hitTestBehavior: rive.RiveHitTestBehavior.none,
            // La textura compartida solo existe con el renderer de Rive; con
            // el de Flutter, RiveWidget mostraría un error en su lugar.
            useSharedTexture:
                widget.useSharedTexture &&
                controller.artboard.riveFactory != rive.Factory.flutter,
          ),
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
