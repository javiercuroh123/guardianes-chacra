import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// HUD mínimo de la Fase 5: maíz, papas y oleada. La Fase 6 lo reemplaza
/// por el completo (siguiente oleada, pausa y velocidad).
class BattleHud extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hud = ref.watch(battleHudProvider);
    if (hud == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _Chip(
          key: const ValueKey('hud-corn'),
          text: '🌽 ${hud.corn}',
          semanticsLabel: l10n.hudCorn(hud.corn),
        ),
        const SizedBox(width: 6),
        _Chip(
          key: const ValueKey('hud-potatoes'),
          text: '🥔 ${hud.potatoes}',
          semanticsLabel: l10n.hudPotatoes(hud.potatoes),
        ),
        const Spacer(),
        _Chip(
          key: const ValueKey('hud-wave'),
          text: l10n.hudWave(hud.wave, hud.totalWaves),
          semanticsLabel: l10n.hudWave(hud.wave, hud.totalWaves),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const new({required this.text, required this.semanticsLabel, super.key});

  final String text;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    excludeSemantics: true,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC1B1B1B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
