import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';

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

/// Lo que mide el artboard `Valley` de Rive.
const valleyArtboardSize = Size(960, 432);

/// El lugar de cada nivel en el dibujo del valle (coordenadas del
/// artboard, el centro del círculo): la chacra junto a las casitas, los
/// andenes a la derecha de la collca y la orilla sobre la totora del lago.
const valleyAnchors = <String, Offset>{
  'chacra_del_valle': Offset(190, 220),
  'andenes': Offset(575, 212),
  'orilla_del_lago': Offset(855, 218),
};

/// El lugar en el dibujo de cada uno de [levelIds]: el de [valleyAnchors]
/// o, para un nivel que el dibujo no conoce, el reparto de
/// [valleyNodePositions].
List<Offset> valleyAnchorsFor(List<String> levelIds) {
  final spread = valleyNodePositions(levelIds.length);
  return [
    for (final (index, id) in levelIds.indexed)
      valleyAnchors[id] ??
          Offset(
            spread[index].dx * valleyArtboardSize.width,
            spread[index].dy * valleyArtboardSize.height,
          ),
  ];
}

/// El valle puesto en una pantalla: con qué escala se dibuja y dónde cae
/// cada punto del artboard.
///
/// En pantallas de 2:1 o más anchas (los teléfonos apaisados) lo cubre todo,
/// centrado, como en el título. En las más angostas (tabletas) se ajusta al
/// ancho y se apoya abajo, con cielo arriba: cubriendo, se cortarían los
/// niveles de los costados.
@immutable
class ValleyFrame {
  const new({required this.scale, required this.offset, required this.cover});

  factory of(Size screen) {
    const art = valleyArtboardSize;
    final cover = screen.width / screen.height >= 2;
    if (cover) {
      final scale = math.max(
        screen.width / art.width,
        screen.height / art.height,
      );
      return ValleyFrame(
        scale: scale,
        offset: Offset(
          (screen.width - art.width * scale) / 2,
          (screen.height - art.height * scale) / 2,
        ),
        cover: true,
      );
    }
    final scale = screen.width / art.width;
    return ValleyFrame(
      scale: scale,
      offset: Offset(0, screen.height - art.height * scale),
      cover: false,
    );
  }

  final double scale;

  /// Dónde cae la esquina de arriba a la izquierda del artboard.
  final Offset offset;

  /// Si cubre la pantalla (si no, se ajusta al ancho y se apoya abajo).
  final bool cover;

  Offset toScreen(Offset art) => offset + art * scale;
}
