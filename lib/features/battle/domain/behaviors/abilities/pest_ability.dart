import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';

/// Habilidad especial de una plaga (dividirse al morir, invocar…). Cada
/// plaga recibe sus propias instancias, así que pueden guardar estado.
abstract class PestAbility {
  /// Tipos de plaga que esta habilidad puede crear. La simulación los
  /// comprueba al empezar para no fallar a mitad de partida.
  Iterable<String> get spawnsPests => const [];

  /// Se llama en cada tick mientras la plaga está viva.
  void onTick(Pest pest, BattleContext context) {}

  /// Se llama cuando la derrotan (no cuando llega a la collca).
  void onDeath(Pest pest, BattleContext context) {}
}
