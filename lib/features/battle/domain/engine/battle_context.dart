import 'package:guardianes_chacra/core/math/seeded_random.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/domain/world/guardian.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/battle/domain/world/projectile.dart';

/// Lo que un comportamiento (ataque, efecto o habilidad) puede pedirle a
/// la simulación. Es la única puerta hacia el motor: un comportamiento
/// nuevo se escribe contra esta interfaz sin conocer cómo está hecho.
abstract interface class BattleContext {
  int get tick;

  /// Azar con semilla: usar siempre este, nunca `Random()`.
  SeededRandom get random;

  /// Plagas vivas que [guardian] puede atacar: dentro de su alcance y con
  /// alguna de las etiquetas a las que ataca.
  List<Pest> targetsFor(Guardian guardian);

  /// Lanza un proyectil de [from] hacia [target].
  void launchProjectile({
    required Guardian from,
    required Pest target,
    required ProjectileShot shot,
  });

  /// Aplica [hit] a [pest] con su armadura y resistencias. Ignora a las
  /// plagas que ya no están vivas.
  void hit(Pest pest, Hit hit);

  /// Aplica [effect] a [pest] según la regla de acumulación del efecto
  /// (si la plaga no es inmune).
  void applyEffect(Pest pest, StatusEffect effect);

  /// Crea una plaga de tipo [pestId] en el camino de [from], a [distance]
  /// casillas del inicio, como parte de la misma oleada.
  void spawnPest(String pestId, {required Pest from, required double distance});

  void publish(SimEvent event);
}
