import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';

/// Los nombres del artboard `PestPortrait` (ver `docs/UI_RIVE.md`).
abstract final class PestPortraitRive {
  static const artboard = 'PestPortrait';
  static const viewModel = 'PestPortrait';
  static const enumName = 'PestId';

  /// Qué plaga se ve (un valor de [ids]).
  static const pest = 'pest';

  /// El retrato de respaldo: la silueta con "?".
  static const unknown = 'unknown';

  /// Los valores del enum `PestId`, en el orden del editor: el primero es
  /// el respaldo (un valor que el enum no tiene deja el primero).
  static const List<String> ids = [
    unknown,
    'gorgojo',
    'polilla',
    'langosta',
    'granizo',
    'granizo_chico',
    'escarabajo',
    'espiritu_helada',
    'rey_gorgojo',
  ];

  /// El valor para la plaga [pestId]; si todavía no tiene retrato (una
  /// plaga nueva en los datos), el de respaldo.
  static String valueFor(String pestId) =>
      ids.contains(pestId) ? pestId : unknown;
}

/// Los nombres del artboard `PestCard` (ver `docs/UI_RIVE.md`).
abstract final class PestCardRive {
  static const artboard = 'PestCard';
  static const viewModel = 'PestCard';
  static const name = 'name';

  /// La insignia "Nueva" (una plaga que el jugador todavía no vio).
  static const isNew = 'isNew';
  static const newLabel = 'newLabel';

  /// El jefe: marco ciruela, la cinta "Jefe final" y el brillo que late.
  static const boss = 'boss';
  static const bossLabel = 'bossLabel';

  /// El fondo de la ventana del retrato.
  static const color = 'color';

  /// El `PestPortrait` anidado.
  static const portrait = 'portrait';

  /// Sube y aparece. Hasta entonces la tarjeta no se ve.
  static const enter = 'enter';

  static const double aspect = 180 / 132;
}

/// La tarjeta de una plaga en la preparación: su retrato sobre el color de
/// la plaga, el nombre (en dos líneas si hace falta), "Nueva" si todavía no
/// se vio y, el jefe, su marco y su cinta. Entra subiendo cuando [shown]
/// pasa a `true`.
///
/// Solo dibuja: los toques y lo que lee TalkBack los pone quien la usa.
/// Sin el archivo de Rive, una tarjeta de Flutter con lo mismo.
class RivePestCard extends ConsumerStatefulWidget {
  const new({
    required this.pestId,
    required this.name,
    required this.color,
    required this.newLabel,
    required this.bossLabel,
    this.isNew = false,
    this.boss = false,
    this.shown = true,
    this.width = 96,
    super.key,
  });

  final String pestId;
  final String name;

  /// El color de la plaga (el de sus datos); la ventana lleva un tono
  /// claro de él.
  final Color color;
  final String newLabel;
  final String bossLabel;
  final bool isNew;
  final bool boss;
  final bool shown;

  /// Ancho de la tarjeta (el artboard mide 132 × 180).
  final double width;

  /// El fondo claro de la ventana para el color [color] de una plaga.
  static Color windowColor(Color color) =>
      Color.lerp(color, Colors.white, 0.6)!;

  @override
  ConsumerState<RivePestCard> createState() => _RivePestCardState();
}

class _RivePestCardState extends ConsumerState<RivePestCard>
    with RiveBindingState<RivePestCard> {
  @override
  String get artboardName => PestCardRive.artboard;

  @override
  void bind(RiveBinding binding) {
    final enter = binding.trigger(PestCardRive.enter);
    _apply(binding);
    if (widget.shown) enter.trigger();
  }

  void _apply(RiveBinding binding) {
    binding.string(PestCardRive.name).value = widget.name;
    binding.string(PestCardRive.newLabel).value = widget.newLabel;
    binding.string(PestCardRive.bossLabel).value = widget.bossLabel;
    binding.boolean(PestCardRive.isNew).value = widget.isNew;
    binding.boolean(PestCardRive.boss).value = widget.boss;
    binding.color(PestCardRive.color).value = RivePestCard.windowColor(
      widget.color,
    );
    binding
        .enumerator('${PestCardRive.portrait}/${PestPortraitRive.pest}')
        .value = PestPortraitRive.valueFor(
      widget.pestId,
    );
  }

  @override
  void didUpdateWidget(RivePestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final binding = this.binding;
    if (binding == null) return;
    _apply(binding);
    if (widget.shown && !oldWidget.shown) {
      binding.viewModel.trigger(PestCardRive.enter)?.trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.width * PestCardRive.aspect,
        child: binding != null ? binding.widget() : _fallback(context),
      ),
    );
  }

  /// La tarjeta de siempre: el color de la plaga, el nombre y las
  /// insignias.
  Widget _fallback(BuildContext context) {
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      opacity: widget.shown ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.hud,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.boss ? scheme.tertiary : colors.onHud,
            width: widget.boss ? 3 : 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: RivePestCard.windowColor(widget.color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: widget.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.name,
                  style: TextStyle(
                    color: colors.onHud,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final badge in [
                if (widget.isNew) widget.newLabel,
                if (widget.boss) widget.bossLabel,
              ])
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: scheme.tertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
