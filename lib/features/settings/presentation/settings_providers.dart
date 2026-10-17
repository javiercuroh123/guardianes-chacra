import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';

// TODO(fase-7): guardarlos junto con el progreso.
/// Los ajustes del jugador. En la Fase 6 viven en memoria.
class SettingsController extends Notifier<Settings> {
  @override
  Settings build() => const Settings();

  set music(bool on) => state = state.copyWith(music: on);
  bool get music => state.music;

  set effects(bool on) => state = state.copyWith(effects: on);
  bool get effects => state.effects;

  set vibration(bool on) => state = state.copyWith(vibration: on);
  bool get vibration => state.vibration;

  set language(AppLanguage language) =>
      state = state.copyWith(language: language);
  AppLanguage get language => state.language;
}

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

/// El `locale` de la app según el idioma elegido (`null` = el del teléfono).
Locale? localeFor(AppLanguage language) => switch (language) {
  AppLanguage.system => null,
  AppLanguage.es => const Locale('es'),
  AppLanguage.en => const Locale('en'),
};
