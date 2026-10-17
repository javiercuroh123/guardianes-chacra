import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/services/audio_service.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// Revisa el contenido real de `assets/`: si alguien edita un JSON o un
/// mapa y lo deja inválido, este test lo dice antes de abrir el juego.
void main() {
  late GameContent content;

  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
  });

  Simulation simulationFor(LevelDef level) => Simulation(
    level: level,
    pests: content.pests,
    guardians: content.guardians,
    rules: content.rules,
    seed: 1,
  );

  test('tiene los 5 guardianes, las plagas y los 3 niveles en orden', () {
    expect(content.guardians.keys, [
      'hondero',
      'llama',
      'tullpa',
      'condor',
      'pututu',
    ]);
    expect(
      content.pests.keys,
      containsAll(<String>[
        'gorgojo',
        'polilla',
        'langosta',
        'escarabajo',
        'espiritu_helada',
        'granizo',
        'rey_gorgojo',
      ]),
    );
    expect(content.levels.map((level) => level.id), [
      'chacra_del_valle',
      'andenes',
      'orilla_del_lago',
    ]);
  });

  test('cada guardián tiene 2 mejoras y una especialización de 2 ramas', () {
    for (final guardian in content.guardians.values) {
      expect(guardian.levels, hasLength(3), reason: guardian.id);
      expect(guardian.branches, hasLength(2), reason: guardian.id);
    }
  });

  test('cada nivel tiene entre 10 y 15 oleadas y la última trae un jefe', () {
    for (final level in content.levels) {
      expect(level.waves.length, inInclusiveRange(10, 15), reason: level.id);
      final lastWavePests = level.waves.last.groups.map(
        (group) => content.pests[group.pestId]!,
      );
      expect(lastWavePests.any((pest) => pest.boss), isTrue, reason: level.id);
    }
  });

  test('cada guardián tiene su color, distinto y legible con texto blanco', () {
    final colors = [
      for (final guardian in content.guardians.values) guardian.color,
    ];

    expect(colors, everyElement(isNotNull));
    expect(colors.toSet(), hasLength(colors.length));
    for (final guardian in content.guardians.values) {
      // Su inicial se dibuja en blanco encima: contraste mínimo 3:1.
      final luminance = Color(guardian.color!).computeLuminance();
      expect(
        1.05 / (luminance + 0.05),
        greaterThanOrEqualTo(3),
        reason: guardian.id,
      );
    }
  });

  test('Andenes tiene 2 caminos', () {
    final andenes = content.levels.firstWhere((level) => level.id == 'andenes');

    expect(andenes.map.paths.map((path) => path.id), ['norte', 'sur']);
  });

  test('cada nivel crea su partida y, sin guardianes, se pierde', () {
    // Crear la Simulation valida los comportamientos de guardianes y
    // plagas con el registro; jugarla hasta el final recorre cada oleada.
    for (final level in content.levels) {
      final simulation = simulationFor(level);
      for (
        var i = 0;
        i < 30 * 60 * 20 && simulation.status == BattleStatus.playing;
        i++
      ) {
        simulation.step();
      }

      expect(simulation.status, BattleStatus.lost, reason: level.id);
    }
  });

  test('en cada nivel se puede construir cada guardián', () {
    for (final level in content.levels) {
      for (final guardianId in content.guardians.keys) {
        final simulation = simulationFor(level)
          ..enqueue(
            BuildGuardian(
              slotId: level.map.buildSlots.first.id,
              guardianType: guardianId,
            ),
          )
          ..step();

        expect(
          simulation.guardians.single.def.id,
          guardianId,
          reason: '${level.id} / $guardianId',
        );
      }
    }
  });

  test('cada sonido nombrado en los datos existe y está declarado', () {
    final files = {
      ?content.audio.menuMusic,
      ...content.audio.sfx.values,
      for (final level in content.levels) ?level.music,
    };
    // Todos los efectos tienen su archivo (uno que falta quedaría mudo).
    expect(content.audio.sfx.keys, containsAll(Sfx.values));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final file in files) {
      expect(File('assets/audio/$file').existsSync(), isTrue, reason: file);
      final folder = file.substring(0, file.lastIndexOf('/') + 1);
      expect(
        pubspec,
        contains('- assets/audio/$folder'),
        reason: 'falta assets/audio/$folder en pubspec.yaml',
      );
    }
  });

  test('cada sprite existe, está declarado y se divide en sus cuadros', () {
    final sprites = [
      for (final pest in content.pests.values) ?pest.sprite,
      for (final guardian in content.guardians.values) ...[
        ?guardian.sprite,
        for (final level in guardian.levels) ?level.sprite,
        for (final branch in guardian.branches) ?branch.level.sprite,
      ],
    ];
    expect(sprites, isNotEmpty, reason: 'el gorgojo tiene sprite de ejemplo');

    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final sprite in sprites) {
      final file = File('assets/images/${sprite.image}');
      expect(file.existsSync(), isTrue, reason: sprite.image);
      final folder = sprite.image.substring(
        0,
        sprite.image.lastIndexOf('/') + 1,
      );
      expect(pubspec, contains('- assets/images/$folder'), reason: folder);

      // Ancho y alto del PNG (cabecera IHDR): cuadros cuadrados y enteros.
      final header = file.readAsBytesSync().sublist(16, 24);
      int read(int at) =>
          header[at] << 24 |
          header[at + 1] << 16 |
          header[at + 2] << 8 |
          header[at + 3];
      final (width, height) = (read(0), read(4));
      expect(width, sprite.frames * height, reason: sprite.image);
    }
  });
}
