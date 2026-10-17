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
    this.nextWaveSeconds,
    this.earlyCallBonus = 0,
    this.speed = GameSpeed.normal,
  });

  factory of(Simulation simulation, {GameSpeed speed = GameSpeed.normal}) {
    final countdown = simulation.nextWaveCountdownTicks;
    return BattleHudState(
      corn: simulation.corn,
      potatoes: simulation.potatoes,
      // Antes de la primera oleada se muestra la 1 (la que viene).
      wave: simulation.startedWaves.clamp(1, simulation.totalWaves),
      totalWaves: simulation.totalWaves,
      status: simulation.status,
      nextWaveSeconds: countdown == null
          ? null
          : ticksToWholeSeconds(countdown),
      earlyCallBonus: simulation.earlyCallBonus,
      speed: speed,
    );
  }

  final int corn;
  final int potatoes;
  final int wave;
  final int totalWaves;
  final BattleStatus status;

  /// Segundos para la siguiente oleada, o `null` si no hay ninguna en
  /// cuenta regresiva (entonces no se puede llamar).
  final int? nextWaveSeconds;

  /// Maíz extra por llamar ya la siguiente oleada.
  final int earlyCallBonus;

  final GameSpeed speed;

  @override
  bool operator ==(Object other) =>
      other is BattleHudState &&
      other.corn == corn &&
      other.potatoes == potatoes &&
      other.wave == wave &&
      other.totalWaves == totalWaves &&
      other.status == status &&
      other.nextWaveSeconds == nextWaveSeconds &&
      other.earlyCallBonus == earlyCallBonus &&
      other.speed == speed;

  @override
  int get hashCode => Object.hash(
    corn,
    potatoes,
    wave,
    totalWaves,
    status,
    nextWaveSeconds,
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
