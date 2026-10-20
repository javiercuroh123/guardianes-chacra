import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Panel` (ver `docs/UI_RIVE.md`).
abstract final class PanelRive {
  static const artboard = 'Panel';
  static const viewModel = 'Panel';

  /// Al pasar a `true` el marco cae con un rebote (o aparece, con menos
  /// movimiento); al pasar a `false` baja y se desvanece.
  static const visible = 'visible';
}

/// El marco de madera con guarda tejida, dibujado en Rive, con [child] (de
/// Flutter) adentro. El contenido entra y sale junto con el marco: cae
/// 40 dp con un rebote en 420 ms y sale bajando 24 dp en 200 ms.
///
/// Sin el archivo de Rive es una `Card` del tema con la misma animación.
class RivePanel extends ConsumerStatefulWidget {
  const new({
    required this.child,
    this.visible = true,
    this.padding = const EdgeInsets.fromLTRB(28, 26, 28, 26),
    super.key,
  });

  final Widget child;
  final bool visible;

  /// El espacio entre el borde del marco y [child] (la guarda mide unos 20).
  final EdgeInsets padding;

  static const enter = Duration(milliseconds: 420);
  static const exit = Duration(milliseconds: 200);

  @override
  ConsumerState<RivePanel> createState() => _RivePanelState();
}

class _RivePanelState extends ConsumerState<RivePanel>
    with RiveBindingState<RivePanel> {
  @override
  String get artboardName => PanelRive.artboard;

  @override
  void bind(RiveBinding binding) =>
      binding.boolean(PanelRive.visible).value = widget.visible;

  @override
  void didUpdateWidget(RivePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    binding?.viewModel.boolean(PanelRive.visible)?.value = widget.visible;
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final calm = MediaQuery.disableAnimationsOf(context);
    final content = Padding(padding: widget.padding, child: widget.child);
    if (binding == null) {
      return _Follow(
        visible: widget.visible,
        calm: calm,
        child: Card(child: content),
      );
    }
    // El marco anima en Rive; el contenido lo acompaña desde Flutter.
    return Stack(
      children: [
        Positioned.fill(child: binding.widget(fit: rive.Fit.layout)),
        _Follow(visible: widget.visible, calm: calm, child: content),
      ],
    );
  }
}

/// Mueve y desvanece su hijo como el marco de Rive (`Enter` y `Exit`):
/// cada entrada empieza 40 dp arriba y cada salida termina 24 dp abajo,
/// aunque la anterior no haya terminado. Oculto, no recibe toques.
class _Follow extends StatefulWidget {
  const new({required this.visible, required this.calm, required this.child});

  final bool visible;
  final bool calm;
  final Widget child;

  @override
  State<_Follow> createState() => _FollowState();
}

class _FollowState extends State<_Follow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late bool _entering = widget.visible;

  /// La entrada se ve del todo a los 130 ms, como el marco.
  static const _fadeIn = 130;

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      _play(enter: true);
    } else {
      _controller.value = 1; // Ya salió.
    }
  }

  @override
  void didUpdateWidget(_Follow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) _play(enter: widget.visible);
  }

  void _play({required bool enter}) {
    _entering = enter;
    _controller
      ..duration = enter ? RivePanel.enter : RivePanel.exit
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !widget.visible,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final double dy;
        final double opacity;
        if (_entering) {
          // easeOutBack pasa de 1: el contenido rebota hacia abajo.
          dy = widget.calm
              ? 0
              : -40 * (1 - Curves.easeOutBack.transform(progress));
          opacity = (progress * RivePanel.enter.inMilliseconds / _fadeIn).clamp(
            0.0,
            1.0,
          );
        } else {
          dy = widget.calm ? 0 : 24 * Curves.easeIn.transform(progress);
          opacity = 1 - progress;
        }
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: widget.child,
    ),
  );
}
