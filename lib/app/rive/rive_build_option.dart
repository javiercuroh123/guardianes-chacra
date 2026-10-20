import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';

/// Los nombres del artboard `BuildOption` (ver `docs/UI_RIVE.md`).
abstract final class BuildOptionRive {
  static const artboard = 'BuildOption';
  static const viewModel = 'BuildOption';

  static const name = 'name';

  /// El costo en maíz, ya formateado.
  static const cost = 'cost';

  /// El `Portrait` anidado.
  static const portrait = 'portrait';

  /// Marcada con el primer toque: brilla de maíz y se levanta.
  static const selected = 'selected';

  /// Sin maíz suficiente: gris y el costo en rojo.
  static const affordable = 'affordable';

  /// Todavía no se puede construir: velo oscuro y candado.
  static const locked = 'locked';

  /// Se confirmó: un "pop" y desaparece.
  static const confirm = 'confirm';

  /// "No se puede": una sacudida.
  static const deny = 'deny';
}

/// Un guardián en el menú de construcción: retrato, nombre y costo.
///
/// Si se puede construir, tocarlo llama a [onTap] (marcar y, con el
/// segundo toque, confirmar: lo decide quien lo usa). Si no alcanza el
/// maíz o está bloqueado, tocarlo lo sacude, suena "no se puede" y llama a
/// [onDenied]. Con [confirmed] hace el "pop" final.
///
/// Sin el archivo de Rive es una tarjeta de Flutter con lo mismo.
class RiveBuildOption extends ConsumerStatefulWidget {
  const new({
    required this.guardianId,
    required this.name,
    required this.cost,
    required this.color,
    required this.semanticsLabel,
    required this.onTap,
    required this.onDenied,
    this.selected = false,
    this.affordable = true,
    this.locked = false,
    this.confirmed = false,
    this.scale = 1,
    super.key,
  });

  final String guardianId;
  final String name;
  final int cost;

  /// El color del guardián, para el respaldo.
  final Color color;
  final String semanticsLabel;
  final VoidCallback onTap;
  final VoidCallback onDenied;
  final bool selected;
  final bool affordable;
  final bool locked;
  final bool confirmed;

  /// Cuánto se achica respecto de [size] (en el abanico va más chico).
  final double scale;

  /// El artboard a escala de letra 1.
  static const Size size = Size(84, 108);

  @override
  ConsumerState<RiveBuildOption> createState() => _RiveBuildOptionState();
}

class _RiveBuildOptionState extends ConsumerState<RiveBuildOption>
    with RiveBindingState<RiveBuildOption> {
  bool get _available => widget.affordable && !widget.locked;

  @override
  String get artboardName => BuildOptionRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding
      ..trigger(BuildOptionRive.confirm)
      ..trigger(BuildOptionRive.deny);
    _apply(binding);
  }

  void _apply(RiveBinding binding) {
    binding.string(BuildOptionRive.name).value = widget.name;
    binding.string(BuildOptionRive.cost).value = '${widget.cost}';
    binding
        .enumerator('${BuildOptionRive.portrait}/${PortraitRive.guardian}')
        .value = PortraitRive.valueFor(
      widget.guardianId,
    );
    binding.boolean(BuildOptionRive.selected).value = widget.selected;
    binding.boolean(BuildOptionRive.affordable).value = widget.affordable;
    binding.boolean(BuildOptionRive.locked).value = widget.locked;
  }

  @override
  void didUpdateWidget(RiveBuildOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    final binding = this.binding;
    if (binding == null) return;
    _apply(binding);
    if (widget.confirmed && !oldWidget.confirmed) {
      binding.viewModel.trigger(BuildOptionRive.confirm)?.trigger();
    }
  }

  void _tap() {
    if (widget.confirmed) return;
    if (_available) {
      ref.read(uiFeedbackProvider).tap();
      widget.onTap();
      return;
    }
    ref.read(uiFeedbackProvider).deny();
    binding?.viewModel.trigger(BuildOptionRive.deny)?.trigger();
    widget.onDenied();
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final size =
        RiveBuildOption.size *
        widget.scale *
        MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: _available,
      label: widget.semanticsLabel,
      onTap: _tap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SizedBox.fromSize(
          size: size,
          child: binding != null ? binding.widget() : _fallback(context),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: widget.selected ? 1.08 : 1,
      duration: const Duration(milliseconds: 140),
      child: Card(
        color: _available ? scheme.surface : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: widget.selected ? scheme.secondary : scheme.outline,
            width: widget.selected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: widget.color,
                child: widget.locked
                    ? const Icon(Icons.lock, color: Colors.white, size: 18)
                    : Text(
                        widget.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              if (!widget.locked)
                Text(
                  '${widget.cost}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.affordable ? null : scheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
