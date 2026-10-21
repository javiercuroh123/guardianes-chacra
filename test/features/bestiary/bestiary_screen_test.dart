import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
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
    // Los paneles terminan de aparecer.
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder inEntry(String entryKey, String text) => find.descendant(
    of: find.byKey(ValueKey(entryKey)),
    matching: find.text(text),
  );

  /// El texto en el panel del detalle (el segundo de la pestaña).
  Finder inDetail(String text) => find.descendant(
    of: find.byType(RivePanel).at(1),
    matching: find.text(text),
  );

  testWidgets('una plaga sin descubrir es "?"; descubierta, se da vuelta al '
      'tocarla y muestra su ficha', (tester) async {
    await pumpBestiary(tester);
    expect(inEntry('bestiary-pest-gorgojo', '???'), findsOneWidget);
    expect(find.bySemanticsLabel('Sin descubrir'), findsWidgets);

    final container = containerOf(tester, BestiaryScreen);
    container.read(progressProvider.notifier).discoverPest('gorgojo');
    await tester.pump();
    // Boca abajo hasta que se toca.
    expect(find.bySemanticsLabel('¡Nuevo!'), findsWidgets);
    expect(container.read(progressProvider).seenPests, isEmpty);

    await tester.tap(find.byKey(const ValueKey('bestiary-pest-gorgojo')));
    await tester.pump();
    expect(container.read(progressProvider).seenPests, {'gorgojo'});
    expect(inEntry('bestiary-pest-gorgojo', 'Gorgojo'), findsOneWidget);
    expect(find.bySemanticsLabel('Gorgojo, ¡Nuevo!'), findsOneWidget);
    expect(inDetail('Vida'), findsOneWidget);
    expect(inDetail('30'), findsOneWidget);

    // Una sin descubrir dice cómo conocerla.
    await tester.tap(find.byKey(const ValueKey('bestiary-pest-polilla')));
    await tester.pump();
    expect(inDetail('Aparece en una partida para conocerla.'), findsOneWidget);
  });

  testWidgets('los guardianes, en su pestaña: niveles y especializaciones', (
    tester,
  ) async {
    await pumpBestiary(tester);
    final container = containerOf(tester, BestiaryScreen);
    container.read(progressProvider.notifier)
      ..discoverGuardian('hondero')
      ..seeGuardian('hondero');

    await tester.tap(find.byKey(const ValueKey('bestiary-tab-guardians')));
    await tester.pumpAndSettle();
    expect(inEntry('bestiary-guardian-hondero', 'Hondero'), findsOneWidget);
    expect(inEntry('bestiary-guardian-llama', '???'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bestiary-guardian-hondero')));
    await tester.pump();
    expect(inDetail('Costo'), findsOneWidget);
    expect(inDetail('60'), findsOneWidget);
    expect(inDetail('Al nivel III, una de estas:'), findsOneWidget);
    expect(inDetail('Piedra pesada'), findsOneWidget);

    // El nivel II muestra lo que cuesta mejorarlo.
    await tester.tap(find.text('II'));
    await tester.pump();
    expect(inDetail('Mejora'), findsOneWidget);
    expect(inDetail('45'), findsOneWidget);
  });

  testWidgets('se puede deslizar de una pestaña a la otra', (tester) async {
    await pumpBestiary(tester);
    expect(find.byKey(const ValueKey('bestiary-pest-gorgojo')), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1500);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('bestiary-guardian-hondero')),
      findsOneWidget,
    );
  });
}
