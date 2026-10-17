import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';

void main() {
  // Camino en L: 4 casillas a la derecha y 3 hacia abajo (7 en total).
  final lPath = PathTrack(const [Vec2(0, 0), Vec2(4, 0), Vec2(4, 3)]);

  test('la longitud es la suma de sus tramos', () {
    expect(lPath.length, 7);
  });

  test('positionAt interpola sobre el tramo correcto', () {
    expect(lPath.positionAt(0), const Vec2(0, 0));
    expect(lPath.positionAt(2), const Vec2(2, 0));
    expect(lPath.positionAt(4), const Vec2(4, 0));
    expect(lPath.positionAt(5.5), const Vec2(4, 1.5));
    expect(lPath.positionAt(7), const Vec2(4, 3));
  });

  test('positionAt se queda en los extremos fuera del camino', () {
    expect(lPath.positionAt(-1), const Vec2(0, 0));
    expect(lPath.positionAt(100), const Vec2(4, 3));
  });

  test('encuentra el tramo en caminos con varias curvas', () {
    // Zigzag de 4 tramos de 2 casillas.
    final zigzag = PathTrack(const [
      Vec2(0, 0),
      Vec2(2, 0),
      Vec2(2, 2),
      Vec2(0, 2),
      Vec2(0, 4),
    ]);

    expect(zigzag.length, 8);
    expect(zigzag.positionAt(1), const Vec2(1, 0));
    expect(zigzag.positionAt(3), const Vec2(2, 1));
    expect(zigzag.positionAt(5), const Vec2(1, 2));
    expect(zigzag.positionAt(7.5), const Vec2(0, 3.5));
  });

  test('tolera puntos repetidos (tramos de longitud cero)', () {
    final track = PathTrack(const [Vec2(0, 0), Vec2(0, 0), Vec2(3, 0)]);

    expect(track.length, 3);
    expect(track.positionAt(0), const Vec2(0, 0));
    expect(track.positionAt(1.5), const Vec2(1.5, 0));
  });

  test('un camino necesita al menos dos puntos', () {
    expect(() => PathTrack(const [Vec2(1, 1)]), throwsArgumentError);
  });
}
