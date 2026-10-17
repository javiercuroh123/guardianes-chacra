import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/creature_icons.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Enciclopedia de plagas y guardianes. Cada ficha aparece como "?" hasta
/// que el jugador la descubre: una plaga, al verla en una partida; un
/// guardián, al construirlo.
class BestiaryScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.menuBestiary),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: l10n.bestiaryPests),
              Tab(text: l10n.bestiaryGuardians),
            ],
          ),
        ),
        body: switch (ref.watch(gameContentProvider)) {
          AsyncData(:final value) => TabBarView(
            children: [
              _PestEntries(
                content: value,
                progress: ref.watch(progressProvider),
              ),
              _GuardianEntries(
                content: value,
                progress: ref.watch(progressProvider),
              ),
            ],
          ),
          AsyncError(:final error) => Center(
            child: Text(l10n.contentLoadError('$error')),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _PestEntries extends StatelessWidget {
  const new({required this.content, required this.progress});

  final GameContent content;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = NumberFormat.decimalPattern(language);
    String text(String key) => content.texts.text(key, language: language);

    return _EntryList(
      children: [
        for (final pest in content.pests.values)
          if (progress.discoveredPests.contains(pest.id))
            _EntryCard(
              key: ValueKey('bestiary-pest-${pest.id}'),
              icon: PestIcon(def: pest, size: 44),
              title: text(ContentTexts.pestName(pest.id)),
              description: text(ContentTexts.pestDescription(pest.id)),
              facts: _pestFacts(pest, l10n, number),
            )
          else
            _EntryCard(
              key: ValueKey('bestiary-pest-${pest.id}'),
              icon: PestIcon(def: pest, size: 44, hidden: true),
              title: l10n.bestiaryUnknown,
            ),
      ],
    );
  }

  List<String> _pestFacts(
    PestDef pest,
    AppLocalizations l10n,
    NumberFormat number,
  ) => [
    l10n.statHealth(number.format(pest.maxHealth)),
    l10n.statSpeed(number.format(pest.speed)),
    if (pest.armor > 0) l10n.statArmor(number.format(pest.armor)),
    l10n.statReward('${pest.cornReward}'),
    l10n.statPotatoes('${pest.potatoDamage}'),
    if (pest.tags.contains(PestTag.flying)) l10n.statFlying,
    for (final MapEntry(:key, :value) in pest.resistances.entries)
      l10n.statResistance(switch (key) {
        DamageType.physical => l10n.damagePhysical,
        DamageType.fire => l10n.damageFire,
      }, number.format(value)),
    if (pest.immunities.contains('slow')) l10n.statImmune,
  ];
}

class _GuardianEntries extends StatelessWidget {
  const new({required this.content, required this.progress});

  final GameContent content;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final number = NumberFormat.decimalPattern(language);
    String text(String key) => content.texts.text(key, language: language);

    return _EntryList(
      children: [
        for (final guardian in content.guardians.values)
          if (progress.discoveredGuardians.contains(guardian.id))
            _EntryCard(
              key: ValueKey('bestiary-guardian-${guardian.id}'),
              icon: GuardianIcon(
                def: guardian,
                label: text(ContentTexts.guardianName(guardian.id))
                    .characters
                    .first
                    .toUpperCase(),
                size: 44,
              ),
              title: text(ContentTexts.guardianName(guardian.id)),
              description: text(ContentTexts.guardianDescription(guardian.id)),
              facts: _guardianFacts(guardian, l10n, number),
            )
          else
            _EntryCard(
              key: ValueKey('bestiary-guardian-${guardian.id}'),
              icon: GuardianIcon(
                def: guardian,
                label: '?',
                size: 44,
                hidden: true,
              ),
              title: l10n.bestiaryUnknown,
            ),
      ],
    );
  }

  List<String> _guardianFacts(
    GuardianDef guardian,
    AppLocalizations l10n,
    NumberFormat number,
  ) {
    final first = guardian.levels.first;
    final targets = first.targets;
    return [
      l10n.statCost('${first.cost}'),
      l10n.statRange(number.format(first.range)),
      if (targets.isEmpty)
        l10n.statSupport
      else if (targets.length == PestTag.values.length)
        l10n.statTargetsBoth
      else if (targets.contains(PestTag.flying))
        l10n.statTargetsFlying
      else
        l10n.statTargetsGround,
    ];
  }
}

class _EntryList extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, index) => children[index],
      ),
    ),
  );
}

class _EntryCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.description,
    this.facts = const [],
    super.key,
  });

  final Widget icon;
  final String title;
  final String? description;
  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  if (description case final description?) ...[
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                  if (facts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final fact in facts)
                          Chip(
                            label: Text(fact),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
