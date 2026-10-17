import 'package:meta/meta.dart';

/// Qué hace falta para abrir un nivel o un guardián (`"unlock"` en su
/// JSON). Si hay varias condiciones, se piden todas; sin ninguna, está
/// abierto desde el principio.
@immutable
class UnlockRule {
  const new({this.afterLevel, this.totalStars = 0});

  /// Abierto desde el principio.
  static const always = UnlockRule();

  /// Hay que ganar este nivel (con al menos una estrella).
  final String? afterLevel;

  /// Estrellas que hay que juntar entre todos los niveles.
  final int totalStars;

  /// Si se cumple con [stars] (las mejores estrellas por id de nivel).
  bool isMetBy(Map<String, int> stars) {
    final level = afterLevel;
    if (level != null && (stars[level] ?? 0) == 0) return false;
    return stars.values.fold(0, (sum, value) => sum + value) >= totalStars;
  }

  @override
  bool operator ==(Object other) =>
      other is UnlockRule &&
      other.afterLevel == afterLevel &&
      other.totalStars == totalStars;

  @override
  int get hashCode => Object.hash(afterLevel, totalStars);

  @override
  String toString() =>
      'UnlockRule(afterLevel: $afterLevel, totalStars: $totalStars)';
}
