import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/presentation/feedback/battle_analytics.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

import '../../../../helpers/battle_fixtures.dart';
import '../../../../helpers/fake_analytics_service.dart';

void main() {
  late FakeAnalyticsService analytics;

  Simulation start(LevelDef level, {int extraCorn = 0}) {
    final simulation = Simulation(
      level: level,
      pests: pestCatalog,
      guardians: guardianCatalog,
      rules: testRules,
      seed: 1,
      extraCorn: extraCorn,
    );
    BattleAnalytics(
      simulation: simulation,
      analytics: analytics,
      levelId: level.id,
      // Para el test: una estrella por papa.
      starsFor: (potatoes) => potatoes,
      extraCorn: extraCorn,
    );
    return simulation;
  }

  void playOut(Simulation simulation) {
    for (var i = 0; i < 5000; i++) {
      if (simulation.status != BattleStatus.playing) return;
      simulation.step();
    }
    fail('la partida no terminó');
  }

  setUp(() => analytics = FakeAnalyticsService());

  test('al empezar anota el nivel y el maíz de un anuncio', () {
    start(testLevel(waves: [testWave('gorgojo')]), extraCorn: 50);

    expect(analytics.names, ['level_start']);
    expect(analytics.last('level_start'), {
      'level': 'prueba',
      'extra_corn': 50,
    });
  });

  test('al ganar anota estrellas, papas y segundos', () {
    // Un Hondero junto al camino derrota al único gorgojo.
    final simulation = start(testLevel(waves: [testWave('gorgojo')]))
      ..enqueue(const BuildGuardian(slotId: 'a', guardianType: 'hondero'));
    playOut(simulation);

    expect(analytics.names, ['level_start', 'level_complete']);
    final complete = analytics.last('level_complete');
    expect(complete['potatoes'], simulation.potatoes);
    expect(complete['stars'], simulation.potatoes);
    expect(complete['revived'], 0);
    expect(complete['seconds'], isA<int>());
  });

  test('al perder anota la oleada; revivida y perdida otra vez, dos veces', () {
    final simulation = start(
      testLevel(
        waves: [
          testWave('gorgojo'),
          // Llega después de revivir (al revivir se van las plagas).
          testWave('gorgojo', count: 3, prepTime: 30),
        ],
        potatoes: 1,
      ),
    );
    playOut(simulation);

    expect(analytics.last('level_fail'), {
      'level': 'prueba',
      'wave': simulation.startedWaves,
      'total_waves': 2,
      'seconds': simulation.tick ~/ 30,
      'revived': 0,
    });

    simulation.revive(1);
    playOut(simulation);

    expect(analytics.names, ['level_start', 'level_fail', 'level_fail']);
    expect(analytics.last('level_fail')['revived'], 1);
  });
}
