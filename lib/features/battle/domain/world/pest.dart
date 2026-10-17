import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/abilities/pest_ability.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/battle_context.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Lo que las demás capas pueden leer de una plaga. La simulación entrega
/// esta vista (sin métodos que modifiquen) para que Flame solo dibuje.
abstract interface class PestView {
  int get id;
  PestDef get def;

  /// Casillas recorridas desde el inicio de su camino.
  double get distance;
  double get health;
  Vec2 get position;

  /// Tipos de efecto activos ("slow", "burn"…), para dibujarlos.
  Iterable<String> get activeEffects;
}

/// Una plaga en juego. Solo la simulación y los comportamientos la
/// modifican.
class Pest implements PestView {
  new({
    required this.id,
    required this.def,
    required this.wave,
    required this.pathId,
    required this.track,
    this.abilities = const [],
    this.distance = 0,
  }) : health = def.maxHealth;

  // Margen para dar por llegada una plaga cuya suma de pasos quedó en
  // 9,9999999 casillas en lugar de 10 por el redondeo de los decimales.
  static const _arrivalEpsilon = 1e-9;

  @override
  final int id;

  @override
  final PestDef def;

  /// Índice de la oleada a la que pertenece.
  final int wave;

  final String pathId;
  final PathTrack track;
  final List<PestAbility> abilities;

  @override
  double distance;

  @override
  double health;

  /// Ya salió del juego (llegó a la collca o fue derrotada y retirada).
  bool removed = false;

  bool get isAlive => !removed && health > 0;

  @override
  Vec2 get position => track.positionAt(distance);

  bool get reachedCollca => distance >= track.length - _arrivalEpsilon;

  /// Un efecto por tipo. El mapa conserva el orden de inserción, así que
  /// recorrerlo da siempre el mismo orden (importa para el determinismo).
  final Map<String, ActiveEffect> _effects = {};

  @override
  Iterable<String> get activeEffects => _effects.keys;

  /// Producto de los multiplicadores de velocidad de sus efectos. Como hay
  /// uno por tipo, dos ralentizaciones nunca se multiplican entre sí.
  double get speedFactor {
    var factor = 1.0;
    for (final active in _effects.values) {
      factor *= active.effect.speedFactor;
    }
    return factor;
  }

  ActiveEffect? effect(String type) => _effects[type];

  /// Aplica [effect] con su regla de acumulación. Devuelve `false` si la
  /// plaga es inmune.
  bool applyEffect(StatusEffect effect) {
    if (def.immunities.contains(effect.type)) return false;
    final current = _effects[effect.type];
    _effects[effect.type] = current == null
        ? ActiveEffect(effect, effect.durationTicks)
        : effect.mergeInto(current);
    return true;
  }

  /// Llama a `onTick` de cada efecto activo.
  void tickEffects(BattleContext context) {
    for (final active in _effects.values.toList()) {
      active.effect.onTick(this, context);
    }
  }

  /// Descuenta un tick a cada efecto y quita los que terminaron.
  void expireEffects() {
    for (final active in _effects.values) {
      active.remaining--;
    }
    _effects.removeWhere((_, active) => active.remaining <= 0);
  }

  /// Avanza lo que le corresponde en un tick, según sus efectos.
  void advance() => distance += def.speed * speedFactor / ticksPerSecond;
}
