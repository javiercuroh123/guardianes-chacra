import 'dart:ui';

/// Colores fijos de la partida (los de cada plaga o guardián salen de
/// `colorForId`). Provisionales hasta el arte de la Fase 8.
abstract final class BattleColors {
  static const letterbox = Color(0xFF2E4F2A);
  static const outline = Color(0xCC1B1B1B);
  static const healthBack = Color(0xAA000000);
  static const health = Color(0xFF6BD36B);
  static const slow = Color(0xFF7FDBFF);
  static const burn = Color(0xFFFF8C1A);
  static const stun = Color(0xFFFFE066);
  static const projectile = Color(0xFFF5F0E6);
  static const impact = Color(0xFFFFF3C4);
  static const rangeFill = Color(0x26FFFFFF);
  static const rangeStroke = Color(0x99FFFFFF);
  static const selection = Color(0xFFFFFFFF);
}
