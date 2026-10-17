import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';

void main() {
  test('distanceTo mide la distancia en línea recta', () {
    expect(const Vec2(1, 1).distanceTo(const Vec2(4, 5)), 5);
  });

  test('distanceSquaredTo es la distancia al cuadrado', () {
    expect(const Vec2(1, 1).distanceSquaredTo(const Vec2(4, 5)), 25);
  });

  test('lerp interpola entre dos puntos', () {
    const from = Vec2(2, 10);
    const to = Vec2(6, 2);

    expect(from.lerp(to, 0), const Vec2(2, 10));
    expect(from.lerp(to, 0.25), const Vec2(3, 8));
    expect(from.lerp(to, 1), const Vec2(6, 2));
  });

  test('dos vectores con las mismas coordenadas son iguales', () {
    // Construidos en tiempo de ejecución: dos `const` iguales serían el
    // mismo objeto y el test pasaría aunque faltara `==`.
    Vec2 build(double x, double y) => Vec2(x, y);

    expect(build(1.5, -2), build(1.5, -2));
    expect(build(1.5, -2).hashCode, build(1.5, -2).hashCode);
    expect(build(1.5, -2), isNot(build(-2, 1.5)));
  });
}
