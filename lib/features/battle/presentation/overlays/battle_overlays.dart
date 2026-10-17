import 'package:flutter/material.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/widgets/stars_row.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Nombres de los overlays de Flame de la partida (ver
/// `GameWidget.overlayBuilderMap` en `BattleScreen`).
abstract final class BattleOverlays {
  static const pause = 'pause';
  static const won = 'won';
  static const lost = 'lost';
}

class PauseOverlay extends StatelessWidget {
  const new({
    required this.onResume,
    required this.onRetry,
    required this.onExit,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _OverlayCard(
      title: l10n.hudPause,
      actions: [
        OutlinedButton(
          key: const ValueKey('battle-exit'),
          onPressed: onExit,
          child: Text(l10n.pauseExit),
        ),
        OutlinedButton(
          key: const ValueKey('battle-retry'),
          onPressed: onRetry,
          child: Text(l10n.battleRetry),
        ),
        FilledButton(
          key: const ValueKey('pause-resume'),
          onPressed: onResume,
          child: Text(l10n.pauseResume),
        ),
      ],
    );
  }
}

class VictoryOverlay extends StatelessWidget {
  const new({
    required this.stars,
    required this.potatoes,
    required this.cornHarvested,
    required this.onRetry,
    required this.onExit,
    this.unlocked = const [],
    this.onNext,
    super.key,
  });

  /// Nombres de lo que abrió esta victoria (niveles y guardianes).
  final List<String> unlocked;

  final int stars;
  final int potatoes;
  final int cornHarvested;

  /// `null` en el último nivel.
  final VoidCallback? onNext;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onNext = this.onNext;
    final textTheme = Theme.of(context).textTheme;
    return _OverlayCard(
      title: l10n.battleWon,
      body: Column(
        children: [
          StarsRow(stars: stars, size: 44),
          const SizedBox(height: 8),
          Text(l10n.victoryPotatoes(potatoes), style: textTheme.titleMedium),
          Text(l10n.victoryCorn(cornHarvested), style: textTheme.titleMedium),
          if (unlocked.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.victoryUnlocked(unlocked.join(', ')),
              key: const ValueKey('victory-unlocked'),
              style: textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        _exitButton(l10n, primary: onNext == null),
        OutlinedButton(
          key: const ValueKey('battle-retry'),
          onPressed: onRetry,
          child: Text(l10n.battleRetry),
        ),
        if (onNext != null)
          FilledButton(
            key: const ValueKey('victory-next'),
            onPressed: onNext,
            child: Text(l10n.victoryNext),
          ),
      ],
    );
  }

  Widget _exitButton(AppLocalizations l10n, {required bool primary}) {
    const key = ValueKey('battle-exit');
    final label = Text(l10n.toValley);
    return primary
        ? FilledButton(key: key, onPressed: onExit, child: label)
        : OutlinedButton(key: key, onPressed: onExit, child: label);
  }
}

class DefeatOverlay extends StatelessWidget {
  const new({
    required this.onRetry,
    required this.onExit,
    this.onRevive,
    this.revivePotatoes = 0,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onExit;

  /// Ver un anuncio para seguir con [revivePotatoes] papas. Sin él (no hay
  /// anuncio cargado o ya se revivió), no hay botón.
  final VoidCallback? onRevive;
  final int revivePotatoes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _OverlayCard(
      title: l10n.battleLost,
      actions: [
        if (onRevive case final onRevive?)
          OutlinedButton.icon(
            key: const ValueKey('battle-revive'),
            icon: const Icon(Icons.ondemand_video),
            onPressed: onRevive,
            label: Text(l10n.adRevive(revivePotatoes)),
          ),
        OutlinedButton(
          key: const ValueKey('battle-exit'),
          onPressed: onExit,
          child: Text(l10n.toValley),
        ),
        FilledButton(
          key: const ValueKey('battle-retry'),
          onPressed: onRetry,
          child: Text(l10n.battleRetry),
        ),
      ],
    );
  }
}

/// Un velo sobre la partida con una tarjeta al centro: título, contenido
/// opcional y botones (el principal, a la derecha).
class _OverlayCard extends StatelessWidget {
  const new({required this.title, required this.actions, this.body});

  final String title;
  final Widget? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    return ColoredBox(
      color: GameColors.of(context).overlayScrim,
      child: SafeArea(
        child: Center(
          // Con letra grande o pantallas bajas, la tarjeta se desplaza en
          // vez de cortarse.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (body != null) ...[const SizedBox(height: 12), body],
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
