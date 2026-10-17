import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/status_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/sim_time.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:meta/meta.dart';

/// Lo que lleva un proyectil: su golpe, su velocidad, su área y sus
/// efectos. Lo define el ataque que lo lanza.
@immutable
class ProjectileShot {
  const new({
    required this.hit,
    required this.speed,
    this.splashRadius = 0,
    this.onHit = const [],
  });

  final Hit hit;

  /// Casillas por segundo.
  final double speed;

  /// 0 = solo golpea a su objetivo; más de 0 = golpea a todas las plagas
  /// atacables a esa distancia del punto de impacto.
  final double splashRadius;

  final List<StatusEffect> onHit;
}

/// Lo que las demás capas pueden leer de un proyectil.
abstract interface class ProjectileView {
  int get id;
  int get guardianId;
  Vec2 get position;

  /// Radio del área del impacto en casillas (0 = sin área).
  double get splashRadius;
}

/// Proyectil teledirigido: persigue a su objetivo y, si el objetivo muere
/// antes de que llegue, sigue hasta la última posición donde lo vio.
class Projectile implements ProjectileView {
  new({
    required this.id,
    required this.guardianId,
    required this.position,
    required this.target,
    required this.shot,
    required this.targets,
  }) : _aim = target.position;

  // Margen para que el último paso cuente como llegada aunque la suma de
  // decimales deje la distancia apenas por encima del paso.
  static const _arrivalEpsilon = 1e-9;

  @override
  final int id;

  @override
  final int guardianId;

  @override
  Vec2 position;

  final Pest target;
  final ProjectileShot shot;

  /// Etiquetas que puede golpear (las del guardián que lo lanzó).
  final Set<PestTag> targets;

  @override
  double get splashRadius => shot.splashRadius;

  /// Hacia dónde va: la posición actual del objetivo mientras vive.
  Vec2 _aim;

  /// Avanza un tick. Devuelve `true` si llegó a su destino (impacta en
  /// [position]).
  bool advance() {
    if (target.isAlive) _aim = target.position;
    final step = shot.speed / ticksPerSecond;
    final remaining = position.distanceTo(_aim);
    if (remaining <= step + _arrivalEpsilon) {
      position = _aim;
      return true;
    }
    position = position.lerp(_aim, step / remaining);
    return false;
  }
}
