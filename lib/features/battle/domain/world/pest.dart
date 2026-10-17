import 'package:guardianes_chacra/core/math/vec2.dart';
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
}

/// Una plaga en juego. Solo la simulación la crea y la modifica.
class Pest implements PestView {
  new({
    required this.id,
    required this.def,
    required this.wave,
    required this._track,
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

  final PathTrack _track;

  @override
  double distance = 0;

  @override
  double health;

  @override
  Vec2 get position => _track.positionAt(distance);

  bool get reachedCollca => distance >= _track.length - _arrivalEpsilon;

  /// Avanza lo que le corresponde en un tick.
  void advance() => distance += def.speed / ticksPerSecond;
}
