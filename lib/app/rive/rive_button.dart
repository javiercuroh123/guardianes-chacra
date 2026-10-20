import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres de los botones de Rive (ver `docs/UI_RIVE.md`). Los tres
/// artboards comparten el view model `Button`.
abstract final class ButtonRive {
  static const primary = 'PrimaryButton';
  static const secondary = 'SecondaryButton';
  static const round = 'RoundButton';
  static const viewModel = 'Button';

  /// El texto (los redondos no lo muestran).
  static const label = 'label';

  /// El dedo está encima: se hunde.
  static const pressed = 'pressed';
  static const enabled = 'enabled';

  /// El `IconSet` anidado y si se muestra.
  static const icon = 'icon';
  static const hasIcon = 'hasIcon';

  /// "No se puede": una sacudida corta.
  static const deny = 'deny';

  /// Cara terracota con el texto crema (por ejemplo, cerrar o vender).
  static const danger = 'danger';
}

enum RiveButtonKind {
  /// Maíz, con un brillo que lo cruza cada ~4 s: la acción principal.
  primary,

  /// Crema: las demás acciones.
  secondary,

  /// Redondo, solo con ícono (pausa, velocidad, atrás, cerrar).
  round,
}

/// Un botón dibujado en Rive. Flutter recibe el toque (con su Key y su
/// Semantics), toca el sonido y vibra; Rive solo anima: se hunde al
/// presionar, rebota al soltar y se sacude si no se puede.
///
/// Sin [onPressed] queda deshabilitado. Si además hay [onDenied], tocarlo
/// lo sacude, suena "no se puede" y llama a [onDenied] (por ejemplo, para
/// avisar que no alcanza el maíz).
///
/// Sin el archivo de Rive usa los botones del tema.
class RiveButton extends ConsumerStatefulWidget {
  const new({
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = RiveButtonKind.primary,
    this.onDenied,
    this.danger = false,
    super.key,
  }) : size = height;

  /// Redondo: [label] no se ve, pero lo lee TalkBack y es el tooltip.
  const new round({
    required this.label,
    required RiveIcon this.icon,
    required this.onPressed,
    this.danger = false,
    this.onDenied,
    this.size = 52,
    super.key,
  }) : kind = RiveButtonKind.round;

  final String label;
  final RiveIcon? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onDenied;
  final RiveButtonKind kind;

  /// Terracota: una acción que se pierde (vender). En el principal no se
  /// nota (es de maíz).
  final bool danger;

  /// Lado del redondo a escala de letra 1 (los otros miden [height] de
  /// alto y lo que pida su texto de ancho).
  final double size;

  /// Alto de los botones con texto a escala de letra 1.
  static const double height = 56;

  /// El ancho más chico, para que "OK" no quede diminuto.
  static const double minWidth = 140;

  /// Ancho a escala 1 para [label]: el texto medido con la misma letra que
  /// en Rive (Fredoka 20, peso 700) más los márgenes del artboard.
  static double widthFor(String label, {required bool hasIcon}) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // Cara (2 + 2), relleno (18 + 18), ícono (26 + 8) y un poco de aire:
    // Rive mide la letra apenas distinto que Flutter.
    final width = 4 + 36 + (hasIcon ? 34 : 0) + text.width + 8;
    text.dispose();
    return width < minWidth ? minWidth : width.ceilToDouble();
  }

  @override
  ConsumerState<RiveButton> createState() => _RiveButtonState();
}

class _RiveButtonState extends ConsumerState<RiveButton>
    with RiveBindingState<RiveButton> {
  rive.ViewModelInstanceBoolean? _pressed;
  rive.ViewModelInstanceBoolean? _enabled;

  bool get _isEnabled => widget.onPressed != null;

  @override
  String get artboardName => switch (widget.kind) {
    RiveButtonKind.primary => ButtonRive.primary,
    RiveButtonKind.secondary => ButtonRive.secondary,
    RiveButtonKind.round => ButtonRive.round,
  };

  @override
  void bind(RiveBinding binding) {
    _pressed = binding.boolean(ButtonRive.pressed);
    _enabled = binding.boolean(ButtonRive.enabled);
    binding.trigger(ButtonRive.deny);
    _apply(binding);
  }

  void _apply(RiveBinding binding) {
    final icon = widget.icon;
    binding.string(ButtonRive.label).value = widget.label;
    binding.boolean(ButtonRive.hasIcon).value = icon != null;
    if (icon != null) binding.icon(ButtonRive.icon).value = icon.name;
    binding.boolean(ButtonRive.danger).value = widget.danger;
    _enabled?.value = _isEnabled;
    if (!_isEnabled) _pressed?.value = false;
  }

  @override
  void didUpdateWidget(RiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) _apply(binding);
  }

  void _tap() {
    ref.read(uiFeedbackProvider).tap();
    widget.onPressed?.call();
  }

  void _deny() {
    ref.read(uiFeedbackProvider).deny();
    binding?.viewModel.trigger(ButtonRive.deny)?.trigger();
    widget.onDenied?.call();
  }

  VoidCallback? get _onTap =>
      _isEnabled ? _tap : (widget.onDenied != null ? _deny : null);

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final Widget child;
    if (binding == null) {
      child = _fallback(context);
    } else {
      final round = widget.kind == RiveButtonKind.round;
      final width = round
          ? widget.size
          : RiveButton.widthFor(widget.label, hasIcon: widget.icon != null);
      final height = round ? widget.size : RiveButton.height;
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _isEnabled ? (_) => _pressed?.value = true : null,
        onTapUp: (_) => _pressed?.value = false,
        onTapCancel: () => _pressed?.value = false,
        onTap: _onTap,
        child: SizedBox(
          width: width * scale,
          height: height * scale,
          child: binding.widget(fit: rive.Fit.layout, layoutScale: scale),
        ),
      );
    }
    final semantics = Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      onTap: _onTap,
      excludeSemantics: true,
      child: child,
    );
    return widget.kind == RiveButtonKind.round
        ? Tooltip(message: widget.label, child: semantics)
        : semantics;
  }

  /// Los botones del tema, con el mismo sonido y la misma vibración.
  Widget _fallback(BuildContext context) {
    final onTap = _onTap;
    final icon = widget.icon;
    final label = Text(widget.label);
    final button = switch (widget.kind) {
      RiveButtonKind.primary when icon != null => FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon.fallback),
        label: label,
      ),
      RiveButtonKind.primary => FilledButton(onPressed: onTap, child: label),
      RiveButtonKind.secondary when icon != null => OutlinedButton.icon(
        onPressed: onTap,
        style: _dangerStyle(context),
        icon: Icon(icon.fallback),
        label: label,
      ),
      RiveButtonKind.secondary => OutlinedButton(
        onPressed: onTap,
        style: _dangerStyle(context),
        child: label,
      ),
      RiveButtonKind.round => _roundFallback(context, onTap, icon!),
    };
    // Con "no se puede", el botón tiene que recibir el toque: se ve
    // apagado sin estar deshabilitado.
    return !_isEnabled && onTap != null
        ? Opacity(opacity: 0.55, child: button)
        : button;
  }

  ButtonStyle? _dangerStyle(BuildContext context) {
    if (!widget.danger) return null;
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
    );
  }

  Widget _roundFallback(
    BuildContext context,
    VoidCallback? onTap,
    RiveIcon icon,
  ) {
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: widget.danger ? scheme.error : colors.hud,
        foregroundColor: widget.danger ? scheme.onError : colors.onHud,
      ),
      onPressed: onTap,
      icon: Icon(icon.fallback),
    );
  }
}
