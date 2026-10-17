import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Simulation;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/core/math/vec2.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/commands.dart';
import 'package:guardianes_chacra/features/battle/domain/engine/fixed_step_clock.dart';
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
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';

import '../../../helpers/battle_game_helpers.dart';
import '../../../helpers/test_app.dart';

void main() {
  late GameContent content;
  late LevelDef level;

  setUpAll(() async {
    content = await ContentLoader(FileAssetSource()).load();
    level = content.levels.first;
  });

  Future<BattleGame> pumpScreen(
    WidgetTester tester, {
    int maps = 1,
    GameContent? withContent,
  }) async {
    usePhoneLandscape(tester);
    final loadMap = await preloadMap(tester, level, count: maps);
    await tester.pumpWidget(
      testApp(
        BattleScreen(levelId: level.id, loadMap: loadMap),
        overrides: [
          gameContentProvider.overrideWith((ref) => withContent ?? content),
        ],
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
    // La primera oleada llega en 15 s; llamarla ya da 15 × 1,5 = 22 de maíz.
    expect(find.text('15 s'), findsOneWidget);
    expect(find.text('+22'), findsOneWidget);
    // Texto claro sobre el fondo oscuro del HUD (`foregroundColor` de
    // IconButton no colorea un Text).
    expect(
      tester.widget<Text>(find.text('x1')).style?.color,
      AppTheme.light.extension<GameColors>()!.onHud,
    );
  });

  testWidgets('llamar la siguiente oleada la empieza y da el bono', (
    tester,
  ) async {
    final game = await pumpScreen(tester);
    final bonus = game.simulation.earlyCallBonus;

    await tester.tap(key('hud-next-wave'));
    await advance(tester, game, seconds: 0.1);

    expect(game.simulation.startedWaves, 1);
    // El bono baja 1 cada 2/3 s: puede haber bajado 1 antes del tick.
    expect(game.simulation.corn - 220, inInclusiveRange(bonus - 1, bonus));
    // Mientras la oleada aparece no hay otra en cuenta regresiva.
    expect(key('hud-next-wave'), findsNothing);
  });

  testWidgets('x2 dobla la velocidad y otro toque la devuelve', (tester) async {
    final game = await pumpScreen(tester);

    await tester.tap(key('hud-speed'));
    await tester.pump();
    expect(game.clock.speed, GameSpeed.fast);
    expect(find.text('x2'), findsOneWidget);

    await tester.tap(key('hud-speed'));
    await tester.pump();
    expect(game.clock.speed, GameSpeed.normal);
  });

  testWidgets('Pausa detiene el juego y Continuar lo reanuda', (tester) async {
    final game = await pumpScreen(tester);

    await tester.tap(key('hud-pause'));
    await tester.pump();
    expect(game.paused, isTrue);
    expect(key('pause-resume'), findsOneWidget);
    // El HUD se oculta: sus botones no deben responder bajo el velo.
    expect(key('hud-pause'), findsNothing);

    await tester.tap(key('pause-resume'));
    await tester.pump();
    expect(game.paused, isFalse);
    expect(key('pause-resume'), findsNothing);
    expect(key('hud-pause'), findsOneWidget);
  });

  testWidgets('al pasar a segundo plano se pausa y sigue así al volver', (
    tester,
  ) async {
    final game = await pumpScreen(tester);
    addTearDown(() => setLifecycle(AppLifecycleState.resumed));

    await setLifecycle(AppLifecycleState.hidden);
    await tester.pump();
    expect(game.paused, isTrue);
    expect(key('pause-resume'), findsOneWidget);

    // Flame reanudaría solo su propia pausa de segundo plano; esta es del
    // jugador y espera a que toque Continuar.
    await setLifecycle(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.paused, isTrue);
    expect(key('pause-resume'), findsOneWidget);
  });

  testWidgets('al ganar: estrellas, resumen, progreso y siguiente nivel', (
    tester,
  ) async {
    // El nivel 1 con solo su primera oleada (6 gorgojos).
    final oneWave = LevelDef(
      id: level.id,
      mapFile: level.mapFile,
      map: level.map,
      startingCorn: level.startingCorn,
      startingPotatoes: level.startingPotatoes,
      earlyCallCornPerSecond: level.earlyCallCornPerSecond,
      waves: [level.waves.first],
    );
    final game = await pumpScreen(
      tester,
      withContent: GameContent(
        rules: content.rules,
        pests: content.pests,
        guardians: content.guardians,
        levels: [oneWave, ...content.levels.skip(1)],
        texts: content.texts,
      ),
    );
    for (final slot in ['e1', 'e2', 'e3']) {
      game.simulation.enqueue(
        BuildGuardian(slotId: slot, guardianType: 'hondero'),
      );
    }

    for (var second = 0; second < 90; second++) {
      if (game.simulation.status != BattleStatus.playing) break;
      await advance(tester, game, seconds: 1);
    }
    expect(game.simulation.status, BattleStatus.won);

    final wave = level.waves.first;
    final harvested =
        wave.reward +
        wave.groups.fold(
          0,
          (sum, group) =>
              sum + group.count * content.pests[group.pestId]!.cornReward,
        );
    expect(find.text('¡La cosecha está a salvo!'), findsOneWidget);
    // La tarjeta se lee entera de una vez (título, estrellas y resumen).
    expect(find.bySemanticsLabel(RegExp('3 de 3 estrellas')), findsOneWidget);
    expect(find.text('Papas salvadas: 20'), findsOneWidget);
    expect(find.text('Maíz cosechado: $harvested'), findsOneWidget);
    expect(key('hud-pause'), findsNothing);

    final progress = containerOf(tester, BattleScreen).read(progressProvider);
    expect(progress.starsOf(level.id), 3);
    expect(progress.discoveredPests, {'gorgojo'});
    expect(progress.discoveredGuardians, {'hondero'});

    await tester.tap(key('victory-next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester
          .widget<LevelPreviewScreen>(find.byType(LevelPreviewScreen))
          .levelId,
      'andenes',
    );
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
    expect(find.text('Volver al valle'), findsOneWidget);
    expect(key('hud-pause'), findsNothing);

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

/// Simula que la app pasa a [state], como lo avisaría el sistema (Flutter
/// genera los estados intermedios: de `resumed` a `hidden` pasa por
/// `inactive`).
Future<void> setLifecycle(AppLifecycleState state) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(state.toString()),
        (_) {},
      );
}

/// El juego que está en pantalla, ya montado.
Future<BattleGame> mountedGame(WidgetTester tester) async {
  final game = tester
      .widget<GameWidget<BattleGame>>(find.byType(GameWidget<BattleGame>))
      .game!;
  await waitUntilMounted(tester, game);
  return game;
}
