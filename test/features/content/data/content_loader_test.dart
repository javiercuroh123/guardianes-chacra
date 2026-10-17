import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

import '../../../helpers/content_fixture.dart';
import '../../../helpers/tmx_builder.dart';

void main() {
  Future<String> errorOf(ContentFixture fixture) async {
    try {
      await ContentLoader(fixture.toSource()).load();
    } on ContentError catch (error) {
      return error.message;
    }
    fail('No lanzó ContentError');
  }

  test('carga el contenido válido', () async {
    final content = await ContentLoader(ContentFixture().toSource()).load();

    expect(content.rules.sellRefundRate, 0.7);

    final gorgojo = content.pests['gorgojo']!;
    expect(gorgojo.maxHealth, 30);
    expect(gorgojo.armor, 2);
    expect(gorgojo.tags, {PestTag.ground});
    expect(gorgojo.resistances, {DamageType.fire: 1.5});
    expect(gorgojo.immunities, {'slow'});
    expect(gorgojo.abilities.single.type, 'split_on_death');
    expect(gorgojo.abilities.single.params, {'pest': 'gorgojo', 'count': 2});
    expect(gorgojo.boss, isFalse);

    final hondero = content.guardians['hondero']!;
    expect(hondero.levels.map((level) => level.cost), [60, 45]);
    expect(hondero.branches.map((branch) => branch.id), ['piedra', 'rapida']);
    expect(hondero.levels.first.behaviors.single.type, 'projectile');
    expect(hondero.levels.first.behaviors.single.params['damage'], 8);

    final level = content.levels.single;
    expect(level.id, 'prueba');
    expect(level.mapFile, 'prueba.tmx');
    expect(level.map.paths.single.id, 'norte');
    expect(level.map.buildSlots, hasLength(2));
    final group = level.waves.single.groups.single;
    expect(
      (group.pestId, group.count, group.interval, group.pathId),
      ('gorgojo', 3, 1.5, 'norte'),
    );

    expect(
      content.texts.text(ContentTexts.pestName('gorgojo'), language: 'en'),
      'Weevil',
    );
  });

  group('errores claros', () {
    test('una oleada con una plaga que no existe', () async {
      final fixture = ContentFixture()
        ..levels['prueba'] = levelJson(pest: 'gorgoja');

      expect(
        await errorOf(fixture),
        'levels/prueba.json → waves[0].groups[0].pest: la plaga "gorgoja" '
        'no existe',
      );
    });

    test('una oleada con un camino que no existe en el mapa', () async {
      final fixture = ContentFixture()
        ..levels['prueba'] = levelJson(path: 'sur');

      expect(
        await errorOf(fixture),
        'levels/prueba.json → waves[0].groups[0].path: el camino "sur" no '
        'existe en tiles/prueba.tmx',
      );
    });

    test('una etiqueta desconocida', () async {
      final fixture = ContentFixture()
        ..guardians['hondero'] = honderoJson(targets: ['ground', 'acuatica']);

      expect(
        await errorOf(fixture),
        'guardians/hondero.json → levels[0].targets[1]: etiqueta desconocida '
        '"acuatica" (válidas: ground, flying)',
      );
    });

    test('un tipo de daño desconocido en las resistencias', () async {
      final fixture = ContentFixture()
        ..pests['gorgojo'] = gorgojoJson(resistances: {'hielo': 2});

      expect(
        await errorOf(fixture),
        'pests/gorgojo.json → resistances.hielo: tipo de daño desconocido '
        '(válidos: physical, fire)',
      );
    });

    test('un guardián con una sola rama', () async {
      final fixture = ContentFixture()
        ..guardians['hondero'] = honderoJson(branchCount: 1);

      expect(
        await errorOf(fixture),
        'guardians/hondero.json → branches: debe tener al menos 2 ramas '
        '(o ninguna)',
      );
    });

    test('un comportamiento sin tipo', () async {
      final fixture = ContentFixture()
        ..guardians['hondero'] = honderoJson(behavior: {'damage': 3});

      expect(
        await errorOf(fixture),
        'guardians/hondero.json → levels[0].behaviors[0].type: falta este '
        'campo',
      );
    });

    test('falta una traducción', () async {
      final fixture = ContentFixture();
      fixture.texts['en']!.remove('pest.gorgojo.description');

      expect(
        await errorOf(fixture),
        'i18n/en.json: falta el texto "pest.gorgojo.description"',
      );
    });

    test('falta un archivo', () async {
      final fixture = ContentFixture()
        ..missing.add('assets/content/pests/gorgojo.json');

      expect(
        await errorOf(fixture),
        'No se encontró el archivo "assets/content/pests/gorgojo.json"',
      );
    });

    test('un id repetido en el índice', () async {
      final fixture = ContentFixture()
        ..index['pests'] = ['gorgojo', 'gorgojo'];

      expect(
        await errorOf(fixture),
        'index.json → pests: "gorgojo" está repetido',
      );
    });

    test('un id con mayúsculas en el índice', () async {
      final fixture = ContentFixture()..index['levels'] = ['Prueba'];

      expect(
        await errorOf(fixture),
        'index.json → levels[0]: "Prueba" solo puede tener minúsculas, '
        'números y _',
      );
    });

    test('un error del mapa llega con el nombre del archivo', () async {
      final fixture = ContentFixture()
        ..maps['prueba.tmx'] = buildTmx(omitLayers: {'collca'});

      expect(
        await errorOf(fixture),
        'tiles/prueba.tmx: falta la capa de objetos "collca"',
      );
    });
  });
}
