import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/burn_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/slow_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/behaviors/effects/stun_effect.dart';
import 'package:guardianes_chacra/features/battle/domain/world/path_track.dart';
import 'package:guardianes_chacra/features/battle/domain/world/pest.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// Plaga de 3 casillas/s: avanza 0,1 casillas por tick.
Pest _pest({Set<String> immunities = const {}}) => Pest(
  id: 1,
  def: PestDef(
    id: 'prueba',
    maxHealth: 10,
    speed: 3,
    cornReward: 1,
    potatoDamage: 1,
    tags: const {PestTag.ground},
    immunities: immunities,
  ),
  wave: 0,
  pathId: 'recto',
  track: PathTrack(const [Vec2(0, 0), Vec2(10, 0)]),
);

void main() {
  group('ralentizar', () {
    test('dos ralentizaciones iguales no se multiplican', () {
      final pest = _pest()
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 60))
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 60));

      expect(pest.speedFactor, 0.5);
    });

    test('una más débil se ignora', () {
      final pest = _pest()
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 60))
        ..applyEffect(const SlowEffect(factor: 0.8, durationTicks: 120));

      expect(pest.speedFactor, 0.5);
      expect(pest.effect('slow')!.remaining, 60);
    });

    test('una más fuerte reemplaza a la actual, con su duración', () {
      final pest = _pest()
        ..applyEffect(const SlowEffect(factor: 0.8, durationTicks: 120))
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 30));

      expect(pest.speedFactor, 0.5);
      expect(pest.effect('slow')!.remaining, 30);
    });

    test('una igual de fuerte deja la duración más larga', () {
      final longer = _pest()
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 30))
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 90));
      final shorter = _pest()
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 90))
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 30));

      expect(longer.effect('slow')!.remaining, 90);
      expect(shorter.effect('slow')!.remaining, 90);
    });

    test('reduce lo que avanza la plaga en cada tick', () {
      final pest = _pest()
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 60))
        ..advance();

      expect(pest.distance, closeTo(0.05, 1e-12));
    });
  });

  test('un efecto dura exactamente su duración en ticks', () {
    final pest = _pest()
      ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 3))
      ..expireEffects()
      ..expireEffects();
    expect(pest.activeEffects, ['slow']);

    pest.expireEffects();
    expect(pest.activeEffects, isEmpty);
    expect(pest.speedFactor, 1);
  });

  group('aturdir', () {
    test('detiene a la plaga', () {
      final pest = _pest()
        ..applyEffect(const StunEffect(durationTicks: 30))
        ..advance();

      expect(pest.distance, 0);
    });

    test('no se suma: queda la duración más larga', () {
      final pest = _pest()
        ..applyEffect(const StunEffect(durationTicks: 30))
        ..applyEffect(const StunEffect(durationTicks: 10));

      expect(pest.effect('stun')!.remaining, 30);
    });

    test('se combina con la ralentización (velocidad 0)', () {
      final pest = _pest()
        ..applyEffect(const SlowEffect(factor: 0.5, durationTicks: 60))
        ..applyEffect(const StunEffect(durationTicks: 30));

      expect(pest.speedFactor, 0);
    });
  });

  test('quemar: queda el mayor daño por segundo y se renueva la '
      'duración', () {
    final pest = _pest()
      ..applyEffect(const BurnEffect(damagePerSecond: 3, durationTicks: 30));
    for (var i = 0; i < 10; i++) {
      pest.expireEffects();
    }
    expect(pest.effect('burn')!.remaining, 20);

    // Una quemadura más débil no baja el daño, pero renueva la duración.
    pest.applyEffect(const BurnEffect(damagePerSecond: 2, durationTicks: 30));
    var burn = pest.effect('burn')!;
    expect((burn.effect as BurnEffect).damagePerSecond, 3);
    expect(burn.remaining, 30);

    // Una más fuerte sube el daño; la duración no se acorta.
    pest.applyEffect(const BurnEffect(damagePerSecond: 5, durationTicks: 10));
    burn = pest.effect('burn')!;
    expect((burn.effect as BurnEffect).damagePerSecond, 5);
    expect(burn.remaining, 30);
  });

  test('una plaga inmune no recibe el efecto', () {
    final pest = _pest(immunities: {'slow'});

    final applied = pest.applyEffect(
      const SlowEffect(factor: 0.5, durationTicks: 60),
    );

    expect(applied, isFalse);
    expect(pest.activeEffects, isEmpty);
    expect(pest.speedFactor, 1);
  });
}
