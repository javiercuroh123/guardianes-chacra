import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// Lo que la partida lee de los archivos: el mapa de Tiled y las imágenes
/// de los sprites.
///
/// Los tests usan una versión con todo ya cargado (ver
/// `test/helpers/battle_game_helpers.dart`): decodificar imágenes no
/// funciona con el reloj falso de los tests.
class BattleAssets {
  const new();

  /// El mapa de Tiled del nivel. El tileset (.tsx y .png) está junto al
  /// mapa en `assets/tiles/`, igual que en Tiled; por defecto Flame buscaría
  /// la imagen en `assets/images/`.
  Future<Component> loadMap(LevelDef level) => TiledComponent.load(
    level.mapFile,
    Vector2.all(BattleGame.tileSize),
    images: Images(prefix: 'assets/tiles/'),
  );

  /// Las imágenes que se pudieron cargar, por ruta (relativa a
  /// `assets/images/`). Una que falta o no se puede leer no está: su plaga
  /// o guardián se dibuja con la forma de siempre.
  Future<Map<String, Image>> loadImages(Iterable<String> paths) async {
    final images = Images();
    final loaded = <String, Image>{};
    for (final path in paths) {
      try {
        loaded[path] = await images.load(path);
      } on Object catch (error) {
        debugPrint('Sprite: no se pudo cargar $path ($error)');
      }
    }
    return loaded;
  }
}
