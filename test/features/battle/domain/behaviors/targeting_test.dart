import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/targeting/targeting_strategies.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

final _track = PathTrack(const [Vec2(0, 0), Vec2(10, 0)]);

Pest _pest(int id, {required double distance, double health = 10}) => Pest(
  id: id,
  def: const PestDef(
    id: 'prueba',
    maxHealth: 100,
    speed: 1,
    cornReward: 1,
    potatoDamage: 1,
    tags: {PestTag.ground},
  ),
  wave: 0,
  pathId: 'recto',
  track: _track,
  distance: distance,
)..health = health;

void main() {
  // Cuatro plagas en el camino recto (su posición es (distancia, 0)).
  final behind = _pest(1, distance: 1);
  final strong = _pest(2, distance: 4, health: 30);
  final near = _pest(3, distance: 6);
  final ahead = _pest(4, distance: 9);
  final candidates = [behind, strong, near, ahead];

  // El guardián está en (5,5; 1): la más cercana es la de distancia 6.
  const origin = Vec2(5.5, 1);

  test('primera: la que más avanzó', () {
    expect(const FirstTargeting().choose(candidates, origin), ahead);
  });

  test('última: la que menos avanzó', () {
    expect(const LastTargeting().choose(candidates, origin), behind);
  });

  test('más fuerte: la que tiene más vida', () {
    expect(const StrongestTargeting().choose(candidates, origin), strong);
  });

  test('más cercana: la más próxima al guardián', () {
    expect(const ClosestTargeting().choose(candidates, origin), near);
  });

  test('sin candidatas no elige a nadie', () {
    expect(const FirstTargeting().choose(const [], origin), isNull);
  });

  test('en un empate gana la que apareció antes (menor id)', () {
    final later = _pest(8, distance: 5);
    final earlier = _pest(7, distance: 5);

    expect(const FirstTargeting().choose([later, earlier], origin), earlier);
    expect(const LastTargeting().choose([later, earlier], origin), earlier);
  });

  test('más fuerte desempata por la que va primera', () {
    final first = _pest(5, distance: 8, health: 30);

    expect(
      const StrongestTargeting().choose([strong, first], origin),
      first,
    );
  });
}
