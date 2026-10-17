import 'package:meta/meta.dart';

/// Reglas generales de combate que no pertenecen a un guardián ni a una
/// plaga. Son valores de balance: en la Fase 4 vienen de un JSON.
@immutable
class BattleRules {
  const new({required this.sellRefundRate, required this.minDamageFraction});

  /// Fracción del maíz gastado en un guardián que se devuelve al venderlo.
  final double sellRefundRate;

  /// Fracción mínima del daño físico que siempre atraviesa la armadura.
  final double minDamageFraction;
}
