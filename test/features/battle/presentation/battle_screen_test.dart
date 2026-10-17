import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/simulation.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_screen.dart';
import 'package:guardianes_chacra/features/battle/presentation/components/range_component.dart';
import 'package:guardianes_chacra/features/battle/presentation/layout/map_fit.dart';
import 'package:guardianes_chacra/features/battle/presentation/menus/radial_menu.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';

import '../../../helpers/battle_game_helpers.dart';
import '../../../helpers/test_app.dart';

void main() {
  late GameContent content;
  late LevelDef level;

  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
    level = content.levels.first;
  });

  Future<BattleGame> pumpScreen(WidgetTester tester, {int maps = 1}) async {
    usePhoneLandscape(tester);
    final loadMap = await preloadMap(tester, level, count: maps);
    await tester.pumpWidget(
      testApp(
        BattleScreen(levelId: level.id, loadMap: loadMap),
        overrides: [gameContentProvider.overrideWith((ref) => content)],
      ),
    );
    await tester.pump();
    return await mountedGame(tester);
  }

  /// Posición en pantalla de una casilla (el mapa ocupa el teléfono entero).
  Offset onScreen(Vec2 tiles) => MapFit.compute(
    map: BattleGame.mapSizeOf(level),
    viewport: const Size(853, 384),
  ).toScreen(Offset(tiles.x * 64, tiles.y * 64));

  Vec2 slot(String id) =>
      level.map.buildSlots.firstWhere((slot) => slot.id == id).position;

  Finder key(String value) => find.byKey(ValueKey(value));

  testWidgets('el HUD muestra el maíz, las papas y la oleada', (tester) async {
    await pumpScreen(tester);

    expect(find.text('🌽 220'), findsOneWidget);
    expect(find.text('🥔 20'), findsOneWidget);
    expect(find.text('Oleada 1/10'), findsOneWidget);
  });

  testWidgets('tocar un espacio abre el menú con los 5 guardianes', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapMap(tester, onScreen(slot('e1')));

    for (final type in content.guardians.keys) {
      expect(key('build-$type'), findsOneWidget, reason: type);
    }
  });

  testWidgets('el primer toque muestra la opción y el segundo construye', (
    tester,
  ) async {
    final game = await pumpScreen(tester);
    await tapMap(tester, onScreen(slot('e1')));

    await tester.tap(key('build-hondero'));
    await tester.pump();
    expect(find.text('Toca otra vez para confirmar'), findsOneWidget);
    expect(game.simulation.guardians, isEmpty);

    await tester.tap(key('build-hondero'));
    await tester.pump();
    expect(key('build-hondero'), findsNothing);

    await advance(tester, game, seconds: 0.1);
    expect(game.simulation.guardians.single.slotId, 'e1');
    expect(find.text('🌽 160'), findsOneWidget);
  });

  testWidgets('las opciones que no alcanza el maíz no se pueden elegir', (
    tester,
  ) async {
    final game = await pumpScreen(tester);
    // Tullpa (100) + Cóndor (120) = 220: no queda maíz.
    game.simulation
      ..enqueue(const BuildGuardian(slotId: 'e1', guardianType: 'tullpa'))
      ..enqueue(const BuildGuardian(slotId: 'e2', guardianType: 'condor'));
    await advance(tester, game, seconds: 0.1);

    await tapMap(tester, onScreen(slot('e3')));

    for (final type in content.guardians.keys) {
      expect(
        tester.widget<RadialButton>(key('build-$type')).onTap,
        isNull,
        reason: type,
      );
    }
  });

  testWidgets('tocar fuera cierra el menú', (tester) async {
    await pumpScreen(tester);
    await tapMap(tester, onScreen(slot('e1')));

    // Una casilla de pasto, lejos de espacios y caminos.
    await tapMap(tester, onScreen(const Vec2(0.5, 11.5)));

    expect(key('build-hondero'), findsNothing);
  });

  testWidgets('el menú de un guardián cambia su estrategia y lo vende', (
    tester,
  ) async {
    final game = await pumpScreen(tester);
    game.simulation.enqueue(
      const BuildGuardian(slotId: 'e1', guardianType: 'hondero'),
    );
    await advance(tester, game, seconds: 0.1);

    await tapMap(tester, onScreen(slot('e1')));
    expect(find.text('Primera'), findsOneWidget);

    await tester.tap(key('menu-targeting'));
    await advance(tester, game, seconds: 0.1);
    expect(find.text('Última'), findsOneWidget);
    expect(game.simulation.guardians.single.targetingId, 'last');

    // Vender: 70 % de 60 = 42.
    expect(find.text('+42'), findsOneWidget);
    await tester.tap(key('menu-sell'));
    await tester.pump();
    await tester.tap(key('menu-sell'));
    await advance(tester, game, seconds: 0.1);

    expect(game.simulation.guardians, isEmpty);
    expect(find.text('🌽 202'), findsOneWidget);
  });

  testWidgets('al terminar la partida se quita la selección', (tester) async {
    final game = await pumpScreen(tester);
    game.simulation.enqueue(
      const BuildGuardian(slotId: 'e1', guardianType: 'hondero'),
    );
    await advance(tester, game, seconds: 0.1);
    await tapMap(tester, onScreen(slot('e1')));
    final range = game.world.children.whereType<RangeComponent>().single;
    expect(range.visible, isTrue);

    // Un solo Hondero no alcanza: se pierde antes de los 200 s.
    await advance(tester, game, seconds: 200);
    expect(game.simulation.status, BattleStatus.lost);

    expect(range.visible, isFalse);
    expect(key('menu-sell'), findsNothing);
  });

  testWidgets('al perder aparece el aviso y Reintentar empieza de nuevo', (
    tester,
  ) async {
    final game = await pumpScreen(tester, maps: 2);

    // Sin guardianes, las plagas se comen las 20 papas antes de los 150 s.
    await advance(tester, game, seconds: 150);
    expect(game.simulation.status, BattleStatus.lost);
    expect(find.text('La collca quedó vacía'), findsOneWidget);

    await tester.tap(key('battle-retry'));
    await tester.pump();
    final retried = await mountedGame(tester);

    expect(retried, isNot(same(game)));
    expect(find.text('La collca quedó vacía'), findsNothing);
    expect(find.text('🥔 20'), findsOneWidget);
  });
}

/// Toca el mapa. El detector de toques de Flame deja un temporizador de
/// 40 ms: se espera a que venza para que el test no termine con él pendiente.
Future<void> tapMap(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 50));
}

/// El juego que está en pantalla, ya montado.
Future<BattleGame> mountedGame(WidgetTester tester) async {
  final game = tester
      .widget<GameWidget<BattleGame>>(find.byType(GameWidget<BattleGame>))
      .game!;
  await waitUntilMounted(tester, game);
  return game;
}
