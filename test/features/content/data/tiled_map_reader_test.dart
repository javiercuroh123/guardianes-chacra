import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';
import 'package:guardianes_chacra/features/content/data/tiled_map_reader.dart';

import '../../../helpers/tmx_builder.dart';

void main() {
  const file = 'tiles/prueba.tmx';

  String errorOf(String tmx) {
    try {
      readTiledMap(tmx, file: file);
    } on ContentError catch (error) {
      return error.message;
    }
    fail('No lanzó ContentError');
  }

  test('convierte el mapa a casillas', () {
    final map = readTiledMap(buildTmx(), file: file);

    expect(map.width, 10);
    expect(map.height, 6);
    expect(map.paths.single.id, 'norte');
    expect(map.paths.single.points, const [
      Vec2(0, 1.5),
      Vec2(5, 1.5),
      Vec2(5, 4.5),
      Vec2(9, 4.5),
    ]);
    expect(map.collca, const Vec2(9, 4.5));
    expect(map.buildSlots.map((slot) => (slot.id, slot.position)), const [
      ('e1', Vec2(3.5, 3.5)),
      ('espacio_3', Vec2(7.5, 2.5)),
    ]);
  });

  test('los puntos de la polilínea son relativos a su objeto', () {
    // El mismo camino, pero con el objeto en (64, 96) y los puntos
    // corridos una casilla a la izquierda.
    final map = readTiledMap(
      buildTmx(
        paths:
            '<object id="1" name="norte" x="64" y="96"> '
            '<polyline points="-64,0 256,0 256,192 512,192"/></object>',
      ),
      file: file,
    );

    expect(map.paths.single.points.first, const Vec2(0, 1.5));
    expect(map.paths.single.points.last, const Vec2(9, 4.5));
  });

  group('errores', () {
    final cases = <(String, String, String)>[
      (
        'falta una capa',
        buildTmx(omitLayers: {'espacios'}),
        'tiles/prueba.tmx: falta la capa de objetos "espacios"',
      ),
      (
        'camino sin nombre',
        buildTmx(
          paths:
              '<object id="1" x="0" y="96"> '
              '<polyline points="0,0 576,192"/></object>',
        ),
        'tiles/prueba.tmx: el camino del objeto 1 no tiene nombre '
            '(el nombre es su id)',
      ),
      (
        'un objeto que no es polilínea en "caminos"',
        buildTmx(
          paths: '<object id="1" name="norte" x="0" y="96"><point/></object>',
        ),
        'tiles/prueba.tmx: el objeto 1 de la capa "caminos" no es una '
            'polilínea',
      ),
      (
        'dos caminos con el mismo nombre',
        buildTmx(paths: defaultPathsXml + defaultPathsXml),
        'tiles/prueba.tmx: hay dos caminos llamados "norte"',
      ),
      (
        'un camino que no llega a la collca',
        buildTmx(
          paths:
              '<object id="1" name="norte" x="0" y="96"> '
              '<polyline points="0,0 320,0"/></object>',
        ),
        'tiles/prueba.tmx: el camino "norte" termina en (5.0, 1.5), lejos '
            'de la collca (9.0, 4.5)',
      ),
      (
        'una collca con dos puntos',
        buildTmx(collca: defaultCollcaXml + defaultCollcaXml),
        'tiles/prueba.tmx: la capa "collca" debe tener exactamente un punto',
      ),
      (
        'dos espacios con el mismo nombre',
        buildTmx(
          slots:
              '<object id="2" name="e1" x="224" y="224"><point/></object> '
              '<object id="3" name="e1" x="480" y="160"><point/></object>',
        ),
        'tiles/prueba.tmx: hay dos espacios llamados "e1"',
      ),
      (
        'un espacio que no es un punto',
        buildTmx(
          slots:
              '<object id="2" name="e1" x="224" y="224" width="64" '
              'height="64"/>',
        ),
        'tiles/prueba.tmx: el objeto 2 de la capa "espacios" no es un punto',
      ),
      (
        'sin espacios',
        buildTmx(slots: ''),
        'tiles/prueba.tmx: la capa "espacios" no tiene ningún espacio',
      ),
      (
        'casillas que no son cuadradas',
        buildTmx(tileHeight: 32),
        'tiles/prueba.tmx: las casillas deben ser cuadradas (son 64×32 px)',
      ),
    ];

    for (final (name, tmx, message) in cases) {
      test(name, () => expect(errorOf(tmx), message));
    }

    test('un archivo que no es un mapa de Tiled', () {
      expect(
        errorOf('<html></html>'),
        startsWith('tiles/prueba.tmx: no es un mapa de Tiled válido'),
      );
    });
  });
}
