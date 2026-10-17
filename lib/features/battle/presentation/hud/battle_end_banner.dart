import 'package:flutter/material.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Aviso de fin de la partida (provisional: la Fase 6 trae los overlays de
/// victoria y derrota con estrellas).
class BattleEndBanner extends StatelessWidget {
  const new({
    required this.won,
    required this.onRetry,
    required this.onExit,
    super.key,
  });

  final bool won;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  won ? l10n.battleWon : l10n.battleLost,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      key: const ValueKey('battle-exit'),
                      onPressed: onExit,
                      child: Text(l10n.battleExit),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      key: const ValueKey('battle-retry'),
                      onPressed: onRetry,
                      child: Text(l10n.battleRetry),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
