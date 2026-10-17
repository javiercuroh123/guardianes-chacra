import 'package:flutter/material.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/radial_menu.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Una opción de los menús que se confirma con dos toques: el primero
/// muestra el alcance (`range`) y el segundo envía `command`. `id` dice
/// cuál está marcada: un tipo de guardián, `upgrade`, `sell` o
/// `branch:<id>`.
///
/// Los menús solo arman las opciones; qué está marcado y cuándo se
/// confirma lo decide `BattleScreen`.
typedef MenuChoice = ({String id, double range, PlayerCommand command});

/// Estrategias de apuntado en el orden en que se recorren con el botón
/// "Apuntar" (son los ids del registro de comportamientos).
const _targetingCycle = ['first', 'last', 'strongest', 'closest'];

/// El menú de un espacio vacío: un botón por guardián disponible, con su
/// costo.
class BuildMenu extends StatelessWidget {
  const new({
    required this.slotId,
    required this.center,
    required this.bounds,
    required this.guardians,
    required this.canAfford,
    required this.nameOf,
    required this.onChoose,
    this.preview,
    super.key,
  });

  final String slotId;

  /// Dónde está el espacio en la pantalla.
  final Offset center;
  final Size bounds;
  final Iterable<GuardianDef> guardians;
  final bool Function(int cost) canAfford;

  /// El nombre de un tipo de guardián en el idioma del jugador.
  final String Function(String guardianType) nameOf;

  /// La opción marcada con el primer toque.
  final String? preview;
  final void Function(MenuChoice choice) onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RadialMenu(
      center: center,
      bounds: bounds,
      hint: preview == null ? null : l10n.menuConfirmHint,
      children: [
        for (final def in guardians)
          RadialButton(
            key: ValueKey('build-${def.id}'),
            label: nameOf(def.id).characters.first.toUpperCase(),
            caption: '${def.levels.first.cost}',
            color: colorFor(def.id, def.color),
            selected: preview == def.id,
            semanticsLabel: l10n.menuBuild(
              nameOf(def.id),
              def.levels.first.cost,
            ),
            onTap: !canAfford(def.levels.first.cost)
                ? null
                : () => onChoose((
                    id: def.id,
                    range: def.levels.first.range,
                    command: BuildGuardian(
                      slotId: slotId,
                      guardianType: def.id,
                    ),
                  )),
          ),
      ],
    );
  }
}

/// El menú de un guardián construido: mejorar (o elegir rama en el último
/// nivel), vender y cambiar a quién apunta.
class GuardianMenu extends StatelessWidget {
  const new({
    required this.guardian,
    required this.center,
    required this.bounds,
    required this.sellValue,
    required this.canAfford,
    required this.nameOf,
    required this.branchNameOf,
    required this.onChoose,
    required this.onCommand,
    this.preview,
    super.key,
  });

  final GuardianView guardian;
  final Offset center;
  final Size bounds;

  /// El maíz que devuelve venderlo.
  final int sellValue;
  final bool Function(int cost) canAfford;
  final String Function(String guardianType) nameOf;
  final String Function(String branchId) branchNameOf;
  final String? preview;

  /// Mejorar, especializar y vender: se confirman con dos toques.
  final void Function(MenuChoice choice) onChoose;

  /// Cambiar el apuntado: se aplica con un solo toque.
  final void Function(PlayerCommand command) onCommand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final def = guardian.def;
    final color = colorFor(def.id, def.color);
    final atLastLevel = guardian.level == def.levels.length;
    final canUpgrade = guardian.branchId == null && !atLastLevel;
    final canSpecialize = guardian.branchId == null && atLastLevel;
    final targeting = _targetingName(guardian.targetingId, l10n);

    return RadialMenu(
      center: center,
      bounds: bounds,
      title: '${nameOf(def.id)} · ${guardian.level}',
      hint: preview == null ? null : l10n.menuConfirmHint,
      children: [
        if (canUpgrade)
          RadialButton(
            key: const ValueKey('menu-upgrade'),
            icon: Icons.arrow_upward,
            caption: '${def.levels[guardian.level].cost}',
            color: color,
            selected: preview == 'upgrade',
            semanticsLabel:
                '${l10n.menuUpgrade}: ${def.levels[guardian.level].cost}',
            onTap: !canAfford(def.levels[guardian.level].cost)
                ? null
                : () => onChoose((
                    id: 'upgrade',
                    range: def.levels[guardian.level].range,
                    command: UpgradeGuardian(guardian.id),
                  )),
          ),
        if (canSpecialize)
          for (final branch in def.branches)
            RadialButton(
              key: ValueKey('menu-branch-${branch.id}'),
              label: branchNameOf(branch.id).characters.first,
              caption: '${branch.level.cost}',
              color: color,
              selected: preview == 'branch:${branch.id}',
              semanticsLabel:
                  '${branchNameOf(branch.id)}: ${branch.level.cost}',
              onTap: !canAfford(branch.level.cost)
                  ? null
                  : () => onChoose((
                      id: 'branch:${branch.id}',
                      range: branch.level.range,
                      command: SpecializeGuardian(
                        guardian.id,
                        branchId: branch.id,
                      ),
                    )),
            ),
        RadialButton(
          key: const ValueKey('menu-sell'),
          icon: Icons.sell_outlined,
          caption: '+$sellValue',
          color: const Color(0xFF8D6E4F),
          selected: preview == 'sell',
          semanticsLabel: '${l10n.menuSell}: $sellValue',
          onTap: () => onChoose((
            id: 'sell',
            range: guardian.range,
            command: SellGuardian(guardian.id),
          )),
        ),
        if (def.levels.first.targets.isNotEmpty)
          RadialButton(
            key: const ValueKey('menu-targeting'),
            icon: Icons.gps_fixed,
            caption: targeting,
            color: const Color(0xFF455A64),
            semanticsLabel: '${l10n.menuTargeting}: $targeting',
            onTap: () {
              final index = _targetingCycle.indexOf(guardian.targetingId);
              final next =
                  _targetingCycle[(index + 1) % _targetingCycle.length];
              onCommand(SetTargeting(guardian.id, strategy: next));
            },
          ),
      ],
    );
  }

  static String _targetingName(String id, AppLocalizations l10n) =>
      switch (id) {
        'first' => l10n.targetingFirst,
        'last' => l10n.targetingLast,
        'strongest' => l10n.targetingStrongest,
        'closest' => l10n.targetingClosest,
        _ => id,
      };
}
