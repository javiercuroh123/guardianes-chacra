import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_screen.dart';
import 'package:guardianes_chacra/features/battle/presentation/style/creature_icons.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_pests.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Antes de jugar: el nombre del nivel, cuántas oleadas tiene y las plagas
/// que vienen (las que el jugador todavía no vio llevan "Nueva").
class LevelPreviewScreen extends ConsumerWidget {
  const new({required this.levelId, this.assets, super.key});

  final String levelId;

  /// Para los tests: se pasa a la partida (ver `BattleScreen.assets`).
  final BattleAssets? assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return switch (ref.watch(gameContentProvider)) {
      AsyncData(:final value) => _preview(context, ref, value, l10n),
      AsyncError(:final error) => Scaffold(
        body: Center(child: Text(l10n.contentLoadError('$error'))),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }

  Widget _preview(
    BuildContext context,
    WidgetRef ref,
    GameContent content,
    AppLocalizations l10n,
  ) {
    final language = Localizations.localeOf(context).languageCode;
    final level = content.levels.firstWhere((level) => level.id == levelId);
    final discovered = ref.watch(
      progressProvider.select((progress) => progress.discoveredPests),
    );
    final textTheme = Theme.of(context).textTheme;
    String text(String key) => content.texts.text(key, language: language);

    return Scaffold(
      appBar: AppBar(title: Text(text(ContentTexts.levelName(level.id)))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.previewWaves(level.waves.length),
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.previewPests, style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final pestId in pestsAppearingIn(level))
                        _PestChip(
                          key: ValueKey('preview-pest-$pestId'),
                          icon: PestIcon(def: content.pests[pestId]!, size: 32),
                          name: text(ContentTexts.pestName(pestId)),
                          isNew: !discovered.contains(pestId),
                          newLabel: l10n.previewNew,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.back),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const ValueKey('preview-start'),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            BattleScreen(levelId: level.id, assets: assets),
                      ),
                    ),
                    child: Text(l10n.previewStart),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PestChip extends StatelessWidget {
  const new({
    required this.icon,
    required this.name,
    required this.isNew,
    required this.newLabel,
    super.key,
  });

  final Widget icon;
  final String name;
  final bool isNew;
  final String newLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: icon,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(name),
          if (isNew) ...[
            const SizedBox(width: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.tertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  newLabel,
                  style: TextStyle(
                    color: scheme.onTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
