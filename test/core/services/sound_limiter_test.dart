import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/services/sound_limiter.dart';

void main() {
  var now = Duration.zero;
  late SoundLimiter<String> limiter;

  setUp(() {
    now = Duration.zero;
    limiter = SoundLimiter(
      now: () => now,
      // minInterval y window, los de siempre: 70 y 250 ms.
      maxPerWindow: 3,
    );
  });

  test('el mismo sonido no se repite antes del intervalo', () {
    expect(limiter.tryPlay('disparo'), isTrue);
    now = const Duration(milliseconds: 69);
    expect(limiter.tryPlay('disparo'), isFalse);
    now = const Duration(milliseconds: 70);
    expect(limiter.tryPlay('disparo'), isTrue);
  });

  test('un rechazo no cuenta como sonido', () {
    expect(limiter.tryPlay('disparo'), isTrue);
    now = const Duration(milliseconds: 50);
    expect(limiter.tryPlay('disparo'), isFalse);
    // 70 ms desde el que sí sonó, no desde el rechazado.
    now = const Duration(milliseconds: 70);
    expect(limiter.tryPlay('disparo'), isTrue);
  });

  test('entre todos, como mucho 3 por ventana', () {
    expect(limiter.tryPlay('a'), isTrue);
    now = const Duration(milliseconds: 100);
    expect(limiter.tryPlay('b'), isTrue);
    now = const Duration(milliseconds: 200);
    expect(limiter.tryPlay('c'), isTrue);
    expect(limiter.tryPlay('d'), isFalse);

    // A los 250 ms sale "a" de la ventana: entra uno más, no dos.
    now = const Duration(milliseconds: 250);
    expect(limiter.tryPlay('d'), isTrue);
    expect(limiter.tryPlay('e'), isFalse);
  });
}
