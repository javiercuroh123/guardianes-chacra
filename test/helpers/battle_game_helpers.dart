import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';

/// El mapa y las imágenes ya cargados (ver [preloadAssets]).
class PreloadedAssets extends BattleAssets {
  new(this._maps, this._images);

  final List<Component> _maps;
  final Map<String, ui.Image> _images;

  @override
  Future<Component> loadMap(LevelDef level) async => _maps.removeAt(0);

  @override
  Future<Map<String, ui.Image>> loadImages(Iterable<String> paths) async => {
    for (final path in paths) path: ?_images[path],
  };
}

/// Carga el mapa de Tiled real y las imágenes [images] fuera del reloj falso
/// de los tests: decodificar imágenes (el tileset, los sprites) no funciona
/// con él.
///
/// Un componente no puede estar en dos juegos: si la prueba crea más de una
/// partida (por ejemplo, al reintentar), se precargan [count] mapas y cada
/// partida usa el siguiente.
Future<BattleAssets> preloadAssets(
  WidgetTester tester,
  LevelDef level, {
  int count = 1,
  Iterable<String> images = const [],
}) async {
  const real = BattleAssets();
  final maps = [
    for (var i = 0; i < count; i++)
      (await tester.runAsync(() => real.loadMap(level)))!,
  ];
  final loaded = (await tester.runAsync(() => real.loadImages(images)))!;
  return PreloadedAssets(maps, loaded);
}

/// Las imágenes de todos los sprites del contenido.
Set<String> spriteImagesOf(GameContent content) => {
  for (final pest in content.pests.values) ?pest.sprite?.image,
  for (final guardian in content.guardians.values) ...[
    ?guardian.sprite?.image,
    for (final level in guardian.levels) ?level.sprite?.image,
    for (final branch in guardian.branches) ?branch.level.sprite?.image,
  ],
};

/// Pone la pantalla del tamaño de un teléfono horizontal (853 × 384).
void usePhoneLandscape(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(853, 384)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Monta [game] en un GameWidget y espera a que termine de cargar.
Future<BattleGame> pumpBattleGame(WidgetTester tester, BattleGame game) async {
  usePhoneLandscape(tester);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await waitUntilMounted(tester, game);
  return game;
}

Future<void> waitUntilMounted(WidgetTester tester, BattleGame game) async {
  for (var frame = 0; frame < 60 && !game.isMounted; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.isMounted, isTrue, reason: 'el juego no terminó de montarse');
  await tester.pump();
}

/// Avanza el juego [seconds] segundos en frames de 1/60 s y deja que Flame
/// procese los componentes agregados o quitados.
Future<void> advance(
  WidgetTester tester,
  BattleGame game, {
  required double seconds,
}) async {
  final frames = (seconds * 60).round();
  for (var frame = 0; frame < frames; frame++) {
    game.update(1 / 60);
  }
  await tester.pump();
}

/// El juego que está en pantalla, ya montado.
Future<BattleGame> mountedGame(WidgetTester tester) async {
  final game = tester
      .widget<GameWidget<BattleGame>>(find.byType(GameWidget<BattleGame>))
      .game!;
  await waitUntilMounted(tester, game);
  return game;
}
