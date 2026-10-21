import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/ads.dart';
import 'package:guardianes_chacra/app/app.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_screen.dart';

import '../../helpers/fake_ads_service.dart';
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
      'settings-damage-numbers',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pump();
    }

    final settings = container.read(settingsProvider);
    expect(settings.music, isFalse);
    expect(settings.effects, isFalse);
    expect(settings.vibration, isFalse);
    // Los números de daño empiezan apagados: el toque los enciende.
    expect(settings.damageNumbers, isTrue);
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

    // "System" vuelve al idioma del teléfono (aquí, español).
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsOneWidget);
  });

  testWidgets('las opciones de privacidad aparecen solo si la ley las pide', (
    tester,
  ) async {
    final ads = FakeAdsService(rewardedReady: false);
    await tester.pumpWidget(
      testApp(
        const SettingsScreen(),
        overrides: [adsServiceProvider.overrideWithValue(ads)],
      ),
    );
    final privacy = find.byKey(const ValueKey('settings-privacy'));
    expect(privacy, findsNothing);

    ads.status.value = ads.status.value.copyWith(privacyOptionsRequired: true);
    await tester.pump();
    await tester.ensureVisible(privacy);
    await tester.pumpAndSettle();
    await tester.tap(privacy);

    expect(find.text('Opciones de privacidad'), findsOneWidget);
    expect(ads.privacyOptionsShown, 1);
  });
}
