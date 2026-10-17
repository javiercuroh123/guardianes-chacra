import 'package:meta/meta.dart';

/// La imagen de una plaga o un guardián (`"sprite"` en su JSON): una tira
/// horizontal de [frames] cuadros del mismo ancho, en `assets/images/`.
/// Con un solo cuadro es una imagen fija.
///
/// Si falta o no se puede cargar, se dibuja la forma de siempre.
@immutable
class SpriteDef {
  const new({required this.image, this.frames = 1, this.fps = 8});

  /// Ruta relativa a `assets/images/` (por ejemplo, `pests/gorgojo.png`).
  final String image;
  final int frames;

  /// Cuadros por segundo de la animación.
  final double fps;

  @override
  bool operator ==(Object other) =>
      other is SpriteDef &&
      other.image == image &&
      other.frames == frames &&
      other.fps == fps;

  @override
  int get hashCode => Object.hash(image, frames, fps);

  @override
  String toString() => 'SpriteDef($image, frames: $frames, fps: $fps)';
}
