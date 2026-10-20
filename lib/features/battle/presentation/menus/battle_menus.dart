import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guardianes_chacra/app/rive/rive_branch_card.dart';
import 'package:guardianes_chacra/app/rive/rive_build_option.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_guardian_info.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_tooltip.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/guardian_stats.dart';
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
/// "Objetivo" (son los ids del registro de comportamientos).
const _targetingCycle = ['first', 'last', 'strongest', 'closest'];

/// Un guardián en el menú de construcción: los bloqueados también se
/// muestran, con candado y lo que falta para abrirlos ([lockRule]).
@immutable
class BuildEntry {
  const new({required this.def, required this.name, this.lockRule});

  final GuardianDef def;
  final String name;

  /// "Se abre al ganar Andenes", o `null` si ya se puede construir.
  final String? lockRule;

  bool get locked => lockRule != null;
}

/// La etiqueta de abajo de los menús ("Hondero · tierra y aire / Toca
/// otra vez para confirmar", "No alcanza el maíz"…). No recibe toques.
class MenuLabel extends StatelessWidget {
  const new({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 8,
    child: Center(
      child: RiveTooltip(
        key: const ValueKey('menu-label'),
        text: text,
        visible: true,
        arrow: false,
        maxWidth: 360,
      ),
    ),
  );
}

/// El menú de un espacio vacío: los guardianes salen en abanico desde el
/// espacio, uno tras otro. El primer toque marca uno (brilla y se
/// levanta) y el segundo lo construye con un "pop"; los que no alcanza el
/// maíz o están bloqueados se sacuden y la etiqueta de abajo dice por qué.
class BuildMenu extends StatefulWidget {
  const new({
    required this.slotId,
    required this.center,
    required this.bounds,
    required this.entries,
    required this.canAfford,
    required this.onChoose,
    this.preview,
    this.confirmed,
    super.key,
  });

  final String slotId;

  /// Dónde está el espacio en la pantalla.
  final Offset center;
  final Size bounds;
  final List<BuildEntry> entries;
  final bool Function(int cost) canAfford;

  /// La opción marcada con el primer toque.
  final String? preview;

  /// La opción ya confirmada (hace el "pop" antes de cerrar).
  final String? confirmed;
  final void Function(MenuChoice choice) onChoose;

  /// Cuánto se achican las tarjetas en el abanico.
  static const double cardScale = 0.8;

  @override
  State<BuildMenu> createState() => _BuildMenuState();
}

class _BuildMenuState extends State<BuildMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _appear = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 320 + 70 * widget.entries.length),
  );

  /// Por qué no se pudo la última opción tocada.
  String? _notice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appear.isAnimating || _appear.value == 1) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _appear.value = 1;
    } else {
      _appear.forward();
    }
  }

  @override
  void didUpdateWidget(BuildMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preview != oldWidget.preview) _notice = null;
  }

  @override
  void dispose() {
    _appear.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n) {
    if (_notice case final notice?) return notice;
    final preview = widget.entries
        .where((entry) => entry.def.id == widget.preview)
        .firstOrNull;
    if (preview == null) return l10n.menuTapToChoose;
    final attacks = GuardianStats.targets(preview.def.levels.first, l10n);
    return '${l10n.menuOptionInfo(preview.name, attacks)}\n'
        '${l10n.menuConfirmHint}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: TextScaleLimits.battle,
      child: Builder(
        builder: (context) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final card = RiveBuildOption.size * BuildMenu.cardScale * scale;
          final count = widget.entries.length;
          // Las tarjetas no se pisan: el radio crece con la cantidad.
          final radius = math.max(
            card.height * 0.85,
            count * (card.width + 6) / (2 * math.pi),
          );
          final marginX = radius + card.width / 2 + 4;
          final marginY = radius + card.height / 2 + 4;
          double clampTo(double value, double size, double margin) =>
              size <= margin * 2
              ? size / 2
              : value.clamp(margin, size - margin);
          final x = clampTo(widget.center.dx, widget.bounds.width, marginX);
          final y = clampTo(widget.center.dy, widget.bounds.height, marginY);

          // Empieza arriba y sigue en el sentido de las agujas del reloj.
          double angleOf(int index) =>
              -math.pi / 2 + 2 * math.pi * index / math.max(count, 1);

          return Stack(
            children: [
              for (final (index, entry) in widget.entries.indexed)
                _fanned(
                  index: index,
                  count: count,
                  card: card,
                  from: Offset(x, y),
                  to: Offset(
                    x + radius * math.cos(angleOf(index)),
                    y + radius * math.sin(angleOf(index)),
                  ),
                  child: _option(entry, l10n),
                ),
              MenuLabel(text: _label(l10n)),
            ],
          );
        },
      ),
    );
  }

  /// Una tarjeta que sale del centro hasta [to], con un poco de retraso
  /// según su lugar en el abanico.
  Widget _fanned({
    required int index,
    required int count,
    required Size card,
    required Offset from,
    required Offset to,
    required Widget child,
  }) {
    final start = count <= 1 ? 0.0 : 0.45 * index / (count - 1);
    final curve = CurvedAnimation(
      parent: _appear,
      curve: Interval(
        start,
        math.min(1, start + 0.55),
        curve: Curves.easeOutBack,
      ),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        final at = Offset.lerp(from, to, t)!;
        return Positioned(
          left: at.dx - card.width / 2,
          top: at.dy - card.height / 2,
          child: Opacity(
            opacity: t.clamp(0, 1),
            child: Transform.scale(scale: 0.4 + 0.6 * t, child: child),
          ),
        );
      },
      child: child,
    );
  }

  Widget _option(BuildEntry entry, AppLocalizations l10n) {
    final def = entry.def;
    final cost = def.levels.first.cost;
    final rule = entry.lockRule;
    return RiveBuildOption(
      key: ValueKey('build-${def.id}'),
      guardianId: def.id,
      name: entry.name,
      cost: cost,
      color: colorFor(def.id, def.color),
      scale: BuildMenu.cardScale,
      locked: entry.locked,
      affordable: widget.canAfford(cost),
      selected: widget.preview == def.id,
      confirmed: widget.confirmed == def.id,
      semanticsLabel: rule == null
          ? l10n.menuBuild(entry.name, cost)
          : l10n.menuLockedSemantics(entry.name, rule),
      onTap: () {
        setState(() => _notice = null);
        widget.onChoose((
          id: def.id,
          range: def.levels.first.range,
          command: BuildGuardian(slotId: widget.slotId, guardianType: def.id),
        ));
      },
      onDenied: () =>
          setState(() => _notice = rule ?? l10n.rejectNotEnoughCorn),
    );
  }
}

/// La ficha de un guardián construido, a un costado (el opuesto al
/// guardián, para no taparlo): retrato, nivel, a qué ataca, estadísticas
/// "actual → siguiente" y los botones Mejorar (o Especializar), Objetivo,
/// Vender y cerrar.
///
/// Mejorar y Vender se confirman con dos toques (el primero muestra el
/// alcance y la etiqueta de abajo lo pide); Objetivo cambia con un toque.
class GuardianCard extends StatefulWidget {
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
    required this.onSpecialize,
    required this.onClose,
    required this.locale,
    this.preview,
    super.key,
  });

  final GuardianView guardian;

  /// Dónde está el guardián en la pantalla (la ficha va del otro lado).
  final Offset center;
  final Size bounds;

  /// El maíz que devuelve venderlo.
  final int sellValue;
  final bool Function(int cost) canAfford;
  final String Function(String guardianType) nameOf;
  final String Function(String branchId) branchNameOf;
  final String? preview;
  final String locale;

  /// Mejorar y vender: se confirman con dos toques.
  final void Function(MenuChoice choice) onChoose;

  /// Cambiar el apuntado: se aplica con un solo toque.
  final void Function(PlayerCommand command) onCommand;

  /// Abre la ventana de especialización (en el último nivel).
  final VoidCallback onSpecialize;
  final VoidCallback onClose;

  @override
  State<GuardianCard> createState() => _GuardianCardState();
}

class _GuardianCardState extends State<GuardianCard> {
  String? _notice;

  @override
  void didUpdateWidget(GuardianCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preview != oldWidget.preview ||
        widget.guardian.level != oldWidget.guardian.level) {
      _notice = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guardian = widget.guardian;
    final def = guardian.def;
    final branch = def.branches
        .where((branch) => branch.id == guardian.branchId)
        .firstOrNull;
    final current = branch?.level ?? def.levels[guardian.level - 1];
    final atLastLevel = guardian.level == def.levels.length;
    final canUpgrade = branch == null && !atLastLevel;
    final canSpecialize =
        branch == null && atLastLevel && def.branches.isNotEmpty;
    final next = canUpgrade ? def.levels[guardian.level] : null;
    final name = widget.nameOf(def.id);
    final label =
        _notice ?? (widget.preview == null ? null : l10n.menuConfirmHint);
    // La ficha va del lado contrario al guardián.
    final onLeft = widget.center.dx > widget.bounds.width / 2;

    final upgrade = next == null
        ? null
        : RiveButton(
            key: const ValueKey('menu-upgrade'),
            label: l10n.menuUpgradeCost(next.cost),
            icon: RiveIcon.upgrade,
            onPressed: widget.canAfford(next.cost)
                ? () => widget.onChoose((
                    id: 'upgrade',
                    range: next.range,
                    command: UpgradeGuardian(guardian.id),
                  ))
                : null,
            onDenied: () => setState(() => _notice = l10n.rejectNotEnoughCorn),
          );
    final specialize = canSpecialize
        ? RiveButton(
            key: const ValueKey('menu-specialize'),
            label: l10n.menuSpecialize,
            icon: RiveIcon.star,
            onPressed: widget.onSpecialize,
          )
        : null;
    final targeting = def.levels.first.targets.isEmpty
        ? null
        : RiveButton(
            key: const ValueKey('menu-targeting'),
            label: l10n.menuTargetingName(
              _targetingName(guardian.targetingId, l10n),
            ),
            icon: RiveIcon.target,
            kind: RiveButtonKind.secondary,
            onPressed: () {
              final index = _targetingCycle.indexOf(guardian.targetingId);
              final next =
                  _targetingCycle[(index + 1) % _targetingCycle.length];
              widget.onCommand(SetTargeting(guardian.id, strategy: next));
            },
          );
    final sell = RiveButton(
      key: const ValueKey('menu-sell'),
      label: l10n.menuSellValue(widget.sellValue),
      icon: RiveIcon.sell,
      kind: RiveButtonKind.secondary,
      danger: true,
      onPressed: () => widget.onChoose((
        id: 'sell',
        range: guardian.range,
        command: SellGuardian(guardian.id),
      )),
    );

    final card = RivePanel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RiveGuardianInfo(
            guardianId: def.id,
            title: branch == null
                ? l10n.guardianLevel(name, guardian.level)
                : '$name · ${widget.branchNameOf(branch.id)}',
            attacks: GuardianStats.attacks(current, l10n),
            attackIcon: GuardianStats.attackIcon(current),
            stats: GuardianStats.rows(
              current,
              next,
              l10n: l10n,
              locale: widget.locale,
            ),
            color: colorFor(def.id, def.color),
            nextWord: l10n.cardNextWord,
          ),
          const SizedBox(height: 10),
          ?upgrade,
          ?specialize,
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (targeting != null) ...[targeting, const SizedBox(width: 8)],
              sell,
            ],
          ),
        ],
      ),
    );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: TextScaleLimits.battle,
      child: Stack(
        children: [
          Positioned(
            left: onLeft ? 8 : null,
            right: onLeft ? null : 8,
            top: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                card,
                Positioned(
                  top: -6,
                  right: -6,
                  child: RiveButton.round(
                    key: const ValueKey('menu-close'),
                    label: l10n.menuClose,
                    icon: RiveIcon.close,
                    size: 44,
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
          if (label != null) MenuLabel(text: label),
        ],
      ),
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

/// La ventana de especialización: el cartel, las dos ramas como tarjetas
/// que entran girando y los botones cerrar y Elegir. La partida queda
/// pausada mientras está abierta (lo hace `BattleScreen`).
///
/// El primer toque en una tarjeta la marca y muestra su alcance en el
/// mapa; Elegir (o un segundo toque) la confirma: la tarjeta estalla y la
/// ventana se cierra.
class SpecializationWindow extends StatefulWidget {
  const new({
    required this.guardian,
    required this.canAfford,
    required this.branchNameOf,
    required this.branchDescriptionOf,
    required this.onChoose,
    required this.onClose,
    this.preview,
    this.chosen,
    super.key,
  });

  final GuardianView guardian;
  final bool Function(int cost) canAfford;
  final String Function(String branchId) branchNameOf;
  final String Function(String branchId) branchDescriptionOf;

  /// La rama marcada (`branch:<id>`) y la ya elegida.
  final String? preview;
  final String? chosen;
  final void Function(MenuChoice choice) onChoose;
  final VoidCallback onClose;

  @override
  State<SpecializationWindow> createState() => _SpecializationWindowState();
}

class _SpecializationWindowState extends State<SpecializationWindow> {
  String? _notice;

  MenuChoice _choiceFor(GuardianBranchDef branch) => (
    id: 'branch:${branch.id}',
    range: branch.level.range,
    command: SpecializeGuardian(widget.guardian.id, branchId: branch.id),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final def = widget.guardian.def;
    final color = colorFor(def.id, def.color);
    final marked = def.branches
        .where((branch) => widget.preview == 'branch:${branch.id}')
        .firstOrNull;
    final busy = widget.chosen != null;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: TextScaleLimits.battle,
      child: ColoredBox(
        color: const Color(0x8C1B0F08),
        child: SafeArea(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RiveTitleSign(title: l10n.specializeTitle, width: 270),
                      const SizedBox(height: 4),
                      RiveTooltip(
                        text: _notice ?? l10n.specializeSubtitle,
                        visible: true,
                        arrow: false,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RiveButton.round(
                            key: const ValueKey('menu-branch-close'),
                            label: l10n.menuClose,
                            icon: RiveIcon.close,
                            onPressed: busy ? null : widget.onClose,
                          ),
                          const SizedBox(width: 12),
                          RiveButton(
                            key: const ValueKey('menu-branch-confirm'),
                            label: l10n.specializeChoose,
                            icon: RiveIcon.check,
                            onPressed:
                                marked == null ||
                                    busy ||
                                    !widget.canAfford(marked.level.cost)
                                ? null
                                : () => widget.onChoose(_choiceFor(marked)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  for (final (index, branch) in def.branches.indexed) ...[
                    if (index > 0) const SizedBox(width: 12),
                    RiveBranchCard(
                      key: ValueKey('menu-branch-${branch.id}'),
                      guardianId: def.id,
                      name: widget.branchNameOf(branch.id),
                      description: widget.branchDescriptionOf(branch.id),
                      cost: branch.level.cost,
                      color: color,
                      selected: widget.preview == 'branch:${branch.id}',
                      affordable: widget.canAfford(branch.level.cost),
                      chosen: widget.chosen == 'branch:${branch.id}',
                      onTap: () {
                        if (busy) return;
                        setState(() => _notice = null);
                        widget.onChoose(_choiceFor(branch));
                      },
                      onDenied: () =>
                          setState(() => _notice = l10n.rejectNotEnoughCorn),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
