import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/progress/data/save_codec.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progress_repository.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';

void main() {
  const codec = SaveCodec();

  final full = SaveData(
    progress: const Progress()
        .withResult('valle', stars: 3)
        .withResult('andenes', stars: 1)
        .discoverPest('gorgojo')
        .discoverPest('polilla')
        .discoverGuardian('hondero')
        .seePest('gorgojo')
        .seeGuardian('hondero')
        .withUnlocked(levels: ['valle', 'andenes'], guardians: ['hondero']),
    settings: const Settings(
      music: false,
      vibration: false,
      damageNumbers: true,
      language: AppLanguage.en,
    ),
  );

  Matcher throwsSaveFormat(String detail) => throwsA(
    isA<SaveFormatException>().having(
      (error) => error.message,
      'message',
      contains(detail),
    ),
  );

  test('lo guardado se lee igual', () {
    expect(codec.decode(codec.encode(full)), full);
  });

  test('guarda la versión y listas ordenadas (el mismo avance, el mismo '
      'texto)', () {
    final json = jsonDecode(codec.encode(full)) as Map<String, Object?>;

    expect(codec.currentVersion, 1);
    expect(json['version'], 1);
    expect((json['progress']! as Map)['discoveredPests'], [
      'gorgojo',
      'polilla',
    ]);
  });

  test('lo que falta toma su valor por defecto', () {
    expect(codec.decode('{"version": 1}'), const SaveData());
    expect(
      codec.decode('{"version": 1, "settings": {"music": false}}').settings,
      const Settings(music: false),
    );
  });

  test('un guardado de antes del Bestiario nuevo no tiene fichas vistas: '
      'lo descubierto muestra "¡Nuevo!" una vez', () {
    final data = codec.decode(
      '{"version": 1, "progress": {"discoveredPests": ["gorgojo"]}}',
    );
    expect(data.progress.discoveredPests, {'gorgojo'});
    expect(data.progress.seenPests, isEmpty);
    expect(data.progress.seenGuardians, isEmpty);
  });

  test('un guardado de antes de la Fase 8 tiene los números de daño '
      'apagados', () {
    final settings = codec
        .decode('{"version": 1, "settings": {"music": true}}')
        .settings;

    expect(settings.damageNumbers, isFalse);
    expect(settings.effects, isTrue);
  });

  test('un idioma desconocido vuelve al del teléfono', () {
    expect(
      codec
          .decode('{"version": 1, "settings": {"language": "qu"}}')
          .settings
          .language,
      AppLanguage.system,
    );
  });

  group('no se puede leer', () {
    test('JSON roto', () {
      expect(() => codec.decode('{"version": 1,'), throwsSaveFormat('JSON'));
    });

    test('sin versión', () {
      expect(() => codec.decode('{}'), throwsSaveFormat('version'));
    });

    test('una versión más nueva que la app', () {
      expect(
        () => codec.decode('{"version": 2}'),
        throwsSaveFormat('más nueva que la de esta app (1)'),
      );
    });

    test('un tipo inesperado', () {
      expect(
        () => codec.decode(
          '{"version": 1, "progress": {"stars": {"valle": "tres"}}}',
        ),
        throwsSaveFormat('stars.valle debe ser un entero'),
      );
    });
  });

  group('migraciones', () {
    // Un formato inventado para probar el mecanismo:
    // v1 → v2: "estrellas" pasa a llamarse "stars".
    // v2 → v3: el idioma "español" pasa a ser "es".
    final migrating = SaveCodec(
      migrations: [
        (old) {
          final progress = {...old['progress']! as Map<String, Object?>};
          progress['stars'] = progress.remove('estrellas');
          return {...old, 'progress': progress};
        },
        (old) {
          final settings = {...old['settings']! as Map<String, Object?>};
          if (settings['language'] == 'español') settings['language'] = 'es';
          return {...old, 'settings': settings};
        },
      ],
    );

    test('la versión actual es la siguiente a la última migración', () {
      expect(migrating.currentVersion, 3);
      expect(
        jsonDecode(migrating.encode(const SaveData())),
        containsPair('version', 3),
      );
    });

    test('un guardado viejo pasa por todas, en orden', () {
      final data = migrating.decode(
        jsonEncode({
          'version': 1,
          'progress': {
            'estrellas': {'valle': 2},
          },
          'settings': {'language': 'español'},
        }),
      );

      expect(data.progress.starsOf('valle'), 2);
      expect(data.settings.language, AppLanguage.es);
    });

    test('uno de la versión 2 solo pasa por la segunda', () {
      final migrated = migrating.migrate({
        'version': 2,
        'progress': {
          'stars': {'valle': 1},
        },
        'settings': {'language': 'español'},
      });

      expect(migrated['version'], 3);
      expect(migrated['progress'], {
        'stars': {'valle': 1},
      });
      expect(migrated['settings'], {'language': 'es'});
    });
  });
}
