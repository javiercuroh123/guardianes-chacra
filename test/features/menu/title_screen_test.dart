import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/features/bestiary/presentation/bestiary_screen.dart';
import 'package:guardianes_chacra/features/level_select/presentation/level_select_screen.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';

import '../../helpers/real_content.dart';
import '../../helpers/test_app.dart';

void main() {
  final content = useRealContent();

  for (final (button, screen) in [
    ('menu-play', LevelSelectScreen),
    ('menu-bestiary', BestiaryScreen),
    ('menu-settings', SettingsScreen),
  ]) {
    testWidgets('$button abre su pantalla', (tester) async {
      await tester.pumpWidget(
        testApp(const TitleScreen(), overrides: [contentOverride(content())]),
      );

      await tester.tap(find.byKey(ValueKey(button)));
      await tester.pumpAndSettle();

      expect(find.byType(screen), findsOneWidget);
    });
  }
}
