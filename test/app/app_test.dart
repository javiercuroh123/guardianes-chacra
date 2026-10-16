import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app.dart';

void main() {
  Future<void> pumpAppWithDeviceLocale(
    WidgetTester tester,
    Locale locale,
  ) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: GuardianesApp()));
    // Las traducciones se cargan de forma asíncrona.
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el título en español', (tester) async {
    await pumpAppWithDeviceLocale(tester, const Locale('es', 'PE'));

    expect(find.text('Guardianes de la Chacra'), findsOneWidget);
    expect(find.text('¡Defiende la cosecha de la collca!'), findsOneWidget);
  });

  testWidgets('muestra el título en inglés', (tester) async {
    await pumpAppWithDeviceLocale(tester, const Locale('en', 'US'));

    expect(find.text('Guardians of the Chacra'), findsOneWidget);
    expect(find.text("Defend the collca's harvest!"), findsOneWidget);
  });

  testWidgets('un idioma sin traducción usa el inglés', (tester) async {
    await pumpAppWithDeviceLocale(tester, const Locale('fr', 'FR'));

    expect(find.text('Guardians of the Chacra'), findsOneWidget);
  });
}
