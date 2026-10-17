import 'package:flutter/painting.dart';

/// El color de un guardián o plaga: el de sus datos (`"color"` en su JSON)
/// o, si no tiene, uno derivado de su id.
Color colorFor(String id, int? color) =>
    color != null ? Color(color) : colorForId(id);

/// Color de reemplazo para un tipo de plaga o guardián, derivado de su id:
/// una plaga nueva en los JSON se dibuja sin tocar código. En la Fase 8 los
/// sprites vienen de los datos y esto queda solo para lo que no tenga
/// imagen.
///
/// Se usa un hash propio (FNV-1a de 32 bits) porque `String.hashCode` no
/// garantiza el mismo valor entre ejecuciones ni entre plataformas. Brillo
/// y saturación fijos y bajos: así el texto blanco encima siempre se lee.
Color colorForId(String id) {
  var hash = 0x811C9DC5;
  for (final unit in id.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  final hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1, hue, 0.6, 0.55).toColor();
}
