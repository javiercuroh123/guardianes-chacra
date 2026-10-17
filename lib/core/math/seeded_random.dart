/// Generador pseudoaleatorio con semilla (algoritmo Mulberry32).
///
/// Usamos uno propio en lugar de `Random(semilla)` de Dart porque este no
/// garantiza la misma secuencia en la VM (Android) y en la web. Aquí toda
/// la aritmética cabe en 32 bits sin signo, así que la misma semilla da los
/// mismos números en cualquier plataforma.
class SeededRandom {
  new(int seed) : _state = seed & _mask32;

  static const _mask32 = 0xFFFFFFFF;
  static const _twoPow32 = 4294967296.0;

  int _state;

  /// Entero en [0, 2^32).
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask32;
    var t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t ^= (t + _imul(t ^ (t >> 7), t | 61)) & _mask32;
    return (t ^ (t >> 14)) & _mask32;
  }

  /// Decimal en [0, 1).
  double nextDouble() => nextUint32() / _twoPow32;

  /// Entero en [0, [max]).
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'debe ser positivo');
    }
    return (nextDouble() * max).floor();
  }

  /// Multiplicación de 32 bits (como `Math.imul` de JavaScript). Se hace por
  /// mitades de 16 bits porque en la web los enteros son `double` y un
  /// producto de 64 bits perdería precisión.
  static int _imul(int a, int b) {
    final aHigh = (a >> 16) & 0xFFFF;
    final aLow = a & 0xFFFF;
    final bHigh = (b >> 16) & 0xFFFF;
    final bLow = b & 0xFFFF;
    final cross = ((aHigh * bLow + aLow * bHigh) & 0xFFFF) << 16;
    return (aLow * bLow + cross) & _mask32;
  }
}
