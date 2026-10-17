import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/domain/events/sim_events.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/damage_number_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/guardian_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/pest_component.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';
import 'package:guardianes_chacra/features/content/domain/sprite_def.dart';

import '../../../helpers/battle_game_helpers.dart';
import '../../../helpers/real_content.dart';

/// El "game feel" de la Fase 8: sprites con su forma de reserva, destello,
/// números de daño, partículas y sacudida de cámara.
void main() {
  final content = useRealContent();

  /// El nivel 1 con solo su última oleada (la del Rey Gorgojo).
  LevelDef bossLevel() {
    final level = content().levels.first;
    return LevelDef(
      id: level.id,
      mapFile: level.mapFile,
      map: level.map,
      startingCorn: level.startingCorn,
      startingPotatoes: level.startingPotatoes,
      earlyCallCornPerSecond: level.earlyCallCornPerSecond,
      waves: [level.waves.last],
    );
  }

  Future<BattleGame> pumpGame(
    WidgetTester tester, {
    LevelDef? level,
    Map<String, GuardianDef>? guardians,
    bool loadImages = true,
    bool showDamageNumbers = false,
    bool reduceMotion = false,
    List<PlayerCommand> commands = const [],
  }) async {
    final playing = level ?? content().levels.first;
    final defs = guardians ?? content().guardians;
    final simulation = Simulation(
      level: playing,
      pests: content().pests,
      guardians: defs,
      rules: content().rules,
      seed: 1,
    );
    commands.forEach(simulation.enqueue);
    return await pumpBattleGame(
      tester,
      BattleGame(
        simulation: simulation,
        level: playing,
        battleAssets: await preloadAssets(
          tester,
          playing,
          images: loadImages ? const ['pests/gorgojo.png'] : const [],
        ),
        sprites: [
          for (final pest in content().pests.values) ?pest.sprite,
          for (final guardian in defs.values) ?guardian.sprite,
        ],
        showDamageNumbers: showDamageNumbers,
        reduceMotion: reduceMotion,
      ),
    );
  }

  /// La primera plaga en pantalla, a los 16 s (la oleada 1 empieza a los
  /// 15 s).
  Future<PestComponent> firstPest(WidgetTester tester, BattleGame game) async {
    await advance(tester, game, seconds: 16);
    return game.world.children.whereType<PestComponent>().first;
  }

  void damage(BattleGame game, int pestId, double amount) =>
      game.simulation.events.publish(
        PestDamaged(
          game.simulation.tick,
          pestId: pestId,
          amount: amount,
          damageType: DamageType.physical,
        ),
      );

  testWidgets('el gorgojo usa su sprite y mira hacia donde camina', (
    tester,
  ) async {
    final game = await pumpGame(tester);
    final gorgojo = await firstPest(tester, game);

    expect(gorgojo.view.def.id, 'gorgojo');
    expect(gorgojo.hasSprite, isTrue);
    // El camino del nivel 1 empieza yendo hacia la derecha.
    expect(gorgojo.facingLeft, isFalse);
  });

  testWidgets('si la imagen no carga, se dibuja la forma de siempre', (
    tester,
  ) async {
    final game = await pumpGame(tester, loadImages: false);

    expect((await firstPest(tester, game)).hasSprite, isFalse);
  });

  testWidgets('un guardián con sprite no muestra su inicial', (tester) async {
    final hondero = content().guardians['hondero']!;
    final game = await pumpGame(
      tester,
      guardians: {
        'hondero': GuardianDef(
          id: hondero.id,
          levels: hondero.levels,
          branches: hondero.branches,
          color: hondero.color,
          sprite: const SpriteDef(image: 'pests/gorgojo.png', frames: 4),
        ),
      },
      commands: [const BuildGuardian(slotId: 'e1', guardianType: 'hondero')],
    );
    await advance(tester, game, seconds: 0.1);

    final guardian = game.world.children.whereType<GuardianComponent>().single;
    expect(guardian.hasSprite, isTrue);
    expect(guardian.children.whereType<TextComponent>().single.text, isEmpty);
  });

  testWidgets('el daño hace destellar a la plaga un instante', (tester) async {
    final game = await pumpGame(tester);
    final pest = await firstPest(tester, game);

    damage(game, pest.pestId, 5);
    expect(pest.isFlashing, isTrue);

    await advance(tester, game, seconds: 0.1);
    expect(pest.isFlashing, isFalse);
  });

  testWidgets('los números de daño suman lo recibido y solo si están '
      'activados', (tester) async {
    final game = await pumpGame(tester, showDamageNumbers: true);
    final pest = await firstPest(tester, game);

    // Dos golpes en el mismo intervalo: un solo número con la suma.
    damage(game, pest.pestId, 4);
    damage(game, pest.pestId, 3.4);
    await advance(tester, game, seconds: 0.35);
    final numbers = game.world.children.whereType<DamageNumberComponent>();
    expect(numbers.map((number) => number.text), ['7']);

    // Desaparece al rato y vuelve al pool.
    await advance(tester, game, seconds: 1);
    expect(game.world.children.whereType<DamageNumberComponent>(), isEmpty);

    game.showDamageNumbers = false;
    damage(game, pest.pestId, 4);
    await advance(tester, game, seconds: 0.35);
    expect(game.world.children.whereType<DamageNumberComponent>(), isEmpty);
  });

  testWidgets('una plaga derrotada suelta partículas', (tester) async {
    final game = await pumpGame(tester);
    final pest = await firstPest(tester, game);

    game.simulation.events.publish(
      PestDefeated(
        game.simulation.tick,
        pestId: pest.pestId,
        pestType: pest.view.def.id,
        reward: 4,
      ),
    );
    await advance(tester, game, seconds: 0.05);

    expect(
      game.world.children.whereType<ParticleSystemComponent>(),
      hasLength(1),
    );
  });

  Future<BattleGame> bossArrives(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    final game = await pumpGame(
      tester,
      level: bossLevel(),
      reduceMotion: reduceMotion,
      commands: [const CallNextWave()],
    );
    // El jefe sale en algún momento de la oleada: se avanza hasta verlo.
    for (var step = 0; step < 300; step++) {
      if (game.simulation.pests.any((pest) => pest.def.boss)) break;
      await advance(tester, game, seconds: 0.1);
    }
    expect(game.simulation.pests.any((pest) => pest.def.boss), isTrue);
    return game;
  }

  testWidgets('la cámara se sacude cuando aparece el jefe y vuelve a su '
      'lugar', (tester) async {
    final game = await bossArrives(tester);
    final center = Vector2(
      content().levels.first.map.width * 64 / 2,
      content().levels.first.map.height * 64 / 2,
    );

    expect(game.isShaking, isTrue);
    expect(game.camera.viewfinder.position, isNot(center));

    await advance(tester, game, seconds: 1);
    expect(game.isShaking, isFalse);
    expect(game.camera.viewfinder.position.distanceTo(center), lessThan(0.001));
  });

  testWidgets('con menos animaciones (accesibilidad) no hay sacudida', (
    tester,
  ) async {
    final game = await bossArrives(tester, reduceMotion: true);

    expect(game.isShaking, isFalse);
  });

  test('el jefe del nivel 1 está en su última oleada', () {
    final last = content().levels.first.waves.last;
    expect(
      last.groups.any((group) => content().pests[group.pestId]!.boss),
      isTrue,
    );
  });
}
