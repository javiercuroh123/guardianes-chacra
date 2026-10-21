import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/domain/unlock_rule.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';

void main() {
  // Las reglas del contenido real (ver docs/CONTENIDO.md).
  const progression = Progression(
    levels: {
      'valle': UnlockRule.always,
      'andenes': UnlockRule(afterLevel: 'valle'),
      'lago': UnlockRule(afterLevel: 'andenes', totalStars: 4),
    },
    guardians: {
      'hondero': UnlockRule.always,
      'pututu': UnlockRule(afterLevel: 'valle'),
      'condor': UnlockRule(afterLevel: 'andenes'),
    },
  );

  List<String> playable(Progress progress) => [
    for (final id in progression.levels.keys)
      if (progression.canPlay(progress, id)) id,
  ];

  List<String> buildable(Progress progress) => [
    for (final id in progression.guardians.keys)
      if (progression.canBuild(progress, id)) id,
  ];

  test('al empezar: el primer nivel y los guardianes sin regla', () {
    expect(playable(const Progress()), ['valle']);
    expect(buildable(const Progress()), ['hondero']);
  });

  test('ganar abre lo que pide ese nivel y dice qué se abrió', () {
    final (progress, unlocked) = progression.record(
      const Progress(),
      'valle',
      stars: 1,
    );

    expect(unlocked.levels, ['andenes']);
    expect(unlocked.guardians, ['pututu']);
    expect(playable(progress), ['valle', 'andenes']);
    expect(progress.unlockedLevels, {'valle', 'andenes'});
  });

  test('perder (0 estrellas) no abre nada', () {
    final (progress, unlocked) = progression.record(
      const Progress(),
      'valle',
      stars: 0,
    );

    expect(unlocked.levels, isEmpty);
    expect(unlocked.guardians, isEmpty);
    expect(playable(progress), ['valle']);
  });

  test('el lago pide ganar Andenes y juntar 4 estrellas', () {
    var (progress, _) = progression.record(const Progress(), 'valle', stars: 1);
    (progress, _) = progression.record(progress, 'andenes', stars: 2);
    // 3 estrellas: falta una.
    expect(playable(progress), ['valle', 'andenes']);
    expect(buildable(progress), ['hondero', 'pututu', 'condor']);

    // Repetir el valle con más estrellas también cuenta.
    final (better, unlocked) = progression.record(progress, 'valle', stars: 2);
    expect(unlocked.levels, ['lago']);
    expect(playable(better), ['valle', 'andenes', 'lago']);
  });

  test('lo ya abierto sigue abierto aunque la regla se endurezca', () {
    final (progress, _) = progression.record(
      const Progress(),
      'valle',
      stars: 1,
    );
    // Una actualización ahora pide 3 estrellas en el valle para Andenes.
    const harder = Progression(
      levels: {
        'valle': UnlockRule.always,
        'andenes': UnlockRule(afterLevel: 'valle', totalStars: 3),
      },
      guardians: {},
    );

    expect(harder.canPlay(progress, 'andenes'), isTrue);
    // Un jugador nuevo, en cambio, sigue la regla nueva.
    expect(
      harder.canPlay(const Progress().withResult('valle', stars: 1), 'andenes'),
      isFalse,
    );
  });

  test('un id que el contenido ya no tiene no está abierto', () {
    expect(progression.canPlay(const Progress(), 'borrado'), isFalse);
  });

  group('el nivel sugerido', () {
    /// El avance tras ganar cada nivel de [stars], en orden, con las
    /// reglas (como en el juego).
    Progress after(Map<String, int> stars) {
      var progress = const Progress();
      for (final MapEntry(key: id, value: count) in stars.entries) {
        (progress, _) = progression.record(progress, id, stars: count);
      }
      return progress;
    }

    test('al empezar, el primero', () {
      expect(progression.suggested(const Progress()), 'valle');
    });

    test('el primero abierto que no tiene estrellas', () {
      expect(progression.suggested(after({'valle': 2})), 'andenes');
    });

    test('con todo ganado, el que tiene menos estrellas', () {
      // El lago sigue cerrado (2 + 1 = 3 de 4): conviene volver al valle.
      expect(
        progression.suggested(after({'valle': 2, 'andenes': 1})),
        'andenes',
      );
      expect(progression.suggested(after({'valle': 1, 'andenes': 2})), 'valle');
    });

    test('con todo en 3 estrellas, el último abierto', () {
      expect(
        progression.suggested(after({'valle': 3, 'andenes': 3, 'lago': 3})),
        'lago',
      );
    });

    test('con "todo desbloqueado" cuentan todos', () {
      expect(
        progression.suggested(after({'valle': 2}), unlockAll: true),
        'andenes',
      );
      expect(
        progression.suggested(
          after({'valle': 2, 'andenes': 3}),
          unlockAll: true,
        ),
        'lago',
      );
    });
  });
}
