import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Una app mínima en español, con el tema del juego, para probar una
/// pantalla.
Widget testApp(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: home,
      ),
    );

/// El contenedor de Riverpod de la pantalla [screen] (para leer o cambiar
/// providers desde un test).
ProviderContainer containerOf(WidgetTester tester, Type screen) =>
    ProviderScope.containerOf(tester.element(find.byType(screen)));
