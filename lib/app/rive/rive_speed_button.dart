import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `SpeedButton` (ver `docs/UI_RIVE.md`).
abstract final class SpeedButtonRive {
  static const artboard = 'SpeedButton';
  static const viewModel = 'SpeedButton';

  /// "x1" o "x2".
  static const label = 'label';

  /// A x2: la cara se pinta de maíz y dos flechitas avanzan. Al cambiar,
  /// la cara gira una vuelta.
  static const fast = 'fast';
  static const pressed = 'pressed';

  /// Están en el view model, pero el botón siempre se puede tocar.
  static const enabled = 'enabled';
  static const deny = 'deny';
}

/// El botón redondo de velocidad del HUD: "x1" o "x2", animado en Rive.
/// Sin el archivo de Rive es un `IconButton` que se pinta de maíz a x2.
class RiveSpeedButton extends ConsumerStatefulWidget {
  const new({
    required this.fast,
    required this.onPressed,
    required this.semanticsLabel,
    this.size = 52,
    super.key,
  });

  final bool fast;
  final VoidCallback onPressed;
  final String semanticsLabel;

  /// Lado a escala de letra 1.
  final double size;

  @override
  ConsumerState<RiveSpeedButton> createState() => _RiveSpeedButtonState();
}

class _RiveSpeedButtonState extends ConsumerState<RiveSpeedButton>
    with RiveBindingState<RiveSpeedButton> {
  rive.ViewModelInstanceBoolean? _pressed;
  rive.ViewModelInstanceBoolean? _fast;
  rive.ViewModelInstanceString? _label;

  String get _text => widget.fast ? 'x2' : 'x1';

  @override
  String get artboardName => SpeedButtonRive.artboard;

  @override
  void bind(RiveBinding binding) {
    _pressed = binding.boolean(SpeedButtonRive.pressed);
    binding.boolean(SpeedButtonRive.enabled).value = true;
    _fast = binding.boolean(SpeedButtonRive.fast)..value = widget.fast;
    _label = binding.string(SpeedButtonRive.label)..value = _text;
  }

  @override
  void didUpdateWidget(RiveSpeedButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fast?.value = widget.fast;
    _label?.value = _text;
  }

  void _tap() {
    ref.read(uiFeedbackProvider).tap();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final side = MediaQuery.textScalerOf(context).scale(widget.size);
    final Widget child;
    if (binding == null) {
      final colors = GameColors.of(context);
      final scheme = Theme.of(context).colorScheme;
      final (background, foreground) = widget.fast
          ? (scheme.secondary, scheme.onSecondary)
          : (colors.hud, colors.onHud);
      child = IconButton(
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        onPressed: _tap,
        icon: Text(
          _text,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    } else {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressed?.value = true,
        onTapUp: (_) => _pressed?.value = false,
        onTapCancel: () => _pressed?.value = false,
        onTap: _tap,
        child: SizedBox.square(
          dimension: side,
          child: binding.widget(
            fit: rive.Fit.layout,
            layoutScale: side / widget.size,
          ),
        ),
      );
    }
    return Tooltip(
      message: widget.semanticsLabel,
      child: Semantics(
        button: true,
        label: widget.semanticsLabel,
        onTap: _tap,
        excludeSemantics: true,
        child: child,
      ),
    );
  }
}
