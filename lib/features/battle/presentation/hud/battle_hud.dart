import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/rive/rive_banner.dart';
import 'package:guardianes_chacra/app/rive/rive_button.dart';
import 'package:guardianes_chacra/app/rive/rive_counter.dart';
import 'package:guardianes_chacra/app/rive/rive_icons.dart';
import 'package:guardianes_chacra/app/rive/rive_next_wave.dart';
import 'package:guardianes_chacra/app/rive/rive_speed_button.dart';
import 'package:guardianes_chacra/app/rive/rive_wave_bar.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/presentation/hud/battle_hud_state.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// La barra de arriba de la partida: maíz, papas y oleadas a la izquierda;
/// velocidad, desarrollo (solo en debug) y pausa a la derecha. La
/// siguiente oleada va abajo a la derecha ([BattleNextWave]).
///
/// Solo muestra `battleHudProvider` y avisa los toques: la pantalla decide
/// qué hacer con ellos. Con letra grande crece hasta
/// [TextScaleLimits.battle], para no tapar el mapa.
class BattleHud extends ConsumerWidget {
  const new({
    required this.onToggleSpeed,
    required this.onPause,
    this.onDevTools,
    super.key,
  });

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
    final fast = hud.speed == GameSpeed.fast;
    final waveLabel = l10n.hudWave(hud.wave, hud.totalWaves);
    final potatoesLabel = l10n.hudPotatoesOf(hud.potatoes, hud.maxPotatoes);

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
                    RiveCounter(
                      key: const ValueKey('hud-corn'),
                      value: hud.corn,
                      semanticsLabel: l10n.hudCorn(hud.corn),
                      fallback: _Chip(
                        text: '🌽 ${hud.corn}',
                        semanticsLabel: l10n.hudCorn(hud.corn),
                      ),
                    ),
                    const SizedBox(width: 6),
                    RiveCounter(
                      key: const ValueKey('hud-potatoes'),
                      value: hud.potatoes,
                      max: hud.maxPotatoes,
                      icon: RiveIcon.potato,
                      danger: hud.lowPotatoes,
                      semanticsLabel: potatoesLabel,
                      fallback: _Chip(
                        text: '🥔 ${hud.potatoes}/${hud.maxPotatoes}',
                        semanticsLabel: potatoesLabel,
                      ),
                    ),
                    const SizedBox(width: 6),
                    RiveWaveBar(
                      key: const ValueKey('hud-wave'),
                      wave: hud.wave,
                      totalWaves: hud.totalWaves,
                      label: waveLabel,
                      boss: hud.boss,
                      fallback: _Chip(
                        text: waveLabel,
                        semanticsLabel: waveLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          RiveSpeedButton(
            key: const ValueKey('hud-speed'),
            fast: fast,
            semanticsLabel: l10n.hudSpeedSemantics(fast ? '2' : '1'),
            onPressed: onToggleSpeed,
          ),
          const SizedBox(width: 6),
          if (onDevTools case final onDevTools?) ...[
            IconButton(
              key: const ValueKey('hud-dev'),
              tooltip: 'Desarrollo',
              style: IconButton.styleFrom(
                backgroundColor: colors.hud,
                foregroundColor: colors.onHud,
              ),
              onPressed: onDevTools,
              icon: const Icon(Icons.bug_report_outlined),
            ),
            const SizedBox(width: 6),
          ],
          RiveButton.round(
            key: const ValueKey('hud-pause'),
            label: l10n.hudPause,
            icon: RiveIcon.pause,
            onPressed: onPause,
          ),
        ],
      ),
    );
  }
}

/// "Siguiente oleada", abajo a la derecha: llama ya la oleada que viene y
/// da maíz por el tiempo que se salta. Solo está mientras hay una cuenta
/// regresiva; al llamarla se queda un momento para que se vea el rebote.
class BattleNextWave extends ConsumerStatefulWidget {
  const new({required this.onNextWave, super.key});

  final VoidCallback onNextWave;

  /// Lo que tarda en desvanecerse al quedarse sin cuenta regresiva.
  static const leave = Duration(milliseconds: 450);

  @override
  ConsumerState<BattleNextWave> createState() => _BattleNextWaveState();
}

class _BattleNextWaveState extends ConsumerState<BattleNextWave> {
  /// Lo último que mostró: sigue a la vista mientras se desvanece.
  ({int seconds, int total, int bonus})? _shown;
  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    final hud = ref.watch(battleHudProvider);
    final seconds = hud?.nextWaveSeconds;
    if (hud != null && seconds != null) {
      _shown = (
        seconds: seconds,
        total: hud.nextWaveTotalSeconds ?? seconds,
        bonus: hud.earlyCallBonus,
      );
      _leaving = false;
    } else if (_shown != null) {
      _leaving = true;
    }
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    // Aparece de una vez (se puede tocar enseguida); al irse se desvanece
    // sin cambiar de lugar en el árbol, así se ve el rebote de "llamada".
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: TextScaleLimits.battle,
      child: IgnorePointer(
        ignoring: _leaving,
        child: AnimatedOpacity(
          opacity: _leaving ? 0 : 1,
          duration: _leaving ? BattleNextWave.leave : Duration.zero,
          onEnd: () {
            if (_leaving && mounted) setState(() => _shown = null);
          },
          child: RiveNextWaveButton(
            key: const ValueKey('hud-next-wave'),
            seconds: shown.seconds,
            totalSeconds: shown.total,
            bonusLabel: l10n.hudNextWave(shown.bonus),
            semanticsLabel: l10n.hudNextWaveSemantics(
              shown.seconds,
              shown.bonus,
            ),
            onPressed: widget.onNextWave,
          ),
        ),
      ),
    );
  }
}

/// El cartel "Oleada N" que cae al empezar cada oleada (rojo, con aviso,
/// si trae al jefe). No recibe toques.
class BattleWaveBanner extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hud = ref.watch(battleHudProvider);
    if (hud == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return RiveWaveBanner(
      title: l10n.hudBannerWave(hud.wave),
      subtitle: l10n.hudBannerBoss,
      boss: hud.boss,
      showCount: hud.startedWaves,
    );
  }
}

class _Chip extends StatelessWidget {
  const new({required this.text, required this.semanticsLabel});

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
