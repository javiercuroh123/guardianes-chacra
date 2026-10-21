import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/rive/rive_panel.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_preview_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_layout.dart';
import 'package:guardianes_chacra/features/level_select/presentation/valley_reveal.dart';
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

  testWidgets('desarrollo: "todo desbloqueado" abre todos los niveles', (
    tester,
  ) async {
    await pumpValley(tester);

    containerOf(
      tester,
      LevelSelectScreen,
    ).read(devOptionsProvider.notifier).unlockAll = true;
    await tester.pump();

    expect(
      find.bySemanticsLabel('Orilla del Lago: 0 de 3 estrellas'),
      findsOneWidget,
    );
  });

  test('los anclajes caen sobre el dibujo y se ven en la pantalla', () {
    const ids = ['chacra_del_valle', 'andenes', 'orilla_del_lago', 'nuevo'];
    final anchors = valleyAnchorsFor(ids);
    expect(anchors.take(3), valleyAnchors.values);
    // Un nivel que el dibujo no conoce usa el reparto de siempre.
    expect(anchors.last.dx, closeTo(0.88 * 960, 0.001));
    expect(anchors.last.dy, closeTo(0.42 * 432, 0.001));

    // Un teléfono cubre: el valle llena el alto y se recorta poco.
    final phone = ValleyFrame.of(const Size(853, 384));
    expect(phone.cover, isTrue);
    expect(phone.scale, closeTo(853 / 960, 0.001));
    // Una tableta 4:3 se ajusta al ancho y se apoya abajo.
    final tablet = ValleyFrame.of(const Size(1024, 768));
    expect(tablet.cover, isFalse);
    expect(tablet.toScreen(const Offset(960, 432)), const Offset(1024, 768));
    for (final frame in [phone, tablet]) {
      for (final anchor in anchors.take(3)) {
        final point = frame.toScreen(anchor);
        expect(point.dx, inInclusiveRange(60, frame == phone ? 793 : 964));
      }
    }
  });

  testWidgets('la barra de abajo lleva al nivel sugerido', (tester) async {
    await pumpValley(tester);
    Finder inBar(String text) =>
        find.descendant(of: find.byType(RivePanel), matching: find.text(text));
    expect(inBar('Chacra del Valle'), findsOneWidget);

    containerOf(tester, LevelSelectScreen)
        .read(progressProvider.notifier)
        .recordResult(
          'chacra_del_valle',
          stars: 2,
          progression: Progression.of(content()),
        );
    await tester.pump();
    // Ganado el primero, sugiere Andenes (todavía sin estrellas).
    expect(inBar('Andenes'), findsOneWidget);
    expect(find.bySemanticsLabel('2 de 9 estrellas'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('valley-play')));
    await tester.pumpAndSettle();
    final preview = tester.widget<LevelPreviewScreen>(
      find.byType(LevelPreviewScreen),
    );
    expect(preview.levelId, 'andenes');
  });

  testWidgets('Volver regresa a la pantalla anterior', (tester) async {
    usePhoneLandscape(tester);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LevelSelectScreen(),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
        overrides: [contentOverride(content())],
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelSelectScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('valley-back')));
    await tester.pumpAndSettle();
    expect(find.byType(LevelSelectScreen), findsNothing);
  });

  testWidgets('el globo de un nivel cerrado se va solo o al tocar el mapa', (
    tester,
  ) async {
    await pumpValley(tester);
    const rule = 'Gana Chacra del Valle para abrir este nivel';

    await tester.tap(find.byKey(const ValueKey('level-andenes')));
    await tester.pump();
    expect(find.text(rule), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(rule), findsNothing);

    await tester.tap(find.byKey(const ValueKey('level-andenes')));
    await tester.pump();
    expect(find.text(rule), findsOneWidget);
    await tester.tapAt(const Offset(420, 120));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(rule), findsNothing);
  });

  testWidgets('un nivel recién abierto dibuja su camino al volver al valle', (
    tester,
  ) async {
    await pumpValley(tester);
    final container = containerOf(tester, LevelSelectScreen);
    container
        .read(progressProvider.notifier)
        .recordResult(
          'chacra_del_valle',
          stars: 3,
          progression: Progression.of(content()),
        );
    container.read(valleyRevealProvider.notifier).add(['andenes']);
    await tester.pump();
    await tester.pump();
    // El valle lo tomó: no lo vuelve a dibujar la próxima vez.
    expect(container.read(valleyRevealProvider), isEmpty);
    // Mientras se dibuja, Andenes ya se puede abrir.
    expect(find.bySemanticsLabel('Andenes: 0 de 3 estrellas'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(tester.takeException(), isNull);
  });
}
