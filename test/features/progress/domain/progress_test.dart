import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';

void main() {
  test('guarda el mejor resultado de cada nivel', () {
    final progress = const Progress()
        .withResult('valle', stars: 2)
        .withResult('valle', stars: 1)
        .withResult('andenes', stars: 3);

    expect(progress.starsOf('valle'), 2);
    expect(progress.starsOf('andenes'), 3);
    expect(progress.starsOf('lago'), 0);
  });

  test('una derrota (0 estrellas) no borra una victoria', () {
    final progress = const Progress()
        .withResult('valle', stars: 3)
        .withResult('valle', stars: 0);

    expect(progress.starsOf('valle'), 3);
  });

  test('registra plagas y guardianes descubiertos', () {
    final progress = const Progress()
        .discoverPest('gorgojo')
        .discoverPest('gorgojo')
        .discoverGuardian('hondero');

    expect(progress.discoveredPests, {'gorgojo'});
    expect(progress.discoveredGuardians, {'hondero'});
  });

  test('descubrir algo ya descubierto devuelve el mismo progreso', () {
    final progress = const Progress().discoverPest('gorgojo');

    // Así Riverpod no avisa un cambio que no hubo.
    expect(progress.discoverPest('gorgojo'), same(progress));
  });

  test('suma lo desbloqueado; si no hay nada nuevo, es el mismo', () {
    final progress = const Progress().withUnlocked(
      levels: ['valle'],
      guardians: ['hondero'],
    );

    expect(progress.unlockedLevels, {'valle'});
    expect(progress.unlockedGuardians, {'hondero'});
    expect(progress.withUnlocked(levels: ['valle']), same(progress));
  });

  test('dos progresos con los mismos datos son iguales', () {
    final a = const Progress()
        .withResult('valle', stars: 2)
        .discoverPest('gorgojo')
        .withUnlocked(levels: ['valle', 'andenes']);
    final b = const Progress()
        .withUnlocked(levels: ['andenes', 'valle'])
        .discoverPest('gorgojo')
        .withResult('valle', stars: 2);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(a.withResult('valle', stars: 3)));
  });
}
