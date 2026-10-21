import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_bestiary_grid.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/app/rive/rive_pest_card.dart';
import 'package:guardianes_chacra/app/rive/rive_portrait.dart';
import 'package:guardianes_chacra/app/rive/rive_segmented.dart';
import 'package:guardianes_chacra/app/rive/rive_stat_pill.dart';
import 'package:guardianes_chacra/app/rive/rive_tab.dart';
import 'package:guardianes_chacra/app/rive/rive_title_sign.dart';
import 'package:guardianes_chacra/app/rive/rive_valley.dart';
import 'package:guardianes_chacra/app/ui_feedback.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/battle_palette.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:rive/rive.dart' as rive;

/// Enciclopedia de plagas y guardianes, en dos pestañas que se deslizan. A
/// la izquierda la grilla de fichas (Rive); a la derecha, el detalle de la
/// elegida (en Flutter: los textos largos crecen con la letra y TalkBack
/// los lee).
///
/// Una ficha es "?" hasta que el jugador la descubre (una plaga, al verla
/// en una partida; un guardián, al construirlo). Recién descubierta queda
/// boca abajo: la primera vez que se toca se da vuelta y muestra "¡Nuevo!".
class BestiaryScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends ConsumerState<BestiaryScreen> {
  final _pages = PageController();
  int _tab = 0;
  String? _pest;
  String? _guardian;

  /// El nivel del guardián que muestra el detalle (0 a 2).
  int _level = 0;

  /// Las fichas dadas vuelta en esta visita: llevan "¡Nuevo!" hasta salir.
  final _revealed = <String>{};

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _showTab(int tab) {
    ref.read(uiFeedbackProvider).tap();
    _pages.animateToPage(
      tab,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _tapPest(String id, Progress progress) {
    final notifier = ref.read(progressProvider.notifier);
    if (progress.discoveredPests.contains(id) &&
        !progress.seenPests.contains(id)) {
      _revealed.add('pest:$id');
      notifier.seePest(id);
      ref.read(uiFeedbackProvider).star();
    } else {
      ref.read(uiFeedbackProvider).tap();
    }
    setState(() => _pest = id);
  }

  void _tapGuardian(String id, Progress progress) {
    final notifier = ref.read(progressProvider.notifier);
    if (progress.discoveredGuardians.contains(id) &&
        !progress.seenGuardians.contains(id)) {
      _revealed.add('guardian:$id');
      notifier.seeGuardian(id);
      ref.read(uiFeedbackProvider).star();
    } else {
      ref.read(uiFeedbackProvider).tap();
    }
    setState(() {
      if (_guardian != id) _level = 0;
      _guardian = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: RiveValley.sky,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frame = ValleyFrame.of(constraints.biggest);
          return Stack(
            fit: StackFit.expand,
            children: [
              RiveValley(
                fit: frame.cover ? rive.Fit.cover : rive.Fit.fitWidth,
                alignment: frame.cover
                    ? Alignment.center
                    : Alignment.bottomCenter,
              ),
              SafeArea(
                minimum: const EdgeInsets.all(8),
                child: switch (ref.watch(gameContentProvider)) {
                  AsyncData(:final value) => _body(context, value),
                  AsyncError(:final error) => Center(
                    child: Text(l10n.contentLoadError('$error')),
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, GameContent content) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(progressProvider);
    return Column(
      children: [
        _Header(title: l10n.menuBestiary),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RiveTab(
              key: const ValueKey('bestiary-tab-pests'),
              label: l10n.bestiaryPests,
              icon: RiveIcon.bug,
              selected: _tab == 0,
              onTap: () => _showTab(0),
            ),
            const SizedBox(width: 10),
            RiveTab(
              key: const ValueKey('bestiary-tab-guardians'),
              label: l10n.bestiaryGuardians,
              icon: RiveIcon.paw,
              selected: _tab == 1,
              onTap: () => _showTab(1),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: (tab) => setState(() => _tab = tab),
            children: [
              _pestsPage(context, content, progress),
              _guardiansPage(context, content, progress),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pestsPage(
    BuildContext context,
    GameContent content,
    Progress progress,
  ) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    String text(String key) => content.texts.text(key, language: language);
    final pests = content.pests.values.toList();
    final selected = _pest ?? _firstSeen(pests.map((p) => p.id), progress);
    final entries = [
      for (final pest in pests)
        _entry(
          id: pest.id,
          kind: 'pest',
          name: text(ContentTexts.pestName(pest.id)),
          color: colorFor(pest.id, pest.color),
          discovered: progress.discoveredPests.contains(pest.id),
          seen: progress.seenPests.contains(pest.id),
          l10n: l10n,
        ),
    ];
    final pest = content.pests[selected];
    return _Page(
      grid: RiveBestiaryGrid(
        entries: entries,
        selectedId: selected,
        columns: 4,
        newLabel: l10n.bestiaryNew,
        keyPrefix: 'bestiary-pest-',
        onTap: (id) => _tapPest(id, progress),
      ),
      columns: 4,
      rows: (entries.length / 4).ceil(),
      detail: pest == null
          ? const SizedBox.shrink()
          : _PestDetail(
              key: ValueKey('bestiary-detail-${pest.id}'),
              pest: pest,
              name: text(ContentTexts.pestName(pest.id)),
              description: text(ContentTexts.pestDescription(pest.id)),
              discovered: progress.discoveredPests.contains(pest.id),
              seen: progress.seenPests.contains(pest.id),
            ),
    );
  }

  Widget _guardiansPage(
    BuildContext context,
    GameContent content,
    Progress progress,
  ) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    String text(String key) => content.texts.text(key, language: language);
    final guardians = content.guardians.values.toList();
    final selected =
        _guardian ?? _firstSeen(guardians.map((g) => g.id), progress);
    final entries = [
      for (final guardian in guardians)
        _entry(
          id: guardian.id,
          kind: 'guardian',
          name: text(ContentTexts.guardianName(guardian.id)),
          color: colorFor(guardian.id, guardian.color),
          discovered: progress.discoveredGuardians.contains(guardian.id),
          seen: progress.seenGuardians.contains(guardian.id),
          l10n: l10n,
        ),
    ];
    final guardian = content.guardians[selected];
    return _Page(
      grid: RiveBestiaryGrid(
        entries: entries,
        selectedId: selected,
        columns: 3,
        newLabel: l10n.bestiaryNew,
        keyPrefix: 'bestiary-guardian-',
        onTap: (id) => _tapGuardian(id, progress),
      ),
      columns: 3,
      rows: (entries.length / 3).ceil(),
      detail: guardian == null
          ? const SizedBox.shrink()
          : _GuardianDetail(
              key: ValueKey('bestiary-detail-${guardian.id}'),
              guardian: guardian,
              name: text(ContentTexts.guardianName(guardian.id)),
              description: text(ContentTexts.guardianDescription(guardian.id)),
              branches: [
                for (final branch in guardian.branches)
                  (
                    name: text(ContentTexts.branchName(guardian.id, branch.id)),
                    description: text(
                      ContentTexts.branchDescription(guardian.id, branch.id),
                    ),
                  ),
              ],
              discovered: progress.discoveredGuardians.contains(guardian.id),
              seen: progress.seenGuardians.contains(guardian.id),
              level: _level,
              onLevel: (level) => setState(() => _level = level),
            ),
    );
  }

  /// La primera ficha descubierta y ya abierta; si no hay, la primera.
  String? _firstSeen(Iterable<String> ids, Progress progress) {
    for (final id in ids) {
      if (progress.seenPests.contains(id) ||
          progress.seenGuardians.contains(id)) {
        return id;
      }
    }
    return ids.firstOrNull;
  }

  BestiaryEntryData _entry({
    required String id,
    required String kind,
    required String name,
    required Color color,
    required bool discovered,
    required bool seen,
    required AppLocalizations l10n,
  }) {
    final isNew = _revealed.contains('$kind:$id');
    final faceDown = discovered && !seen;
    return BestiaryEntryData(
      id: id,
      name: discovered ? name : '???',
      color: color,
      isGuardian: kind == 'guardian',
      locked: !discovered,
      faceDown: faceDown,
      isNew: isNew,
      semanticsLabel: !discovered
          ? l10n.bestiaryUnknown
          : faceDown
          ? l10n.bestiaryNew
          : isNew
          ? '$name, ${l10n.bestiaryNew}'
          : name,
    );
  }
}

/// Volver (redondo) y el cartel del título.
class _Header extends StatelessWidget {
  const new({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: RiveButton.round(
            key: const ValueKey('bestiary-back'),
            label: AppLocalizations.of(context).back,
            icon: RiveIcon.back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: FittedBox(child: RiveTitleSign(title: title, width: 200)),
        ),
      ],
    ),
  );
}

/// Una pestaña: la grilla en su panel (del ancho justo para [columns]
/// fichas a lo alto que haya) y el detalle en otro panel.
class _Page extends StatelessWidget {
  const new({
    required this.grid,
    required this.columns,
    required this.rows,
    required this.detail,
  });

  final Widget grid;
  final int columns;
  final int rows;
  final Widget detail;

  static const _padding = EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const entry = BestiaryGridRive.entrySize;
      const gap = BestiaryGridRive.gap;
      final gridWidth = columns * entry.width + (columns - 1) * gap;
      final gridHeight = rows * entry.height + (rows - 1) * gap;
      final scale = ((constraints.maxHeight - _padding.vertical) / gridHeight)
          .clamp(0.3, (constraints.maxWidth * 0.5) / gridWidth);
      return Row(
        children: [
          // La grilla en su propio nodo: TalkBack la lee por filas. Sin él,
          // el detalle (tan alto como las dos filas) junta las fichas con
          // él y las lee por columnas.
          Semantics(
            container: true,
            child: RivePanel(
              padding: _padding,
              child: SizedBox(
                width: gridWidth * scale,
                height: gridHeight * scale,
                child: grid,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RivePanel(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: SizedBox.expand(
                child: SingleChildScrollView(child: detail),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Las pastillas de las estadísticas, en filas.
class _Stats extends StatelessWidget {
  const new({required this.pills});

  final List<(RiveIcon, String, String)> pills;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final (icon, label, value) in pills)
        RiveStatPill(icon: icon, label: label, value: value, scale: 0.55),
    ],
  );
}

/// El encabezado del detalle: el retrato, el nombre y la descripción.
class _DetailHeader extends StatelessWidget {
  const new({required this.portrait, required this.title, required this.text});

  final Widget portrait;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    final theme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El nombre ya va al lado: TalkBack no lo lee dos veces.
        ExcludeSemantics(child: portrait),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.titleLarge?.copyWith(
                  color: colors.onHud,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: theme.bodyMedium?.copyWith(color: colors.onHud),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PestDetail extends StatelessWidget {
  const new({
    required this.pest,
    required this.name,
    required this.description,
    required this.discovered,
    required this.seen,
    super.key,
  });

  final PestDef pest;
  final String name;
  final String description;
  final bool discovered;
  final bool seen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    final color = colorFor(pest.id, pest.color);
    if (!discovered || !seen) {
      return _DetailHeader(
        portrait: RivePestPortrait(
          pestId: PestPortraitRive.unknown,
          name: l10n.bestiaryUnknown,
          color: color,
        ),
        title: discovered ? l10n.bestiaryNew : l10n.bestiaryUnknown,
        text: discovered ? l10n.bestiaryTapToReveal : l10n.bestiaryHiddenPest,
      );
    }
    final flying = pest.tags.contains(PestTag.flying);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          portrait: RivePestPortrait(pestId: pest.id, name: name, color: color),
          title: name,
          text: description,
        ),
        const SizedBox(height: 10),
        _Stats(
          pills: [
            (
              RiveIcon.heart,
              l10n.statLabelHealth,
              number.format(pest.maxHealth),
            ),
            (
              RiveIcon.fastForward,
              l10n.statLabelSpeed,
              number.format(pest.speed),
            ),
            (RiveIcon.corn, l10n.statLabelReward, '+${pest.cornReward}'),
            (RiveIcon.potato, l10n.statLabelDamage, '${pest.potatoDamage}'),
            (
              flying ? RiveIcon.air : RiveIcon.ground,
              l10n.statLabelMoves,
              flying ? l10n.movesFlying : l10n.movesGround,
            ),
            if (pest.armor > 0)
              (RiveIcon.shield, l10n.statLabelArmor, number.format(pest.armor)),
            for (final MapEntry(:key, :value) in pest.resistances.entries)
              (
                RiveIcon.damage,
                l10n.statLabelResistance,
                l10n.statResistance(switch (key) {
                  DamageType.physical => l10n.damagePhysical,
                  DamageType.fire => l10n.damageFire,
                }, number.format(value)),
              ),
          ],
        ),
        if (pest.immunities.contains('slow')) ...[
          const SizedBox(height: 6),
          Text(
            l10n.statImmune,
            style: TextStyle(
              color: GameColors.of(context).onHud,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _GuardianDetail extends StatelessWidget {
  const new({
    required this.guardian,
    required this.name,
    required this.description,
    required this.branches,
    required this.discovered,
    required this.seen,
    required this.level,
    required this.onLevel,
    super.key,
  });

  final GuardianDef guardian;
  final String name;
  final String description;
  final List<({String name, String description})> branches;
  final bool discovered;
  final bool seen;
  final int level;
  final ValueChanged<int> onLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    );
    final color = colorFor(guardian.id, guardian.color);
    if (!discovered || !seen) {
      return _DetailHeader(
        portrait: RivePortrait(
          guardianId: PortraitRive.unknown,
          name: l10n.bestiaryUnknown,
          color: color,
          size: 96,
        ),
        title: discovered ? l10n.bestiaryNew : l10n.bestiaryUnknown,
        text: discovered
            ? l10n.bestiaryTapToReveal
            : l10n.bestiaryHiddenGuardian,
      );
    }
    final levels = guardian.levels;
    final stats = levels[level.clamp(0, levels.length - 1)];
    final targets = stats.targets;
    final (targetsIcon, targetsLabel) = targets.isEmpty
        ? (RiveIcon.star, l10n.targetsSupport)
        : targets.length == PestTag.values.length
        ? (RiveIcon.target, l10n.targetsBoth)
        : targets.contains(PestTag.flying)
        ? (RiveIcon.air, l10n.targetsFlying)
        : (RiveIcon.ground, l10n.targetsGround);
    final titleStyle = TextStyle(
      color: colors.onHud,
      fontWeight: FontWeight.w800,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          portrait: RivePortrait(
            guardianId: guardian.id,
            name: name,
            color: color,
            size: 96,
          ),
          title: name,
          text: description,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(l10n.bestiaryLevels, style: titleStyle),
            const SizedBox(width: 10),
            RiveSegmented(
              key: const ValueKey('bestiary-levels'),
              labels: [for (var i = 0; i < levels.length; i++) 'I' * (i + 1)],
              selected: level,
              onChanged: onLevel,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Stats(
          pills: [
            (
              RiveIcon.corn,
              level == 0 ? l10n.statLabelCost : l10n.statLabelUpgrade,
              '${stats.cost}',
            ),
            (RiveIcon.target, l10n.statLabelRange, number.format(stats.range)),
            (targetsIcon, l10n.statLabelTargets, targetsLabel),
          ],
        ),
        if (branches.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(l10n.bestiaryBranches, style: titleStyle),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, branch) in branches.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.hud,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.star, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(branch.name, style: titleStyle),
                          const SizedBox(height: 2),
                          Text(
                            branch.description,
                            style: TextStyle(color: colors.onHud),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
