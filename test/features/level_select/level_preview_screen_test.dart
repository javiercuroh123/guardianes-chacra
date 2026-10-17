import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_game.dart';
import 'package:guardianes_chacra/features/battle/presentation/battle_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';

import '../../helpers/battle_game_helpers.dart';
import '../../helpers/real_content.dart';
import '../../helpers/test_app.dart';

void main() {
  final content = useRealContent();

  Future<void> pumpPreview(WidgetTester tester, {LoadMap? loadMap}) async {
    usePhoneLandscape(tester);
    await tester.pumpWidget(
      testApp(
        LevelPreviewScreen(levelId: 'chacra_del_valle', loadMap: loadMap),
        overrides: [contentOverride(content())],
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
    final loadMap = await preloadMap(tester, content().levels.first);
    await pumpPreview(tester, loadMap: loadMap);

    await tester.tap(find.byKey(const ValueKey('preview-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(BattleScreen), findsOneWidget);
    expect(find.byType(LevelPreviewScreen), findsNothing);
  });
}
