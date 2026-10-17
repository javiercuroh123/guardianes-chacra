import 'package:guardianes_chacra/core/events/event_bus.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/core/services/sound_limiter.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Qué vibración pide el juego (la pantalla la traduce a `HapticFeedback`).
enum Haptic { collcaDamaged, boss }

/// El sonido y la vibración de una partida. Escucha los eventos de la
/// simulación igual que `BattleGame` para dibujar, y no decide nada del
/// juego.
///
/// Los sonidos frecuentes (disparos, impactos, plagas derrotadas, la collca)
/// pasan por un [SoundLimiter]; los que importan una sola vez (jefe,
/// victoria, derrota) suenan siempre.
class BattleFeedback {
  new({
    required EventBus<SimEvent> events,
    required this.audio,
    required this._pests,
    required this.vibrationEnabled,
    required this.vibrate,
    String? music,
    Duration Function()? now,
  }) {
    final stopwatch = Stopwatch()..start();
    final clock = now ?? () => stopwatch.elapsed;
    _sounds = SoundLimiter(now: clock);
    // La vibración de la collca se nota mejor espaciada.
    _haptics = SoundLimiter(
      now: clock,
      minInterval: const Duration(milliseconds: 300),
    );
    audio.playMusic(music);
    events.on<SimEvent>(_onEvent);
  }

  final AudioService audio;
  final bool Function() vibrationEnabled;
  final void Function(Haptic haptic) vibrate;
  final Map<String, PestDef> _pests;
  late final SoundLimiter<Sfx> _sounds;
  late final SoundLimiter<Haptic> _haptics;

  void _onEvent(SimEvent event) {
    switch (event) {
      case GuardianFired() || AreaPulsed():
        _limited(Sfx.shot);
      case ProjectileImpacted():
        _limited(Sfx.impact);
      case PestDefeated():
        _limited(Sfx.pestDefeated);
      case CollcaDamaged():
        _limited(Sfx.collcaDamaged);
        _vibrate(Haptic.collcaDamaged);
      case PestSpawned(:final pestType) when _pests[pestType]?.boss ?? false:
        audio.playSfx(Sfx.boss);
        _vibrate(Haptic.boss);
      case LevelWon():
        audio
          ..playMusic(null)
          ..playSfx(Sfx.victory);
      case LevelLost():
        audio
          ..playMusic(null)
          ..playSfx(Sfx.defeat);
      case _:
        break;
    }
  }

  void _limited(Sfx sfx) {
    if (_sounds.tryPlay(sfx)) audio.playSfx(sfx);
  }

  void _vibrate(Haptic haptic) {
    if (vibrationEnabled() && _haptics.tryPlay(haptic)) vibrate(haptic);
  }
}
