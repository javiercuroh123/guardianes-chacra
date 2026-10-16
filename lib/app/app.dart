import 'package:flutter/material.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

class GuardianesApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // El idioma sale del dispositivo; si no es español ni inglés, Flutter
      // usa el primero de supportedLocales (inglés). La Fase 6 agrega la
      // opción de elegirlo en Ajustes.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // TODO(fase-6): ThemeData central con el estilo del juego.
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2E7D32)),
      home: const TitleScreen(),
    );
  }
}
