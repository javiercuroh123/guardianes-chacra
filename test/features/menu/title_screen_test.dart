import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/content/data/content_loader.dart';
import 'package:guardianes_chacra/features/content/data/file_asset_source.dart';
import 'package:guardianes_chacra/features/content/domain/game_content.dart';
import 'package:guardianes_chacra/features/content/presentation/content_providers.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  FilledButton playButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const ValueKey('title-play')));

  testWidgets('"Jugar" espera a que cargue el contenido', (tester) async {
    await tester.pumpWidget(
      testApp(
        const TitleScreen(),
        overrides: [
          gameContentProvider.overrideWith(
            (ref) => Completer<GameContent>().future,
          ),
        ],
      ),
    );

    expect(find.text('Jugar'), findsOneWidget);
    expect(playButton(tester).onPressed, isNull);
  });

  testWidgets('"Jugar" se activa con el contenido cargado', (tester) async {
    final content = (await tester.runAsync(
      () => ContentLoader(FileAssetSource()).load(),
    ))!;
    await tester.pumpWidget(
      testApp(
        const TitleScreen(),
        overrides: [gameContentProvider.overrideWith((ref) => content)],
      ),
    );
    await tester.pump();

    expect(playButton(tester).onPressed, isNotNull);
  });
}
