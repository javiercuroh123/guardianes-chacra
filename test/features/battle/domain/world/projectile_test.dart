import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/damage.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/battle/domain/world/projectile.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

Pest _pest({required double speed, required List<Vec2> path}) => Pest(
  id: 1,
  def: PestDef(
    id: 'prueba',
    maxHealth: 10,
    speed: speed,
    cornReward: 1,
    potatoDamage: 1,
    tags: const {PestTag.ground},
  ),
  wave: 0,
  pathId: 'camino',
  track: PathTrack(path),
);

Projectile _projectile(
  Pest target, {
  required Vec2 from,
  required double speed,
}) => Projectile(
  id: 1,
  guardianId: 1,
  position: from,
  target: target,
  shot: ProjectileShot(
    hit: const Hit(amount: 1, type: DamageType.physical),
    speed: speed,
  ),
  targets: const {PestTag.ground},
);

void main() {
  test('llega a un objetivo quieto en el tiempo que da su velocidad', () {
    // De (3, 4) a (0, 0) hay 5 casillas; a 10 casillas/s avanza 1/3 por
    // tick: llega en el tick 15.
    final target = _pest(speed: 0, path: const [Vec2(0, 0), Vec2(0, 10)]);
    final projectile = _projectile(target, from: const Vec2(3, 4), speed: 10);

    for (var tick = 1; tick < 15; tick++) {
      expect(projectile.advance(), isFalse, reason: 'tick $tick');
    }
    expect(projectile.advance(), isTrue);
    expect(projectile.position, const Vec2(0, 0));
  });

  test('persigue a un objetivo que se mueve', () {
    final target = _pest(speed: 3, path: const [Vec2(0, 0), Vec2(10, 0)]);
    final projectile = _projectile(target, from: const Vec2(0, 5), speed: 15);

    var arrived = false;
    for (var tick = 0; tick < 100 && !arrived; tick++) {
      target.advance();
      arrived = projectile.advance();
    }

    expect(arrived, isTrue);
    expect(projectile.position.x, closeTo(target.position.x, 1e-9));
    expect(projectile.position.y, closeTo(0, 1e-9));
  });

  test('si el objetivo muere antes, impacta en su última posición', () {
    final target = _pest(speed: 3, path: const [Vec2(0, 0), Vec2(10, 0)]);
    final projectile = _projectile(target, from: const Vec2(0, 5), speed: 15);

    // Tres ticks persiguiéndolo: la plaga queda en (0,3; 0) y muere.
    for (var tick = 0; tick < 3; tick++) {
      target.advance();
      expect(projectile.advance(), isFalse);
    }
    target.health = 0;

    var arrived = false;
    for (var tick = 0; tick < 100 && !arrived; tick++) {
      arrived = projectile.advance();
    }

    expect(arrived, isTrue);
    expect(projectile.position.x, closeTo(0.3, 1e-9));
    expect(projectile.position.y, closeTo(0, 1e-9));
  });
}
