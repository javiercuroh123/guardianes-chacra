import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/widgets/stars_row.dart';

/// Los nombres del artboard `LevelNode` (ver `docs/UI_RIVE.md`).
abstract final class LevelNodeRive {
  static const artboard = 'LevelNode';
  static const viewModel = 'LevelNode';
  static const enumName = 'LevelNodeState';

  /// El número del nivel en el círculo y su nombre en la cinta.
  static const number = 'number';
  static const name = 'name';

  /// Las mejores estrellas (0 a 3).
  static const stars = 'stars';

  /// Un valor de [LevelNodeState].
  static const state = 'state';

  /// El círculo se sacude y el candado se bambolea (un nivel cerrado).
  static const shake = 'shake';

  /// El candado salta y el círculo hace "pop" (un nivel recién abierto).
  static const unlock = 'unlock';

  static const double aspect = 150 / 160;

  /// El centro del círculo, como fracción del artboard (160 × 150): ahí se
  /// ancla el nodo en el mapa.
  static const circleCenter = Offset(0.5, 0.32);
}

enum LevelNodeState {
  /// Gris, con candado y sin estrellas.
  locked,

  /// Verde, flota sobre su pedestal.
  available,

  /// Además, un anillo dorado que brilla: el nivel sugerido.
  chosen,
}

/// Un nivel en el mapa del valle: el pedestal de piedra con el círculo y
/// el número, la cinta con el nombre y sus estrellas. Se sacude cada vez
/// que sube [shakes] y se abre con un "pop" cada vez que sube [unlocks].
///
/// Solo dibuja: los toques y lo que lee TalkBack los pone quien lo usa.
/// Sin el archivo de Rive, un círculo de Flutter con lo mismo.
class RiveLevelNode extends ConsumerStatefulWidget {
  const new({
    required this.number,
    required this.name,
    required this.stars,
    required this.state,
    this.shakes = 0,
    this.unlocks = 0,
    this.width = 140,
    super.key,
  });

  final int number;
  final String name;
  final int stars;
  final LevelNodeState state;
  final int shakes;
  final int unlocks;

  /// Ancho del nodo (el artboard mide 160 × 150). No crece con la letra:
  /// es parte del mapa.
  final double width;

  @override
  ConsumerState<RiveLevelNode> createState() => _RiveLevelNodeState();
}

class _RiveLevelNodeState extends ConsumerState<RiveLevelNode>
    with RiveBindingState<RiveLevelNode> {
  @override
  String get artboardName => LevelNodeRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding
      ..trigger(LevelNodeRive.shake)
      ..trigger(LevelNodeRive.unlock);
    _apply(binding);
  }

  void _apply(RiveBinding binding) {
    binding.string(LevelNodeRive.number).value = '${widget.number}';
    binding.string(LevelNodeRive.name).value = widget.name;
    binding.number(LevelNodeRive.stars).value = widget.stars.toDouble();
    binding.enumerator(LevelNodeRive.state).value = widget.state.name;
  }

  @override
  void didUpdateWidget(RiveLevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    final binding = this.binding;
    if (binding == null) return;
    _apply(binding);
    if (widget.shakes > oldWidget.shakes) {
      binding.viewModel.trigger(LevelNodeRive.shake)?.trigger();
    }
    if (widget.unlocks > oldWidget.unlocks) {
      binding.viewModel.trigger(LevelNodeRive.unlock)?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.width * LevelNodeRive.aspect,
        child: binding != null ? binding.widget() : _fallback(context),
      ),
    );
  }

  /// El nodo de siempre: el círculo con el número (o el candado), el
  /// nombre y las estrellas debajo.
  Widget _fallback(BuildContext context) {
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final unlocked = widget.state != LevelNodeState.locked;
    // Arriba, para que el círculo caiga donde en Rive.
    return FittedBox(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked ? scheme.primary : colors.locked,
                // Contorno oscuro, como en los dibujos de la interfaz; el
                // sugerido, dorado.
                border: Border.all(
                  color: widget.state == LevelNodeState.chosen
                      ? colors.star
                      : scheme.onSurface,
                  width: 3,
                ),
              ),
              alignment: Alignment.center,
              child: unlocked
                  ? Text(
                      '${widget.number}',
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : const Icon(Icons.lock_rounded, color: Colors.white),
            ),
            const SizedBox(height: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.hud,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Column(
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onHud,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (unlocked) StarsRow(stars: widget.stars, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
