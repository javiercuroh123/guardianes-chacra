import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Curtain` (ver `docs/UI_RIVE.md`).
abstract final class CurtainRive {
  static const artboard = 'Curtain';
  static const viewModel = 'Curtain';

  /// Cuánto tapa la cortina: 0 abierta (los paños fuera de la pantalla),
  /// 100 cerrada (los paños juntos y el rombo del centro). Rive lo
  /// convierte en la posición de los paños y en el tamaño y el giro del
  /// rombo; en el rebote al cerrarse pasa un poco de 100.
  static const cover = 'cover';
}

/// La cortina de tejido andino que tapa la pantalla al cambiar de una a
/// otra (ver `CurtainRoute`). Cubre a su padre, no recibe toques y TalkBack
/// no la lee.
///
/// Sigue a [progress], el avance de la ruta (de 0 a 1): se cierra en la
/// primera parte, queda cerrada en la mitad y se abre al final; al volver
/// (de 1 a 0) hace lo mismo al revés. El tiempo lo pone Flutter y no una
/// animación de Rive para que la pantalla se cambie siempre con la cortina
/// cerrada, aunque se pierda un cuadro al armar la pantalla nueva.
///
/// Sin el archivo de Rive, un fundido al ciruela del tejido.
class RiveCurtain extends ConsumerStatefulWidget {
  const new({required this.progress, super.key});

  final Animation<double> progress;

  /// El ciruela del tejido: el color del fundido de respaldo.
  static const color = Color(0xFF8B2055);

  /// Hasta dónde de la ruta se cierra y desde dónde se abre.
  static const closedFrom = 0.42;
  static const closedUntil = 0.58;

  /// Se cierra rápido y frena con un rebote corto (pasa un 3 % de cerrada).
  static const _close = Cubic(0.3, 1.12, 0.55, 1);

  /// Cuánto tapa la cortina (0 abierta, 1 cerrada) cuando la ruta va por
  /// [t]: cerrada de [closedFrom] a [closedUntil], justo cuando se cambia la
  /// pantalla (en 0,5).
  static double coverAt(double t) {
    if (t <= 0 || t >= 1) return 0;
    if (t < closedFrom) return _close.transform(t / closedFrom);
    if (t <= closedUntil) return 1;
    return 1 -
        Curves.easeInCubic.transform((t - closedUntil) / (1 - closedUntil));
  }

  @override
  ConsumerState<RiveCurtain> createState() => _RiveCurtainState();
}

class _RiveCurtainState extends ConsumerState<RiveCurtain>
    with RiveBindingState<RiveCurtain> {
  rive.ViewModelInstanceNumber? _cover;

  @override
  String get artboardName => CurtainRive.artboard;

  double get _value => RiveCurtain.coverAt(widget.progress.value);

  @override
  void bind(RiveBinding binding) {
    _cover = binding.number(CurtainRive.cover)..value = _value * 100;
  }

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_update);
  }

  @override
  void didUpdateWidget(RiveCurtain oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      oldWidget.progress.removeListener(_update);
      widget.progress.addListener(_update);
      _update();
    }
  }

  @override
  void dispose() {
    widget.progress.removeListener(_update);
    super.dispose();
  }

  void _update() {
    final cover = _cover;
    if (cover != null) {
      cover.value = _value * 100;
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: binding == null
            ? ColoredBox(
                color: RiveCurtain.color.withValues(
                  alpha: _value.clamp(0.0, 1.0),
                ),
              )
            : binding.widget(fit: rive.Fit.cover),
      ),
    );
  }
}
