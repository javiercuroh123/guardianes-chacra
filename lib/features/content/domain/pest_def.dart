import 'package:guardianes_chacra/features/content/domain/behavior_spec.dart';
import 'package:meta/meta.dart';

/// Tipos de daño. Cada plaga puede resistirlos o ser débil a ellos.
enum DamageType { physical, fire }

/// Etiquetas de una plaga. Los guardianes las usan para decidir a quién
/// pueden atacar (por ejemplo, la Tullpa solo ataca plagas de tierra).
enum PestTag { ground, flying }

/// Definición de un tipo de plaga, tal como viene de los datos.
///
/// Las distancias y velocidades van en casillas del mapa, no en píxeles:
/// así el balance no cambia si cambia el tamaño del arte.
@immutable
class PestDef {
  const new({
    required this.id,
    required this.maxHealth,
    required this.speed,
    required this.cornReward,
    required this.potatoDamage,
    required this.tags,
    this.armor = 0,
    this.resistances = const {},
    this.immunities = const {},
    this.abilities = const [],
  });

  final String id;
  final double maxHealth;

  /// Casillas por segundo.
  final double speed;

  /// Armadura física: se resta del daño físico (ver `damageDealt`).
  final double armor;

  /// Multiplicador de daño por tipo (0.5 = resiste la mitad, 2 = débil).
  /// Un tipo que no aparece aquí hace daño normal (1).
  final Map<DamageType, double> resistances;

  /// Maíz que gana el jugador al derrotarla.
  final int cornReward;

  /// Papas que se come si llega a la collca.
  final int potatoDamage;

  final Set<PestTag> tags;

  /// Tipos de efecto que no le afectan (por ejemplo, `{'slow'}`).
  final Set<String> immunities;

  /// Habilidades especiales (dividirse al morir, invocar…).
  final List<BehaviorSpec> abilities;
}
