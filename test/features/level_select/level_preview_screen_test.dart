import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_assets.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';

import '../../helpers/battle_game_helpers.dart';
import '../../helpers/fake_ads_service.dart';
import '../../helpers/real_content.dart';
import '../../helpers/test_app.dart';

void main() {
  final content = useRealContent();

  Future<void> pumpPreview(
    WidgetTester tester, {
    BattleAssets? assets,
    FakeAdsService? ads,
  }) async {
    usePhoneLandscape(tester);
    await tester.pumpWidget(
      testApp(
        LevelPreviewScreen(levelId: 'chacra_del_valle', assets: assets),
        overrides: [
          contentOverride(content()),
          adsServiceProvider.overrideWithValue(
            ads ?? FakeAdsService(rewardedReady: false),
          ),
        ],
      ),
    );
    await tester.pump();
  }

  testWidgets('muestra las oleadas y las plagas en el orden en que llegan', (
    tester,
  ) async {
    await pumpPreview(tester);

    expect(find.text('10 oleadas'), findsOneWidget);
    final order = [
      for (final id in [
        'gorgojo',
        'polilla',
        'langosta',
        'escarabajo',
        'rey_gorgojo',
      ])
        tester.getTopLeft(find.byKey(ValueKey('preview-pest-$id'))),
    ];
    // En un Wrap, "antes" es más arriba o, en la misma fila, más a la
    // izquierda.
    for (var i = 1; i < order.length; i++) {
      final (previous, current) = (order[i - 1], order[i]);
      expect(
        current.dy > previous.dy ||
            (current.dy == previous.dy && current.dx > previous.dx),
        isTrue,
        reason: 'plaga $i',
      );
    }
  });

  testWidgets('las plagas que el jugador no vio llevan "Nueva"', (
    tester,
  ) async {
    await pumpPreview(tester);
    expect(find.text('Nueva'), findsNWidgets(5));

    containerOf(
      tester,
      LevelPreviewScreen,
    ).read(progressProvider.notifier).discoverPest('gorgojo');
    await tester.pump();

    expect(find.text('Nueva'), findsNWidgets(4));
  });

  testWidgets('Comenzar abre la partida', (tester) async {
    final assets = await preloadAssets(tester, content().levels.first);
    await pumpPreview(tester, assets: assets);

    await tester.tap(find.byKey(const ValueKey('preview-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byType(LevelPreviewScreen), findsNothing);
  });

  group('anuncio recompensado', () {
    Finder rewarded() => find.byKey(const ValueKey('preview-rewarded'));

    testWidgets('sin un anuncio cargado no hay botón', (tester) async {
      await pumpPreview(tester);

      expect(rewarded(), findsNothing);
    });

    testWidgets('el botón aparece en cuanto se carga uno', (tester) async {
      final ads = FakeAdsService(rewardedReady: false);
      await pumpPreview(tester, ads: ads);

      ads.status.value = ads.status.value.copyWith(rewardedReady: true);
      await tester.pump();

      expect(find.text('Ver anuncio: +50 de maíz'), findsOneWidget);
    });

    testWidgets('visto entero, la partida empieza con el maíz extra', (
      tester,
    ) async {
      final assets = await preloadAssets(tester, content().levels.first);
      final ads = FakeAdsService();
      await pumpPreview(tester, assets: assets, ads: ads);

      await tester.tap(rewarded());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await mountedGame(tester);

      expect(ads.rewardedShown, 1);
      final start = content().levels.first.startingCorn;
      expect(find.text('🌽 ${start + 50}'), findsOneWidget);
    });

    testWidgets('cerrado antes, avisa y no empieza', (tester) async {
      final ads = FakeAdsService(earnReward: false);
      await pumpPreview(tester, ads: ads);

      await tester.tap(rewarded());
      await tester.pump();

      expect(find.byType(BattleScreen), findsNothing);
      expect(
        find.text('Mira el anuncio completo para recibir la recompensa.'),
        findsOneWidget,
      );
    });
  });
}
