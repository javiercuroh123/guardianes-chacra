import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:rive/rive.dart' as rive;

/// Los nombres del artboard `Segmented` (ver `docs/UI_RIVE.md`).
abstract final class SegmentedRive {
  static const artboard = 'Segmented';
  static const viewModel = 'Segmented';

  /// Los textos de las tres opciones (`label0`, `label1`, `label2`).
  static String label(int index) => 'label$index';

  /// La opción elegida (0, 1 o 2): la pastilla de maíz se desliza hasta
  /// ella.
  static const selected = 'selected';

  static const options = 3;
}

/// Tres opciones, una elegida (por ejemplo Sistema / Español / English).
/// Rive dibuja; Flutter recibe el toque de cada opción con su Semantics y su
/// Key ([optionKeys]). Sin el archivo de Rive es un `SegmentedButton`.
class RiveSegmented extends ConsumerStatefulWidget {
  const new({
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.optionKeys,
    super.key,
  }) : assert(labels.length == SegmentedRive.options, 'son tres opciones');

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Una Key por opción, para los tests.
  final List<Key>? optionKeys;

  static const double height = 44;

  @override
  ConsumerState<RiveSegmented> createState() => _RiveSegmentedState();
}

class _RiveSegmentedState extends ConsumerState<RiveSegmented>
    with RiveBindingState<RiveSegmented> {
  @override
  String get artboardName => SegmentedRive.artboard;

  @override
  void bind(RiveBinding binding) {
    for (var i = 0; i < SegmentedRive.options; i++) {
      binding.string(SegmentedRive.label(i)).value = widget.labels[i];
    }
    binding.number(SegmentedRive.selected).value = widget.selected.toDouble();
  }

  @override
  void didUpdateWidget(RiveSegmented oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) bind(binding);
  }

  void _choose(int index) {
    if (index == widget.selected) return;
    ref.read(uiFeedbackProvider).tap();
    widget.onChanged(index);
  }

  /// El ancho de cada opción: la más larga, con aire a los lados.
  double _optionWidth() {
    var widest = 0.0;
    for (final label in widget.labels) {
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
      if (text.width > widest) widest = text.width;
      text.dispose();
    }
    return (widest + 32).clamp(80, 160).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    if (binding == null) return _fallback();
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final option = _optionWidth() * scale;
    return SizedBox(
      width: option * SegmentedRive.options,
      height: RiveSegmented.height * scale,
      child: Stack(
        children: [
          Positioned.fill(
            child: binding.widget(fit: rive.Fit.layout, layoutScale: scale),
          ),
          Row(
            children: [
              for (var i = 0; i < SegmentedRive.options; i++)
                Expanded(
                  child: Semantics(
                    key: widget.optionKeys?[i],
                    button: true,
                    selected: i == widget.selected,
                    inMutuallyExclusiveGroup: true,
                    label: widget.labels[i],
                    onTap: () => _choose(i),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _choose(i),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback() => SegmentedButton<int>(
    showSelectedIcon: false,
    segments: [
      for (var i = 0; i < SegmentedRive.options; i++)
        ButtonSegment(
          value: i,
          label: Text(widget.labels[i], key: widget.optionKeys?[i]),
        ),
    ],
    selected: {widget.selected},
    onSelectionChanged: (selection) => _choose(selection.single),
  );
}
