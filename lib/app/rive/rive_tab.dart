import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Tab` (ver `docs/UI_RIVE.md`).
abstract final class TabRive {
  static const artboard = 'Tab';
  static const viewModel = 'Tab';
  static const label = 'label';

  /// Elegida: sube un poco y se pone de maíz.
  static const selected = 'selected';

  /// El `IconSet` anidado y si se muestra.
  static const icon = 'icon';
  static const hasIcon = 'hasIcon';
}

/// Una pestaña dibujada en Rive (por ejemplo, las secciones del
/// bestiario). Flutter recibe el toque, toca el sonido y vibra. Sin el
/// archivo de Rive es un `ChoiceChip`.
class RiveTab extends ConsumerStatefulWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final RiveIcon? icon;

  static const double height = 46;

  static const _tapTop = 2.0;

  /// Ancho a escala 1: el texto (Fredoka 15, peso 700) y los márgenes del
  /// artboard.
  static double widthFor(String label, {required bool hasIcon}) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // Relleno (12 + 12), ícono (22 + 6) y aire.
    final width = 24 + (hasIcon ? 28 : 0) + text.width + 8;
    text.dispose();
    return width.ceilToDouble();
  }

  @override
  ConsumerState<RiveTab> createState() => _RiveTabState();
}

class _RiveTabState extends ConsumerState<RiveTab>
    with RiveBindingState<RiveTab> {
  @override
  String get artboardName => TabRive.artboard;

  @override
  void bind(RiveBinding binding) {
    final icon = widget.icon;
    binding.string(TabRive.label).value = widget.label;
    binding.boolean(TabRive.selected).value = widget.selected;
    binding.boolean(TabRive.hasIcon).value = icon != null;
    if (icon != null) binding.icon(TabRive.icon).value = icon.name;
  }

  @override
  void didUpdateWidget(RiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) bind(binding);
  }

  void _tap() {
    ref.read(uiFeedbackProvider).tap();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) {
      return ChoiceChip(
        label: Text(widget.label),
        avatar: widget.icon == null ? null : Icon(widget.icon!.fallback),
        selected: widget.selected,
        onSelected: (_) => _tap(),
      );
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final width = RiveTab.widthFor(widget.label, hasIcon: widget.icon != null);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: _tap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        // 2 dp de toque arriba, sin dibujo: la pestaña mide 46 y se toca en
        // 48 (el mínimo de Android).
        child: Padding(
          padding: const EdgeInsets.only(top: RiveTab._tapTop),
          child: SizedBox(
            width: width * scale,
            height: RiveTab.height * scale,
            child: binding.widget(fit: rive.Fit.layout, layoutScale: scale),
          ),
        ),
      ),
    );
  }
}
