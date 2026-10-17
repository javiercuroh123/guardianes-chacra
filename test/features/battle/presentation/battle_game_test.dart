import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/guardian_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/pest_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/projectile_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/slot_component.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';

import '../../../helpers/battle_game_helpers.dart';

void main() {
  late GameContent content;

  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
  });

  Simulation level1({List<PlayerCommand> commands = const []}) {
    final simulation = Simulation(
      level: content.levels.first,
      pests: content.pests,
      guardians: content.guardians,
      rules: content.rules,
      seed: 1,
    );
    commands.forEach(simulation.enqueue);
    return simulation;
  }

  Future<BattleGame> pumpGame(
    WidgetTester tester,
    Simulation simulation,
  ) async {
    final level = content.levels.first;
    return await pumpBattleGame(
      tester,
      BattleGame(
        simulation: simulation,
        level: level,
        battleAssets: await preloadAssets(
          tester,
          level,
          images: spriteImagesOf(content),
        ),
        sprites: [for (final pest in content.pests.values) ?pest.sprite],
      ),
    );
  }

  testWidgets('dibuja el mapa y un espacio tocable por cada espacio', (
    tester,
  ) async {
    final game = await pumpGame(tester, level1());

    expect(game.world.children.whereType<TiledComponent>(), hasLength(1));
    expect(
      game.world.children.whereType<SlotComponent>().map((slot) => slot.slotId),
      content.levels.first.map.buildSlots.map((slot) => slot.id),
    );
  });

  testWidgets('la cámara encaja el mapa completo en la pantalla', (
    tester,
  ) async {
    final game = await pumpGame(tester, level1());

    // 853 × 384 con un mapa de 1664 × 768: manda la altura, zoom 0,5.
    expect(game.camera.viewfinder.zoom, 0.5);
    expect(game.camera.viewfinder.position, Vector2(832, 384));
  });

  testWidgets('cada plaga tiene su componente y desaparece al irse', (
    tester,
  ) async {
    final simulation = level1();
    final game = await pumpGame(tester, simulation);
    Set<int> drawn() => {
      for (final pest in game.world.children.whereType<PestComponent>())
        pest.pestId,
    };
    Set<int> alive() => {for (final pest in simulation.pests) pest.id};

    // La primera oleada empieza a los 15 s.
    await advance(tester, game, seconds: 17);
    expect(alive(), isNotEmpty);
    expect(drawn(), alive());

    // Sin guardianes, las primeras llegan a la collca hacia los 55 s.
    await advance(tester, game, seconds: 50);
    expect(simulation.potatoes, lessThan(20));
    expect(drawn(), alive());
  });

  testWidgets('un guardián aparece en su espacio y sus proyectiles vuelven '
      'al pool', (tester) async {
    final simulation = level1(
      commands: [const BuildGuardian(slotId: 'e1', guardianType: 'hondero')],
    );
    final game = await pumpGame(tester, simulation);

    await advance(tester, game, seconds: 0.1);
    final guardian = game.world.children.whereType<GuardianComponent>().single;
    // e1 está en la casilla (4,5; 4,5) y las casillas miden 64 px.
    expect(guardian.position, Vector2(4.5 * 64, 4.5 * 64));

    // Los gorgojos de la primera oleada pasan frente a él.
    var sawProjectile = false;
    for (var second = 0; second < 30; second++) {
      await advance(tester, game, seconds: 1);
      sawProjectile |= game.world.children
          .whereType<ProjectileComponent>()
          .isNotEmpty;
    }
    expect(sawProjectile, isTrue);
    expect(game.projectilePool.availableCount, greaterThan(0));
  });

  testWidgets('la plaga se dibuja entre su posición anterior y la actual', (
    tester,
  ) async {
    final simulation = level1();
    final game = await pumpGame(tester, simulation);
    await advance(tester, game, seconds: 20);

    final pest = simulation.pests.first;
    final drawn = game.world.children.whereType<PestComponent>().firstWhere(
      (component) => component.pestId == pest.id,
    );
    final actual = Vector2(pest.position.x, pest.position.y) * 64;
    // Como mucho un tick de atraso: velocidad / 30 casillas.
    final oneTick = pest.def.speed / 30 * 64;

    expect(
      drawn.position.distanceTo(actual),
      lessThanOrEqualTo(oneTick + 1e-6),
    );
  });
}
