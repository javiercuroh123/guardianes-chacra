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
    // El panel de las plagas termina de aparecer.
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('muestra las oleadas y las plagas en el orden en que llegan', (
    tester,
  ) async {
    await pumpPreview(tester);

    expect(find.bySemanticsLabel('Oleadas: 10'), findsOneWidget);
    expect(find.bySemanticsLabel('Maíz inicial: 220'), findsOneWidget);
    expect(find.bySemanticsLabel('Papas: 20'), findsOneWidget);
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
    // En la fila, "antes" es más a la izquierda.
    for (var i = 1; i < order.length; i++) {
      expect(order[i].dx, greaterThan(order[i - 1].dx), reason: 'plaga $i');
      expect(order[i].dy, order[i - 1].dy, reason: 'plaga $i');
    }
    // El jefe lo dice.
    expect(
      find.bySemanticsLabel('Rey Gorgojo, Nueva, Jefe final'),
      findsOneWidget,
    );
  });

  testWidgets('tocar una plaga muestra qué hace; tocar fuera lo cierra', (
    tester,
  ) async {
    await pumpPreview(tester);
    const moth =
        'Vuela de noche y se cuela por cualquier rendija. '
        'Frágil, pero muy rápida.';

    await tester.tap(find.byKey(const ValueKey('preview-pest-polilla')));
    await tester.pump();
    expect(find.text(moth), findsOneWidget);

    await tester.tapAt(const Offset(60, 360));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(moth), findsNothing);
  });

  testWidgets('Volver regresa al valle', (tester) async {
    usePhoneLandscape(tester);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const LevelPreviewScreen(levelId: 'chacra_del_valle'),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
        overrides: [
          contentOverride(content()),
          adsServiceProvider.overrideWithValue(
            FakeAdsService(rewardedReady: false),
          ),
        ],
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preview-back')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelPreviewScreen), findsNothing);
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
