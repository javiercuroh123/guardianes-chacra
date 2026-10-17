import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/app/audio.dart';
import 'package:guardianes_chacra/app/autosave.dart';
import 'package:guardianes_chacra/app/text_scale.dart';
import 'package:guardianes_chacra/features/menu/presentation/title_screen.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

class GuardianesApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..watch(autosaveProvider)
      ..watch(audioDirectorProvider);
    final language = ref.watch(
      settingsProvider.select((settings) => settings.language),
    );
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Sin idioma elegido se usa el del teléfono; si no es español ni
      // inglés, Flutter usa el primero de supportedLocales (inglés).
      locale: localeFor(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      builder: clampAppTextScale,
      home: const TitleScreen(),
    );
  }
}
