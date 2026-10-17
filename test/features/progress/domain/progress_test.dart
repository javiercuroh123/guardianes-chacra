import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/progress/domain/progress.dart';

void main() {
  const levels = ['valle', 'andenes', 'lago'];

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

  test('el primer nivel está abierto y cada nivel se abre al ganar el '
      'anterior', () {
    const fresh = Progress();
    expect(fresh.isUnlocked(levels, 0), isTrue);
    expect(fresh.isUnlocked(levels, 1), isFalse);

    final afterLoss = fresh.withResult('valle', stars: 0);
    expect(afterLoss.isUnlocked(levels, 1), isFalse);

    final afterWin = fresh.withResult('valle', stars: 1);
    expect(afterWin.isUnlocked(levels, 1), isTrue);
    expect(afterWin.isUnlocked(levels, 2), isFalse);
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
}
