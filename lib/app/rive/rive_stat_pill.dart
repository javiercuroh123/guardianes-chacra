import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';

/// Los nombres del artboard `StatPill` (ver `docs/UI_RIVE.md`).
abstract final class StatPillRive {
  static const artboard = 'StatPill';
  static const viewModel = 'StatPill';

  /// El texto chico de arriba ("Papas restantes").
  static const label = 'label';

  /// El número grande, ya formateado ("20/20").
  static const value = 'value';

  /// El `IconSet` anidado de la insignia.
  static const icon = 'icon';

  /// El número crece y la insignia se mece: terminó de contar.
  static const pop = 'pop';
}

/// Una estadística del resultado: insignia con ícono, etiqueta y número.
/// El conteo lo hace quien la usa (cambia [value] cuadro a cuadro); cada
/// vez que sube [pops], el número hace "pop". Sin el archivo de Rive, una
/// píldora de Flutter con lo mismo.
class RiveStatPill extends ConsumerStatefulWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    this.pops = 0,
    this.scale = 1,
    super.key,
  });

  final RiveIcon icon;
  final String label;
  final String value;

  /// Cada vez que sube, el número hace "pop".
  final int pops;

  /// Cuánto se achica respecto de [size].
  final double scale;

  /// El artboard a escala de letra 1.
  static const Size size = Size(232, 60);

  @override
  ConsumerState<RiveStatPill> createState() => _RiveStatPillState();
}

class _RiveStatPillState extends ConsumerState<RiveStatPill>
    with RiveBindingState<RiveStatPill> {
  @override
  String get artboardName => StatPillRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding.trigger(StatPillRive.pop);
    _apply(binding);
  }

  void _apply(RiveBinding binding) {
    binding.string(StatPillRive.label).value = widget.label;
    binding.string(StatPillRive.value).value = widget.value;
    binding.icon(StatPillRive.icon).value = widget.icon.name;
  }

  @override
  void didUpdateWidget(RiveStatPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    final binding = this.binding;
    if (binding == null) return;
    _apply(binding);
    if (widget.pops > oldWidget.pops) {
      binding.viewModel.trigger(StatPillRive.pop)?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final size =
        RiveStatPill.size *
        widget.scale *
        MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      container: true,
      label: '${widget.label}: ${widget.value}',
      excludeSemantics: true,
      child: SizedBox.fromSize(
        size: size,
        child: binding != null ? binding.widget() : _fallback(context),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = GameColors.of(context);
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.hud,
        shape: const StadiumBorder(),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(widget.icon.fallback, color: colors.onHud),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: text.labelMedium?.copyWith(color: colors.onHud),
                  ),
                  Text(
                    widget.value,
                    style: text.titleLarge?.copyWith(
                      color: colors.onHud,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}
