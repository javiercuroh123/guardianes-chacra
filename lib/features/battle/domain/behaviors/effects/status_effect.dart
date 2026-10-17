import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';

/// Un efecto aplicado a una plaga y los ticks que le quedan.
class ActiveEffect {
  new(this.effect, this.remaining);

  final StatusEffect effect;
  int remaining;
}

/// Efecto de estado con duración (ralentizar, quemar, aturdir…).
///
/// Es inmutable: describe el efecto, y la duración que le queda a cada
/// plaga vive en su [ActiveEffect]. Una plaga tiene como máximo un efecto
/// de cada [type]; cuando llega otro del mismo tipo, [mergeInto] decide
/// qué queda (cada tipo define su propia regla de acumulación).
abstract class StatusEffect {
  const new();

  /// Nombre del tipo, el mismo del registro y de las inmunidades.
  String get type;

  int get durationTicks;

  /// Multiplicador de velocidad mientras dura (1 = normal, 0 = detenida).
  double get speedFactor => 1;

  /// Se llama en cada tick mientras dura (quemar hace su daño aquí).
  void onTick(Pest pest, BattleContext context) {}

  /// Este efecto llega a una plaga que ya tiene [current] del mismo tipo.
  /// Devuelve el efecto (y la duración) que debe quedar.
  ActiveEffect mergeInto(ActiveEffect current);
}
