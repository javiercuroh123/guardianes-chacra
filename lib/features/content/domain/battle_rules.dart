import 'package:meta/meta.dart';

/// Reglas generales de combate que no pertenecen a un guardián ni a una
/// plaga. Son valores de balance: vienen de `assets/content/rules.json`.
@immutable
class BattleRules {
  const new({
    required this.sellRefundRate,
    required this.minDamageFraction,
    required this.twoStarsFraction,
    required this.threeStarsFraction,
  });

  /// Fracción del maíz gastado en un guardián que se devuelve al venderlo.
  final double sellRefundRate;

  /// Fracción mínima del daño físico que siempre atraviesa la armadura.
  final double minDamageFraction;

  /// Fracción de las papas iniciales que hay que salvar para ganar con dos
  /// estrellas (ganar con menos da una).
  final double twoStarsFraction;

  /// Fracción de las papas iniciales que hay que salvar para tres estrellas.
  final double threeStarsFraction;
}
