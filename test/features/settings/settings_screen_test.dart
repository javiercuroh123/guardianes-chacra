import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('los interruptores cambian los ajustes', (tester) async {
    await tester.pumpWidget(testApp(const SettingsScreen()));
    final container = containerOf(tester, SettingsScreen);
    expect(container.read(settingsProvider), const Settings());

    for (final key in [
      'settings-music',
      'settings-effects',
      'settings-vibration',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }

    final settings = container.read(settingsProvider);
    expect(settings.music, isFalse);
    expect(settings.effects, isFalse);
    expect(settings.vibration, isFalse);
  });

  testWidgets('elegir un idioma cambia el de toda la app', (tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es', 'PE')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: GuardianesApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('menu-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);

    // "El del teléfono" vuelve al idioma del sistema (aquí, español).
    await tester.tap(find.text("Phone's language"));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
  });
}
