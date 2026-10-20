import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/rive/rive_binding.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';

/// Los nombres del artboard `GuardianInfo` (ver `docs/UI_RIVE.md`).
abstract final class GuardianInfoRive {
  static const artboard = 'GuardianInfo';
  static const viewModel = 'GuardianInfo';

  /// "Hondero · Nivel 2".
  static const title = 'title';

  /// "Ataca: tierra y aire".
  static const attacks = 'attacks';

  /// El `IconSet` junto a [attacks].
  static const attackIcon = 'attackIcon';

  /// El `Portrait` anidado.
  static const portrait = 'portrait';

  /// Las dos filas de estadísticas: `stat1Label`, `stat1Current`,
  /// `stat1Next`, `stat1Icon` y lo mismo con `stat2`.
  static String statLabel(int row) => 'stat${row}Label';
  static String statCurrent(int row) => 'stat${row}Current';
  static String statNext(int row) => 'stat${row}Next';
  static String statIcon(int row) => 'stat${row}Icon';

  /// Hay mejora: se ven las flechas y el valor siguiente, que late. En el
  /// último nivel solo quedan los valores actuales.
  static const hasNext = 'hasNext';

  static const rows = 2;
}

/// Una fila de la ficha: "Daño 8 → 12".
@immutable
class GuardianStat {
  const new({
    required this.icon,
    required this.label,
    required this.current,
    this.next,
  });

  final RiveIcon icon;
  final String label;
  final String current;

  /// El valor después de mejorar, o `null` si no hay mejora.
  final String? next;
}

/// La parte de arriba de la ficha de un guardián construido: retrato,
/// nombre y nivel, a qué ataca y dos estadísticas con su valor siguiente.
/// No recibe toques (los botones van aparte).
///
/// Sin el archivo de Rive se arma con widgets de Flutter.
class RiveGuardianInfo extends ConsumerStatefulWidget {
  const new({
    required this.guardianId,
    required this.title,
    required this.attacks,
    required this.attackIcon,
    required this.stats,
    required this.color,
    required this.nextWord,
    super.key,
  });

  final String guardianId;
  final String title;
  final String attacks;
  final RiveIcon attackIcon;

  /// Las [GuardianInfoRive.rows] filas, en orden.
  final List<GuardianStat> stats;

  /// El color del guardián, para el retrato de respaldo.
  final Color color;

  /// "luego", para que TalkBack lea "Daño: 8, luego 12".
  final String nextWord;

  /// El artboard a escala de letra 1.
  static const Size size = Size(224, 118);

  @override
  ConsumerState<RiveGuardianInfo> createState() => _RiveGuardianInfoState();
}

class _RiveGuardianInfoState extends ConsumerState<RiveGuardianInfo>
    with RiveBindingState<RiveGuardianInfo> {
  bool get _hasNext => widget.stats.any((stat) => stat.next != null);

  @override
  String get artboardName => GuardianInfoRive.artboard;

  @override
  void bind(RiveBinding binding) {
    binding.string(GuardianInfoRive.title).value = widget.title;
    binding.string(GuardianInfoRive.attacks).value = widget.attacks;
    binding.icon(GuardianInfoRive.attackIcon).value = widget.attackIcon.name;
    binding
        .enumerator('${GuardianInfoRive.portrait}/${PortraitRive.guardian}')
        .value = PortraitRive.valueFor(
      widget.guardianId,
    );
    for (final (index, stat) in widget.stats.indexed) {
      final row = index + 1;
      binding.string(GuardianInfoRive.statLabel(row)).value = stat.label;
      binding.string(GuardianInfoRive.statCurrent(row)).value = stat.current;
      binding.string(GuardianInfoRive.statNext(row)).value = stat.next ?? '';
      binding.icon(GuardianInfoRive.statIcon(row)).value = stat.icon.name;
    }
    binding.boolean(GuardianInfoRive.hasNext).value = _hasNext;
  }

  @override
  void didUpdateWidget(RiveGuardianInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (binding case final binding?) bind(binding);
  }

  /// TalkBack no lee bien la flecha.
  String get _semantics => [
    widget.title,
    widget.attacks,
    for (final stat in widget.stats)
      if (stat.next case final next?)
        '${stat.label}: ${stat.current}, ${widget.nextWord} $next'
      else
        '${stat.label}: ${stat.current}',
  ].join('. ');

  @override
  Widget build(BuildContext context) {
    final binding = this.binding;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      label: _semantics,
      excludeSemantics: true,
      child: binding != null
          ? SizedBox.fromSize(
              size: RiveGuardianInfo.size * scale,
              child: binding.widget(),
            )
          : _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: RiveGuardianInfo.size.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RivePortrait(
                guardianId: widget.guardianId,
                name: widget.title,
                color: widget.color,
                size: 48,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: theme.textTheme.titleMedium),
                    Text(widget.attacks, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          for (final stat in widget.stats)
            Row(
              children: [
                Icon(stat.icon.fallback, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(stat.label)),
                Text(
                  stat.next == null
                      ? stat.current
                      : '${stat.current} → ${stat.next}',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
