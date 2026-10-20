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

/// Mueve y desvanece su hijo como el marco de Rive (`Enter` y `Exit`).
class _Follow extends StatelessWidget {
  const new({required this.visible, required this.calm, required this.child});

  final bool visible;
  final bool calm;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final offset = visible || calm ? 0.0 : 24.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: calm ? 0 : -40, end: offset),
      duration: visible ? RivePanel.enter : RivePanel.exit,
      curve: visible ? Curves.easeOutBack : Curves.easeIn,
      builder: (context, dy, child) => Transform.translate(
        offset: Offset(0, dy),
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: visible
              ? const Duration(milliseconds: 130)
              : RivePanel.exit,
          child: child,
        ),
      ),
      child: child,
    );
  }
}
