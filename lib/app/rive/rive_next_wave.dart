import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `NextWave` (ver `docs/UI_RIVE.md`).
abstract final class NextWaveRive {
  static const artboard = 'NextWave';
  static const viewModel = 'NextWave';

  /// "12 s", ya formateado.
  static const label = 'label';

  /// "+18" en verde, ya formateado.
  static const bonus = 'bonus';

  /// Cuánto le queda al anillo, de 1 (lleno) a 0.
  static const progress = 'progress';
  static const pressed = 'pressed';

  /// Se llamó la oleada: el anillo y el bono rebotan.
  static const called = 'called';

  /// El `IconSet` anidado (la bandera de siguiente oleada).
  static const icon = 'icon';

  /// Están en el view model, pero el botón se muestra solo cuando se puede
  /// llamar.
  static const enabled = 'enabled';
  static const deny = 'deny';
}

/// "Siguiente oleada" del HUD: un anillo que se vacía con la cuenta
/// regresiva, los segundos y el maíz extra por llamarla ya.
///
/// El anillo avanza un segundo por vez con una animación lineal (de golpe
/// si el teléfono pide menos movimiento). Sin el archivo de Rive es una
/// pastilla de Flutter con los mismos textos.
class RiveNextWaveButton extends ConsumerStatefulWidget {
  const new({
    required this.seconds,
    required this.totalSeconds,
    required this.bonusLabel,
    required this.semanticsLabel,
    required this.onPressed,
    super.key,
  });

  final int seconds;

  /// La cuenta regresiva entera: el anillo lleno.
  final int totalSeconds;

  /// "+18", ya formateado.
  final String bonusLabel;
  final String semanticsLabel;
  final VoidCallback onPressed;

  static const double height = 56;

  static const _style = TextStyle(
    fontFamily: AppTheme.bodyFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  /// Ancho a escala 1: relleno (18 + 18), anillo (26) con su margen y el
  /// espacio entre piezas (6 + 6 + 6), los dos textos y algo de aire.
  static double widthFor(String label, String bonus) {
    double measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: _style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return (4 + 36 + 26 + 18 + measure(label) + measure(bonus) + 8)
        .ceilToDouble();
  }

  @override
  ConsumerState<RiveNextWaveButton> createState() => _RiveNextWaveState();
}

class _RiveNextWaveState extends ConsumerState<RiveNextWaveButton>
    with RiveBindingState<RiveNextWaveButton>, SingleTickerProviderStateMixin {
  rive.ViewModelInstanceBoolean? _pressed;
  rive.ViewModelInstanceString? _label;
  rive.ViewModelInstanceString? _bonus;
  rive.ViewModelInstanceTrigger? _called;
  RiveNumberTween? _progress;

  String get _seconds => '${widget.seconds} s';

  double get _fill => widget.totalSeconds <= 0
      ? 0
      : (widget.seconds / widget.totalSeconds).clamp(0, 1);

  @override
  String get artboardName => NextWaveRive.artboard;

  @override
  void bind(RiveBinding binding) {
    _pressed = binding.boolean(NextWaveRive.pressed);
    binding.boolean(NextWaveRive.enabled).value = true;
    binding.icon(NextWaveRive.icon).value = RiveIcon.nextWave.name;
    _label = binding.string(NextWaveRive.label)..value = _seconds;
    _bonus = binding.string(NextWaveRive.bonus)..value = widget.bonusLabel;
    _called = binding.trigger(NextWaveRive.called);
    _progress = RiveNumberTween(
      vsync: this,
      duration: const Duration(seconds: 1),
      curve: Curves.linear,
    )..attach(binding.number(NextWaveRive.progress), _fill);
  }

  @override
  void didUpdateWidget(RiveNextWaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding == null) return;
    _label?.value = _seconds;
    _bonus?.value = widget.bonusLabel;
    _progress?.animateTo(
      _fill,
      instant: MediaQuery.disableAnimationsOf(context),
    );
  }

  @override
  void dispose() {
    _progress?.dispose();
    super.dispose();
  }

  void _tap() {
    ref.read(uiFeedbackProvider).tap();
    if (!MediaQuery.disableAnimationsOf(context)) _called?.trigger();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final Widget child;
    if (binding == null) {
      child = _fallback(context);
    } else {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _pressed?.value = true,
        onTapUp: (_) => _pressed?.value = false,
        onTapCancel: () => _pressed?.value = false,
        onTap: _tap,
        child: SizedBox(
          width:
              RiveNextWaveButton.widthFor(_seconds, widget.bonusLabel) * scale,
          height: RiveNextWaveButton.height * scale,
          child: binding.widget(fit: rive.Fit.layout, layoutScale: scale),
        ),
      );
    }
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      onTap: _tap,
      excludeSemantics: true,
      child: child,
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = GameColors.of(context);
    return Material(
      color: colors.hud,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _tap,
        child: ConstrainedBox(
          // El mismo alto que tocan los demás botones del HUD.
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.skip_next, color: colors.onHud),
                const SizedBox(width: 4),
                Text(
                  _seconds,
                  style: TextStyle(
                    color: colors.onHud,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.bonusLabel,
                  style: TextStyle(
                    color: colors.hudAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
