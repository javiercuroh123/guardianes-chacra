import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/features/progress/presentation/save_providers.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';

/// Los ajustes del jugador. Se guardan junto con el avance (ver
/// `lib/app/autosave.dart`).
class SettingsController extends Notifier<Settings> {
  @override
  Settings build() => ref.watch(savedGameProvider).settings;

  set music(bool on) => state = state.copyWith(music: on);
  bool get music => state.music;

  set effects(bool on) => state = state.copyWith(effects: on);
  bool get effects => state.effects;

  set vibration(bool on) => state = state.copyWith(vibration: on);
  bool get vibration => state.vibration;

  set damageNumbers(bool on) => state = state.copyWith(damageNumbers: on);
  bool get damageNumbers => state.damageNumbers;

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
