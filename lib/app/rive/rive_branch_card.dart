import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';

/// Los nombres del artboard `BranchCard` (ver `docs/UI_RIVE.md`).
abstract final class BranchCardRive {
  static const artboard = 'BranchCard';
  static const viewModel = 'BranchCard';

  static const name = 'name';
  static const description = 'description';

  /// El costo en maíz, ya formateado.
  static const cost = 'cost';

  /// El color del encabezado (el del guardián).
  static const color = 'color';

  /// El `Portrait` anidado.
  static const portrait = 'portrait';

  /// Marcada con el primer toque: se levanta y brilla.
  static const selected = 'selected';

  /// Sin maíz suficiente: gris y el costo en rojo.
  static const affordable = 'affordable';

  /// La tarjeta entra girando sola al aparecer; este trigger la repite.
  static const enter = 'enter';

  /// Se eligió: rebota y estalla en chispas.
  static const choose = 'choose';
}

/// Una de las dos ramas de la especialización: encabezado del color del
/// guardián, retrato, descripción y costo. Entra girando al aparecer.
///
/// Tocarla llama a [onTap] si alcanza el maíz; si no, se sacude con "no se
/// puede" y llama a [onDenied]. Con [chosen] estalla.
///
/// Sin el archivo de Rive es una tarjeta de Flutter con lo mismo.
class RiveBranchCard extends ConsumerStatefulWidget {
  const new({
    required this.guardianId,
    required this.name,
    required this.description,
    required this.cost,
    required this.color,
    required this.onTap,
    required this.onDenied,
    this.selected = false,
    this.affordable = true,
    this.chosen = false,
    super.key,
  });

  final String guardianId;
  final String name;
  final String description;
  final int cost;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDenied;
  final bool selected;
  final bool affordable;
  final bool chosen;

  /// El artboard a escala de letra 1.
  static const Size size = Size(156, 210);

  @override
  ConsumerState<RiveBranchCard> createState() => _RiveBranchCardState();
}

class _RiveBranchCardState extends ConsumerState<RiveBranchCard>
    with RiveBindingState<RiveBranchCard> {
  @override
  String get artboardName => BranchCardRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding
      ..trigger(BranchCardRive.enter)
      ..trigger(BranchCardRive.choose);
    _apply(binding);
  }

  void _apply(RiveBinding binding) {
    binding.string(BranchCardRive.name).value = widget.name;
    binding.string(BranchCardRive.description).value = widget.description;
    binding.string(BranchCardRive.cost).value = '${widget.cost}';
    binding.color(BranchCardRive.color).value = widget.color;
    binding
        .enumerator('${BranchCardRive.portrait}/${PortraitRive.guardian}')
        .value = PortraitRive.valueFor(
      widget.guardianId,
    );
    binding.boolean(BranchCardRive.selected).value = widget.selected;
    binding.boolean(BranchCardRive.affordable).value = widget.affordable;
  }

  @override
  void didUpdateWidget(RiveBranchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final binding = this.binding;
    if (binding == null) return;
    _apply(binding);
    if (widget.chosen && !oldWidget.chosen) {
      binding.viewModel.trigger(BranchCardRive.choose)?.trigger();
    }
  }

  void _tap() {
    if (widget.chosen) return;
    if (widget.affordable) {
      ref.read(uiFeedbackProvider).tap();
      widget.onTap();
      return;
    }
    ref.read(uiFeedbackProvider).deny();
    widget.onDenied();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.affordable,
      label: '${widget.name}. ${widget.description}. ${widget.cost}',
      onTap: _tap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SizedBox.fromSize(
          size: RiveBranchCard.size * scale,
          child: binding != null ? binding.widget() : _fallback(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: widget.selected ? 1.05 : 1,
      duration: const Duration(milliseconds: 140),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.selected ? scheme.secondary : scheme.outline,
            width: widget.selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            ColoredBox(
              color: widget.color,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            Text(
              '${widget.cost}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.affordable ? null : scheme.error,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
