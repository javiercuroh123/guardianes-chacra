import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Tooltip` (ver `docs/UI_RIVE.md`).
abstract final class TooltipRive {
  static const artboard = 'Tooltip';
  static const viewModel = 'Tooltip';
  static const text = 'text';

  /// Aparece subiendo un poco y se desvanece al ocultarse.
  static const visible = 'visible';
}

/// Un globo con flecha abajo (por ejemplo, "Toca otra vez para
/// confirmar"). Lo pone y lo saca quien lo usa con [visible]; TalkBack lo
/// anuncia al aparecer.
class RiveTooltip extends ConsumerStatefulWidget {
  const new({
    required this.text,
    required this.visible,
    this.maxWidth = 240,
    super.key,
  });

  final String text;
  final bool visible;

  /// Ancho máximo a escala de letra 1; el texto largo se parte en líneas.
  final double maxWidth;

  static const _style = TextStyle(
    fontFamily: AppTheme.bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// El tamaño a escala 1 para [text]: el globo (relleno 12 y 6) y la
  /// flecha (10).
  static Size sizeFor(String text, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth - 28);
    final size = Size(
      (painter.width + 28).clamp(80, maxWidth).ceilToDouble(),
      (painter.height + 12 + 10 + 6).ceilToDouble(),
    );
    painter.dispose();
    return size;
  }

  @override
  ConsumerState<RiveTooltip> createState() => _RiveTooltipState();
}

class _RiveTooltipState extends ConsumerState<RiveTooltip>
    with RiveBindingState<RiveTooltip> {
  @override
  String get artboardName => TooltipRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding.string(TooltipRive.text).value = widget.text;
    binding.boolean(TooltipRive.visible).value = widget.visible;
  }

  @override
  void didUpdateWidget(RiveTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) bind(binding);
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final size = RiveTooltip.sizeFor(widget.text, widget.maxWidth) * scale;
    final Widget child;
    if (binding == null) {
      final colors = GameColors.of(context);
      child = AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth * scale),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.onHud, width: 2),
          ),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: RiveTooltip._style.copyWith(color: colors.onHud),
          ),
        ),
      );
    } else {
      child = SizedBox.fromSize(
        size: size,
        child: binding.widget(fit: rive.Fit.layout, layoutScale: scale),
      );
    }
    return Semantics(
      liveRegion: widget.visible,
      label: widget.visible ? widget.text : null,
      excludeSemantics: true,
      child: IgnorePointer(child: child),
    );
  }
}
