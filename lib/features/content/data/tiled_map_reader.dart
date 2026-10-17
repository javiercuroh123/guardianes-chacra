import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:tiled/tiled.dart';

/// Capas de objetos que debe tener todo mapa (ver `docs/TILED.md`).
const pathsLayerName = 'caminos';
const slotsLayerName = 'espacios';
const collcaLayerName = 'collca';

/// Distancia máxima (en casillas) entre el final de un camino y la collca.
const _maxDistanceToCollca = 0.75;

/// Lee de un mapa de Tiled lo que necesita la simulación, en casillas:
/// los caminos (polilíneas con nombre), los espacios de construcción
/// (puntos) y la collca (un punto). Las capas de casillas solo se dibujan,
/// así que aquí se ignoran.
///
/// Es Dart puro (paquete `tiled`): funciona en la app, en los tests y en
/// las herramientas de línea de comandos.
MapDef readTiledMap(String tmx, {required String file}) {
  ContentError error(String detail) => ContentError('$file: $detail');

  final TiledMap map;
  try {
    map = TileMapParser.parseTmx(tmx);
    // El paquete lanza errores de distintos tipos (incluso textos) cuando el
    // XML no es un mapa; todos significan lo mismo para quien edita el mapa.
  } catch (cause) {
    throw error('no es un mapa de Tiled válido ($cause)');
  }

  if (map.tileWidth != map.tileHeight) {
    throw error(
      'las casillas deben ser cuadradas '
      '(son ${map.tileWidth}×${map.tileHeight} px)',
    );
  }
  final tileSize = map.tileWidth.toDouble();
  Vec2 toTiles(double x, double y) => Vec2(x / tileSize, y / tileSize);

  List<TiledObject> objectsOf(String layerName) {
    final layer = map.layers
        .whereType<ObjectGroup>()
        .where((layer) => layer.name == layerName)
        .firstOrNull;
    if (layer == null) throw error('falta la capa de objetos "$layerName"');
    return layer.objects;
  }

  final paths = <PathDef>[];
  for (final object in objectsOf(pathsLayerName)) {
    if (!object.isPolyline) {
      throw error(
        'el objeto ${object.id} de la capa "$pathsLayerName" no es una '
        'polilínea',
      );
    }
    if (object.name.isEmpty) {
      throw error(
        'el camino del objeto ${object.id} no tiene nombre '
        '(el nombre es su id)',
      );
    }
    if (paths.any((path) => path.id == object.name)) {
      throw error('hay dos caminos llamados "${object.name}"');
    }
    if (object.polyline.length < 2) {
      throw error('el camino "${object.name}" necesita al menos 2 puntos');
    }
    paths.add(
      PathDef(
        id: object.name,
        points: [
          for (final point in object.polyline)
            toTiles(object.x + point.x, object.y + point.y),
        ],
      ),
    );
  }
  if (paths.isEmpty) {
    throw error('la capa "$pathsLayerName" no tiene ningún camino');
  }

  final collcaObjects = objectsOf(collcaLayerName);
  if (collcaObjects.length != 1 || !collcaObjects.single.isPoint) {
    throw error('la capa "$collcaLayerName" debe tener exactamente un punto');
  }
  final collca = toTiles(collcaObjects.single.x, collcaObjects.single.y);
  for (final path in paths) {
    final end = path.points.last;
    if (end.distanceTo(collca) > _maxDistanceToCollca) {
      throw error(
        'el camino "${path.id}" termina en ${_format(end)}, lejos de la '
        'collca ${_format(collca)}',
      );
    }
  }

  final slots = <BuildSlotDef>[];
  for (final object in objectsOf(slotsLayerName)) {
    if (!object.isPoint) {
      throw error(
        'el objeto ${object.id} de la capa "$slotsLayerName" no es un punto',
      );
    }
    final id = object.name.isEmpty ? 'espacio_${object.id}' : object.name;
    if (slots.any((slot) => slot.id == id)) {
      throw error('hay dos espacios llamados "$id"');
    }
    slots.add(BuildSlotDef(id: id, position: toTiles(object.x, object.y)));
  }
  if (slots.isEmpty) {
    throw error('la capa "$slotsLayerName" no tiene ningún espacio');
  }

  return MapDef(
    width: map.width,
    height: map.height,
    collca: collca,
    paths: paths,
    buildSlots: slots,
  );
}

String _format(Vec2 point) =>
    '(${point.x.toStringAsFixed(1)}, ${point.y.toStringAsFixed(1)})';
