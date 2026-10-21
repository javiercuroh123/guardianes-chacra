import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres de los artboards `Hondero` y `GorgojoPeek` (ver
/// `docs/UI_RIVE.md`). Solo tienen `reduceMotion`.
abstract final class MascotsRive {
  static const hondero = 'Hondero';
  static const gorgojoPeek = 'GorgojoPeek';

  static const double honderoAspect = 200 / 300;
  static const Size gorgojoSize = Size(140, 110);
}

/// El hondero de cuerpo entero: respira, parpadea y hace girar la honda.
/// Es decoración: TalkBack no lo lee y sin el archivo de Rive no se ve.
class RiveHondero extends ConsumerStatefulWidget {
  const new({this.height = 240, super.key});

  final double height;

  @override
  ConsumerState<RiveHondero> createState() => _RiveHonderoState();
}

class _RiveHonderoState extends ConsumerState<RiveHondero>
    with RiveBindingState<RiveHondero> {
  @override
  String get artboardName => MascotsRive.hondero;

  @override
  void bind(RiveBinding binding) {}

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.height * MascotsRive.honderoAspect,
        height: widget.height,
        child: binding.widget(),
      ),
    );
  }
}

/// Un gorgojo que de vez en cuando se asoma entre las hojas, mira a los
/// lados y se esconde. Es decoración: TalkBack no lo lee y sin el archivo
/// de Rive no se ve. Con [mirrored], mira hacia el otro lado.
class RiveGorgojoPeek extends ConsumerStatefulWidget {
  const new({this.width = 120, this.mirrored = false, super.key});

  final double width;
  final bool mirrored;

  @override
  ConsumerState<RiveGorgojoPeek> createState() => _RiveGorgojoPeekState();
}

class _RiveGorgojoPeekState extends ConsumerState<RiveGorgojoPeek>
    with RiveBindingState<RiveGorgojoPeek> {
  @override
  String get artboardName => MascotsRive.gorgojoPeek;

  @override
  void bind(RiveBinding binding) {}

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) return const SizedBox.shrink();
    const size = MascotsRive.gorgojoSize;
    return ExcludeSemantics(
      child: Transform.flip(
        flipX: widget.mirrored,
        child: SizedBox(
          width: widget.width,
          height: widget.width * size.height / size.width,
          child: binding.widget(),
        ),
      ),
    );
  }
}
