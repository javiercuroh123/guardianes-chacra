import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// La barra de arriba de la partida: maíz, papas y oleada a la izquierda;
/// siguiente oleada, velocidad y pausa a la derecha.
///
/// Solo muestra `battleHudProvider` y avisa los toques: la pantalla decide
/// qué hacer con ellos. Con letra grande crece hasta
/// [TextScaleLimits.battle], para no tapar el mapa.
class BattleHud extends ConsumerWidget {
  const new({
    required this.onNextWave,
    required this.onToggleSpeed,
    required this.onPause,
    this.onDevTools,
    super.key,
  });

  final VoidCallback onNextWave;
  final VoidCallback onToggleSpeed;
  final VoidCallback onPause;

  /// Abre el panel de desarrollo; sin él (en release), no hay botón.
  final VoidCallback? onDevTools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hud = ref.watch(battleHudProvider);
    if (hud == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fast = hud.speed == GameSpeed.fast;
    final buttonStyle = IconButton.styleFrom(
      backgroundColor: colors.hud,
      foregroundColor: colors.onHud,
    );
    // A x2 el botón se pinta de maíz para que se note que está acelerado.
    final (speedBackground, speedForeground) = fast
        ? (scheme.secondary, scheme.onSecondary)
        : (colors.hud, colors.onHud);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: TextScaleLimits.battle,
      child: Row(
        children: [
          // Los datos ocupan lo que dejan los botones. Si no les alcanza
          // (letra grande en un teléfono angosto), se achican un poco en
          // lugar de desbordarse.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
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
                    const SizedBox(width: 6),
                    _Chip(
                      key: const ValueKey('hud-wave'),
                      text: l10n.hudWave(hud.wave, hud.totalWaves),
                      semanticsLabel: l10n.hudWave(hud.wave, hud.totalWaves),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (hud.nextWaveSeconds case final seconds?) ...[
            _NextWaveButton(
              seconds: seconds,
              bonus: hud.earlyCallBonus,
              onTap: onNextWave,
            ),
            const SizedBox(width: 6),
          ],
          IconButton(
            key: const ValueKey('hud-speed'),
            tooltip: l10n.hudSpeedSemantics(fast ? '2' : '1'),
            style: IconButton.styleFrom(
              backgroundColor: speedBackground,
              foregroundColor: speedForeground,
            ),
            onPressed: onToggleSpeed,
            // `foregroundColor` solo colorea íconos: el texto lleva su color.
            icon: Text(
              fast ? 'x2' : 'x1',
              style: TextStyle(
                color: speedForeground,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onDevTools case final onDevTools?)
            IconButton(
              key: const ValueKey('hud-dev'),
              tooltip: 'Desarrollo',
              style: buttonStyle,
              onPressed: onDevTools,
              icon: const Icon(Icons.bug_report_outlined),
            ),
          IconButton(
            key: const ValueKey('hud-pause'),
            tooltip: l10n.hudPause,
            style: buttonStyle,
            onPressed: onPause,
            icon: const Icon(Icons.pause),
          ),
        ],
      ),
    );
  }
}

/// "⏭ 12 s +18": llama ya la oleada que viene y da maíz por el tiempo que se
/// salta.
class _NextWaveButton extends StatelessWidget {
  const new({required this.seconds, required this.bonus, required this.onTap});

  final int seconds;
  final int bonus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = GameColors.of(context);
    return Semantics(
      button: true,
      label: l10n.hudNextWaveSemantics(seconds, bonus),
      excludeSemantics: true,
      child: Material(
        color: colors.hud,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('hud-next-wave'),
          onTap: onTap,
          child: ConstrainedBox(
            // El mismo alto que tocan los demás botones del HUD.
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.skip_next, color: colors.onHud),
                  const SizedBox(width: 4),
                  Text(
                    '$seconds s',
                    style: TextStyle(
                      color: colors.onHud,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.hudNextWave(bonus),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const new({required this.text, required this.semanticsLabel, super.key});

  final String text;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.hud,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              color: colors.onHud,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
