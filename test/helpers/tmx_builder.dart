/// Mapas de Tiled pequeños para los tests: 10×6 casillas de 64 px.
///
/// El camino "norte" va de (0; 1,5) a (5; 1,5), baja a (5; 4,5) y llega a
/// la collca en (9; 4,5). Hay un espacio "e1" en (3,5; 3,5) y otro sin
/// nombre (objeto 3) en (7,5; 2,5).
const defaultPathsXml =
    '<object id="1" name="norte" x="0" y="96"> '
    '<polyline points="0,0 320,0 320,192 576,192"/></object>';

const defaultSlotsXml =
    '<object id="2" name="e1" x="224" y="224"><point/></object> '
    '<object id="3" x="480" y="160"><point/></object>';

const defaultCollcaXml =
    '<object id="4" name="collca" x="576" y="288"><point/></object>';

String buildTmx({
  String paths = defaultPathsXml,
  String slots = defaultSlotsXml,
  String collca = defaultCollcaXml,
  int tileWidth = 64,
  int tileHeight = 64,
  Set<String> omitLayers = const {},
}) {
  String layer(int id, String name, String objects) => omitLayers.contains(name)
      ? ''
      : '<objectgroup id="$id" name="$name">$objects</objectgroup>';

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.12.2" orientation="orthogonal" renderorder="right-down" width="10" height="6" tilewidth="$tileWidth" tileheight="$tileHeight" infinite="0" nextlayerid="5" nextobjectid="5">
 <layer id="1" name="terreno" width="10" height="6">
  <data encoding="csv">${List.filled(60, '0').join(',')}</data>
 </layer>
 ${layer(2, 'caminos', paths)}
 ${layer(3, 'espacios', slots)}
 ${layer(4, 'collca', collca)}
</map>
''';
}
