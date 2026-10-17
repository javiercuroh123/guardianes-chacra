import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/json_reader.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:guardianes_chacra/features/content/domain/sprite_def.dart';
import 'package:guardianes_chacra/features/content/domain/unlock_rule.dart';

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
    expect(content.rules.twoStarsFraction, 0.5);
    expect(content.rules.threeStarsFraction, 0.9);

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

  test('lee el color opcional de guardianes y plagas', () async {
    final fixture = ContentFixture()
      ..guardians['hondero'] = {...honderoJson(), 'color': '#A0522D'};
    final content = await ContentLoader(fixture.toSource()).load();

    expect(content.guardians['hondero']!.color, 0xFFA0522D);
    // Sin "color", la vista usa uno derivado del id.
    expect(content.pests['gorgojo']!.color, isNull);
  });

  test('lee las reglas de desbloqueo', () async {
    final fixture = ContentFixture()
      ..addLevel('segundo', unlock: {'afterLevel': 'prueba', 'totalStars': 2})
      ..addGuardian('llama', unlock: {'afterLevel': 'segundo'});
    final content = await ContentLoader(fixture.toSource()).load();

    expect(content.levels.first.unlock, UnlockRule.always);
    expect(
      content.levels.last.unlock,
      const UnlockRule(afterLevel: 'prueba', totalStars: 2),
    );
    expect(content.guardians['hondero']!.unlock, UnlockRule.always);
    expect(
      content.guardians['llama']!.unlock,
      const UnlockRule(afterLevel: 'segundo'),
    );
  });

  test('lee el audio: menú, efectos y música de cada nivel', () async {
    final fixture = ContentFixture()
      ..levels['prueba'] = {...levelJson(), 'music': 'music/valle.ogg'};
    final content = await ContentLoader(fixture.toSource()).load();

    expect(content.audio.menuMusic, 'music/menu.wav');
    expect(content.audio.sfx, {Sfx.shot: 'sfx/shot.wav'});
    expect(content.levels.single.music, 'music/valle.ogg');
  });

  test('lee los sprites de plagas, guardianes y sus niveles', () async {
    final hondero = honderoJson();
    final fixture = ContentFixture()
      ..pests['gorgojo'] = {
        ...gorgojoJson(),
        'sprite': {'image': 'pests/gorgojo.png', 'frames': 4, 'fps': 10},
      }
      ..guardians['hondero'] = {
        ...hondero,
        'sprite': {'image': 'guardians/hondero.png'},
        'levels': [
          (hondero['levels']! as List).first,
          {
            ...(hondero['levels']! as List)[1] as Map<String, Object?>,
            'sprite': {'image': 'guardians/hondero_2.png'},
          },
        ],
      };
    final content = await ContentLoader(fixture.toSource()).load();

    expect(
      content.pests['gorgojo']!.sprite,
      const SpriteDef(image: 'pests/gorgojo.png', frames: 4, fps: 10),
    );
    final def = content.guardians['hondero']!;
    // Sin "frames" ni "fps": una imagen fija.
    expect(def.sprite, const SpriteDef(image: 'guardians/hondero.png'));
    expect(def.spriteAt(level: 1)!.image, 'guardians/hondero.png');
    expect(def.spriteAt(level: 2)!.image, 'guardians/hondero_2.png');
    // La rama no tiene imagen propia: usa la del guardián.
    expect(
      def.spriteAt(level: 2, branchId: 'piedra')!.image,
      'guardians/hondero.png',
    );
  });

  group('sprites', () {
    test('una imagen que no es .png', () async {
      final fixture = ContentFixture()
        ..pests['gorgojo'] = {
          ...gorgojoJson(),
          'sprite': {'image': 'pests/Gorgojo.jpg'},
        };

      expect(
        await errorOf(fixture),
        'pests/gorgojo.json → sprite.image: debe ser una ruta .png en '
        'minúsculas dentro de assets/images/',
      );
    });

    test('cero cuadros', () async {
      final fixture = ContentFixture()
        ..pests['gorgojo'] = {
          ...gorgojoJson(),
          'sprite': {'image': 'pests/gorgojo.png', 'frames': 0},
        };

      expect(
        await errorOf(fixture),
        'pests/gorgojo.json → sprite.frames: debe ser al menos 1',
      );
    });
  });

  group('audio', () {
    test('un efecto desconocido', () async {
      final fixture = ContentFixture()
        ..audio = {
          'sfx': {'disparo': 'sfx/shot.wav'},
        };

      expect(
        await errorOf(fixture),
        'audio.json → sfx.disparo: efecto desconocido (válidos: shot, impact, '
        'pestDefeated, collcaDamaged, victory, defeat, boss)',
      );
    });

    test('una ruta que no es de audio', () async {
      final fixture = ContentFixture()
        ..levels['prueba'] = {...levelJson(), 'music': 'Musica/Valle.txt'};

      expect(
        await errorOf(fixture),
        'levels/prueba.json → music: debe ser una ruta en minúsculas dentro '
        'de assets/audio/ con extensión .wav, .ogg, .mp3 o .m4a',
      );
    });
  });

  group('anuncios', () {
    test('lee las recompensas y la frecuencia', () async {
      final content = await ContentLoader(ContentFixture().toSource()).load();

      expect(content.ads.rewardedStartCorn, 50);
      expect(content.ads.rewardedRevivePotatoes, 5);
      expect(content.ads.interstitialEveryLevels, 3);
    });

    test('un valor negativo', () async {
      final fixture = ContentFixture()..ads['rewardedStartCorn'] = -10;

      expect(
        await errorOf(fixture),
        'ads.json → rewardedStartCorn: debe ser al menos 0',
      );
    });
  });

  group('reglas de desbloqueo', () {
    test('se cumplen con el nivel ganado y las estrellas juntadas', () {
      const rule = UnlockRule(afterLevel: 'uno', totalStars: 4);

      expect(rule.isMetBy({}), isFalse);
      // Ganó el nivel, pero faltan estrellas.
      expect(rule.isMetBy({'uno': 3}), isFalse);
      // Estrellas de sobra, pero sin ganar ese nivel.
      expect(rule.isMetBy({'dos': 3, 'tres': 3}), isFalse);
      expect(rule.isMetBy({'uno': 2, 'dos': 2}), isTrue);
      expect(UnlockRule.always.isMetBy({}), isTrue);
    });

    test('un campo mal escrito', () async {
      final fixture = ContentFixture()
        ..addLevel('segundo', unlock: {'afterlevel': 'prueba'});

      expect(
        await errorOf(fixture),
        'levels/segundo.json → unlock.afterlevel: campo desconocido '
        '(válidos: afterLevel, totalStars)',
      );
    });

    test('un nivel que no existe', () async {
      final fixture = ContentFixture()
        ..addGuardian('llama', unlock: {'afterLevel': 'tercero'});

      expect(
        await errorOf(fixture),
        'guardians/llama.json → unlock.afterLevel: el nivel "tercero" no '
        'existe',
      );
    });

    test('sin condiciones', () async {
      final fixture = ContentFixture()..addLevel('segundo', unlock: {});

      expect(
        await errorOf(fixture),
        'levels/segundo.json → unlock: necesita afterLevel o totalStars (o '
        'quitar "unlock")',
      );
    });

    test('más estrellas de las que se pueden juntar', () async {
      // Dos niveles: como mucho 6 estrellas.
      final fixture = ContentFixture()
        ..addLevel('segundo', unlock: {'totalStars': 7});

      expect(
        await errorOf(fixture),
        'levels/segundo.json → unlock: no se puede cumplir ni ganando con 3 '
        'estrellas todos los niveles que se van abriendo',
      );
    });

    test('un nivel que se pide a sí mismo deja el juego cerrado', () async {
      final fixture = ContentFixture()
        ..levels['prueba'] = {
          ...levelJson(),
          'unlock': {'afterLevel': 'prueba'},
        };

      expect(
        await errorOf(fixture),
        startsWith('levels/prueba.json → unlock: no se puede cumplir'),
      );
    });

    test('un guardián que no se abre nunca', () async {
      final fixture = ContentFixture()
        ..addGuardian('llama', unlock: {'totalStars': 4});

      expect(
        await errorOf(fixture),
        startsWith('guardians/llama.json → unlock: no se puede cumplir'),
      );
    });

    test('ningún guardián abierto al empezar', () async {
      final fixture = ContentFixture()
        ..guardians['hondero'] = {
          ...honderoJson(),
          'unlock': {'afterLevel': 'prueba'},
        };

      expect(
        await errorOf(fixture),
        'index.json → guardians: ninguno está abierto desde el principio',
      );
    });
  });

  group('errores claros', () {
    test('tres estrellas no pueden pedir menos que dos', () async {
      final fixture = ContentFixture()
        ..rules = {
          'sellRefundRate': 0.7,
          'minDamageFraction': 0.2,
          'twoStarsFraction': 0.8,
          'threeStarsFraction': 0.6,
        };

      expect(
        await errorOf(fixture),
        'rules.json → threeStarsFraction: debe ser mayor o igual que '
        'twoStarsFraction',
      );
    });

    test('un color mal escrito', () async {
      final fixture = ContentFixture()
        ..pests['gorgojo'] = {...gorgojoJson(), 'color': 'rojo'};

      expect(
        await errorOf(fixture),
        'pests/gorgojo.json → color: debe ser un color #RRGGBB',
      );
    });

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
      final fixture = ContentFixture()..index['pests'] = ['gorgojo', 'gorgojo'];

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
