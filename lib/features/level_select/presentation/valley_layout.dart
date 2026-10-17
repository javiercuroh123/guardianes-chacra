import 'dart:ui';

/// Dónde va cada nivel en el mapa del valle, como fracciones del área
/// (0 a 1): repartidos de izquierda a derecha y alternando arriba y abajo
/// del sendero. Un nivel nuevo en `index.json` encuentra su lugar solo.
List<Offset> valleyNodePositions(int count) => [
  for (var i = 0; i < count; i++)
    Offset(
      count == 1 ? 0.5 : 0.12 + 0.76 * i / (count - 1),
      i.isEven ? 0.68 : 0.42,
    ),
];
