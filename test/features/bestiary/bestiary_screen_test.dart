import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/progress/presentation/progress_providers.dart';

import '../../helpers/battle_game_helpers.dart';
import '../../helpers/real_content.dart';
import '../../helpers/test_app.dart';

void main() {
  final content = useRealContent();

  Future<void> pumpBestiary(WidgetTester tester) async {
    usePhoneLandscape(tester);
    await tester.pumpWidget(
      testApp(const BestiaryScreen(), overrides: [contentOverride(content())]),
    );
    await tester.pump();
  }

  Finder inEntry(String entryKey, String text) => find.descendant(
    of: find.byKey(ValueKey(entryKey)),
    matching: find.text(text),
  );

  testWidgets('una plaga sin descubrir no muestra nada; vista, su ficha', (
    tester,
  ) async {
    await pumpBestiary(tester);

    expect(inEntry('bestiary-pest-gorgojo', 'Sin descubrir'), findsOneWidget);
    expect(find.text('Gorgojo'), findsNothing);

    containerOf(
      tester,
      BestiaryScreen,
    ).read(progressProvider.notifier).discoverPest('gorgojo');
    await tester.pump();

    expect(inEntry('bestiary-pest-gorgojo', 'Gorgojo'), findsOneWidget);
    expect(inEntry('bestiary-pest-gorgojo', 'Vida: 30'), findsOneWidget);
    expect(inEntry('bestiary-pest-gorgojo', 'Sin descubrir'), findsNothing);
    // Las demás siguen ocultas.
    expect(inEntry('bestiary-pest-polilla', 'Sin descubrir'), findsOneWidget);
  });

  testWidgets('un guardián aparece en su pestaña al construirlo', (
    tester,
  ) async {
    await pumpBestiary(tester);
    await tester.tap(find.text('Guardianes'));
    await tester.pumpAndSettle();

    expect(
      inEntry('bestiary-guardian-hondero', 'Sin descubrir'),
      findsOneWidget,
    );

    containerOf(
      tester,
      BestiaryScreen,
    ).read(progressProvider.notifier).discoverGuardian('hondero');
    await tester.pump();

    expect(inEntry('bestiary-guardian-hondero', 'Hondero'), findsOneWidget);
  });
}
