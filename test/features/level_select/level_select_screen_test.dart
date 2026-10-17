import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/progress/domain/progression.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';

import '../../helpers/battle_game_helpers.dart';
import '../../helpers/real_content.dart';
import '../../helpers/test_app.dart';

void main() {
  final content = useRealContent();

  Future<void> pumpValley(WidgetTester tester) async {
    usePhoneLandscape(tester);
    await tester.pumpWidget(
      testApp(
        const LevelSelectScreen(),
        overrides: [contentOverride(content())],
      ),
    );
    await tester.pump();
  }

  test('los niveles se reparten de izquierda a derecha por el sendero', () {
    expect(valleyNodePositions(3), const [
      Offset(0.12, 0.68),
      Offset(0.5, 0.42),
      Offset(0.88, 0.68),
    ]);
    expect(valleyNodePositions(1), const [Offset(0.5, 0.68)]);
  });

  testWidgets('al empezar solo está abierto el primer nivel', (tester) async {
    await pumpValley(tester);

    expect(
      find.bySemanticsLabel('Chacra del Valle: 0 de 3 estrellas'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Andenes: bloqueado'), findsOneWidget);
    expect(find.bySemanticsLabel('Orilla del Lago: bloqueado'), findsOneWidget);
  });

  testWidgets('ganar un nivel muestra sus estrellas y abre el siguiente', (
    tester,
  ) async {
    await pumpValley(tester);

    containerOf(tester, LevelSelectScreen)
        .read(progressProvider.notifier)
        .recordResult(
          'chacra_del_valle',
          stars: 2,
          progression: Progression.of(content()),
        );
    await tester.pump();

    expect(
      find.bySemanticsLabel('Chacra del Valle: 2 de 3 estrellas'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Andenes: 0 de 3 estrellas'), findsOneWidget);
    expect(find.bySemanticsLabel('Orilla del Lago: bloqueado'), findsOneWidget);
  });

  testWidgets('un nivel bloqueado avisa y el abierto lleva a la vista previa', (
    tester,
  ) async {
    await pumpValley(tester);

    await tester.tap(find.byKey(const ValueKey('level-andenes')));
    await tester.pump();
    expect(
      find.text('Gana Chacra del Valle para abrir este nivel'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('level-chacra_del_valle')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelPreviewScreen), findsOneWidget);
    // El aviso no sigue tapando la vista previa.
    expect(
      find.text('Gana Chacra del Valle para abrir este nivel'),
      findsNothing,
    );
  });

  testWidgets('el aviso dice qué le falta al nivel según su regla', (
    tester,
  ) async {
    await pumpValley(tester);
    final progress = containerOf(
      tester,
      LevelSelectScreen,
    ).read(progressProvider.notifier);
    final progression = Progression.of(content());

    progress
      ..recordResult('chacra_del_valle', stars: 1, progression: progression)
      ..recordResult('andenes', stars: 1, progression: progression);
    await tester.pump();

    // Andenes ya está ganado, pero faltan estrellas: 2 de 4.
    expect(find.bySemanticsLabel('Orilla del Lago: bloqueado'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('level-orilla_del_lago')));
    await tester.pump();
    expect(
      find.text(
        'Gana Andenes y junta 4 estrellas para abrir este nivel (tienes 2)',
      ),
      findsOneWidget,
    );

    progress.recordResult('andenes', stars: 3, progression: progression);
    await tester.pump();
    expect(
      find.bySemanticsLabel('Orilla del Lago: 0 de 3 estrellas'),
      findsOneWidget,
    );
  });
}
