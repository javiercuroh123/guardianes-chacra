import 'dart:math' as math;
import 'dart:ui';

import 'package:meta/meta.dart';

/// Cómo se ve el mapa en pantalla: la escala para que entre completo
/// (respetando sus proporciones) y dónde queda su esquina superior
/// izquierda para que quede centrado.
///
/// La cámara de Flame usa [zoom] centrada en el mapa, y los menús de
/// Flutter usan [toScreen] para ubicarse sobre un espacio o un guardián.
@immutable
class MapFit {
  const new _({required this.zoom, required this.origin});

  factory compute({required Size map, required Size viewport}) {
    final zoom = math.min(
      viewport.width / map.width,
      viewport.height / map.height,
    );
    final drawn = map * zoom;
    return MapFit._(
      zoom: zoom,
      origin: Offset(
        (viewport.width - drawn.width) / 2,
        (viewport.height - drawn.height) / 2,
      ),
    );
  }

  final double zoom;

  /// Posición en pantalla de la esquina (0, 0) del mapa.
  final Offset origin;

  /// Un punto del mapa (en píxeles del mapa) en coordenadas de pantalla.
  Offset toScreen(Offset world) => origin + world * zoom;
}
