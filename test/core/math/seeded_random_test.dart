import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/seeded_random.dart';

void main() {
  test('reproduce la secuencia de referencia de Mulberry32', () {
    // Valores calculados con la implementación canónica en JavaScript
    // (Math.imul). Si este test pasa en la VM y en la web
    // (`flutter test --platform chrome`), las dos plataformas coinciden.
    const reference = {
      42: [2581720956, 1925393290, 3661312704, 2876485805, 750819978],
      0: [1144304738, 1416247, 958946056, 627933444, 2007157716],
      2026: [1955961175, 1324980858, 2839649622, 2656330836, 654038057],
    };

    for (final MapEntry(key: seed, value: expected) in reference.entries) {
      final random = SeededRandom(seed);
      final actual = [for (var i = 0; i < 5; i++) random.nextUint32()];
      expect(actual, expected, reason: 'semilla $seed');
    }
  });

  test('la misma semilla da la misma secuencia', () {
    final a = SeededRandom(7);
    final b = SeededRandom(7);

    final fromA = [for (var i = 0; i < 100; i++) a.nextDouble()];
    final fromB = [for (var i = 0; i < 100; i++) b.nextDouble()];

    expect(fromA, fromB);
  });

  test('nextDouble devuelve valores en [0, 1)', () {
    final random = SeededRandom(42);

    // 2581720956 / 2^32, el primer valor de la semilla 42.
    expect(random.nextDouble(), closeTo(0.601104, 1e-6));
    for (var i = 0; i < 1000; i++) {
      expect(random.nextDouble(), allOf(greaterThanOrEqualTo(0), lessThan(1)));
    }
  });

  test('nextInt(max) devuelve enteros en [0, max)', () {
    final random = SeededRandom(3);
    final seen = <int>{};

    for (var i = 0; i < 1000; i++) {
      final value = random.nextInt(6);
      expect(value, inInclusiveRange(0, 5));
      seen.add(value);
    }

    expect(seen, {0, 1, 2, 3, 4, 5});
  });

  test('nextInt rechaza un máximo que no es positivo', () {
    expect(() => SeededRandom(1).nextInt(0), throwsArgumentError);
  });
}
