import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:meta/meta.dart';

/// Lo que muestra el HUD de la partida.
@immutable
class BattleHudState {
  const new({
    required this.corn,
    required this.potatoes,
    required this.wave,
    required this.totalWaves,
    required this.status,
    int? maxPotatoes,
    this.startedWaves = 0,
    this.boss = false,
    this.nextWaveSeconds,
    this.nextWaveTotalSeconds,
    this.earlyCallBonus = 0,
    this.speed = GameSpeed.normal,
  }) : maxPotatoes = maxPotatoes ?? potatoes;

  factory of(Simulation simulation, {GameSpeed speed = GameSpeed.normal}) {
    final countdown = simulation.nextWaveCountdownTicks;
    final prep = simulation.nextWavePrepTicks;
    final started = simulation.startedWaves;
    return BattleHudState(
      corn: simulation.corn,
      potatoes: simulation.potatoes,
      maxPotatoes: simulation.startingPotatoes,
      // Antes de la primera oleada se muestra la 1 (la que viene).
      wave: started.clamp(1, simulation.totalWaves),
      totalWaves: simulation.totalWaves,
      startedWaves: started,
      boss: simulation.waveHasBoss(started - 1),
      status: simulation.status,
      nextWaveSeconds: countdown == null
          ? null
          : ticksToWholeSeconds(countdown),
      nextWaveTotalSeconds: prep == null ? null : ticksToWholeSeconds(prep),
      earlyCallBonus: simulation.earlyCallBonus,
      speed: speed,
    );
  }

  final int corn;
  final int potatoes;

  /// Las papas con las que empezó el nivel: el HUD muestra "8/10".
  final int maxPotatoes;
  final int wave;
  final int totalWaves;

  /// Oleadas que ya empezaron (0 antes de la primera): cuando sube, cae el
  /// cartel "Oleada N".
  final int startedWaves;

  /// La oleada en curso trae un jefe.
  final bool boss;
  final BattleStatus status;

  /// Segundos para la siguiente oleada, o `null` si no hay ninguna en
  /// cuenta regresiva (entonces no se puede llamar).
  final int? nextWaveSeconds;

  /// Lo que dura entera esa cuenta regresiva (el anillo lleno).
  final int? nextWaveTotalSeconds;

  /// Maíz extra por llamar ya la siguiente oleada.
  final int earlyCallBonus;

  final GameSpeed speed;

  /// Pocas papas: el contador late en rojo (un 30 % o menos).
  bool get lowPotatoes =>
      potatoes > 0 && potatoes <= (maxPotatoes * 0.3).ceil();

  @override
  bool operator ==(Object other) =>
      other is BattleHudState &&
      other.corn == corn &&
      other.potatoes == potatoes &&
      other.maxPotatoes == maxPotatoes &&
      other.wave == wave &&
      other.totalWaves == totalWaves &&
      other.startedWaves == startedWaves &&
      other.boss == boss &&
      other.status == status &&
      other.nextWaveSeconds == nextWaveSeconds &&
      other.nextWaveTotalSeconds == nextWaveTotalSeconds &&
      other.earlyCallBonus == earlyCallBonus &&
      other.speed == speed;

  @override
  int get hashCode => Object.hash(
    corn,
    potatoes,
    maxPotatoes,
    wave,
    totalWaves,
    startedWaves,
    boss,
    status,
    nextWaveSeconds,
    nextWaveTotalSeconds,
    earlyCallBonus,
    speed,
  );
}

/// El estado del HUD de la partida en curso. Lo actualiza la pantalla
/// cuando el juego avisa que algo cambió; los widgets solo lo leen.
class BattleHudController extends Notifier<BattleHudState?> {
  @override
  BattleHudState? build() => null;

  BattleHudState? get hud => state;

  set hud(BattleHudState? value) => state = value;
}

final NotifierProvider<BattleHudController, BattleHudState?> battleHudProvider =
    NotifierProvider.autoDispose<BattleHudController, BattleHudState?>(
      BattleHudController.new,
    );
