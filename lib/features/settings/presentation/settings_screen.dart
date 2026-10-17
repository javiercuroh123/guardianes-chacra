import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardianes_chacra/dev/dev_options.dart';
import 'package:guardianes_chacra/features/settings/domain/settings.dart';
import 'package:guardianes_chacra/features/settings/presentation/settings_providers.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Música, efectos, vibración e idioma.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSettings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              SwitchListTile(
                key: const ValueKey('settings-music'),
                title: Text(l10n.settingsMusic),
                value: settings.music,
                onChanged: (on) => controller.music = on,
              ),
              SwitchListTile(
                key: const ValueKey('settings-effects'),
                title: Text(l10n.settingsEffects),
                value: settings.effects,
                onChanged: (on) => controller.effects = on,
              ),
              SwitchListTile(
                key: const ValueKey('settings-vibration'),
                title: Text(l10n.settingsVibration),
                value: settings.vibration,
                onChanged: (on) => controller.vibration = on,
              ),
              SwitchListTile(
                key: const ValueKey('settings-damage-numbers'),
                title: Text(l10n.settingsDamageNumbers),
                value: settings.damageNumbers,
                onChanged: (on) => controller.damageNumbers = on,
              ),
              if (devToolsEnabled)
                SwitchListTile(
                  key: const ValueKey('settings-dev-unlock'),
                  title: const Text('Desarrollo: todo desbloqueado'),
                  subtitle: const Text('No existe en release; no se guarda'),
                  value: ref.watch(devOptionsProvider).unlockAll,
                  onChanged: (on) =>
                      ref.read(devOptionsProvider.notifier).unlockAll = on,
                ),
              const Divider(height: 32),
              ListTile(title: Text(l10n.settingsLanguage)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<AppLanguage>(
                  key: const ValueKey('settings-language'),
                  segments: [
                    ButtonSegment(
                      value: AppLanguage.system,
                      label: Text(l10n.languageSystem),
                    ),
                    ButtonSegment(
                      value: AppLanguage.es,
                      label: Text(l10n.languageEs),
                    ),
                    ButtonSegment(
                      value: AppLanguage.en,
                      label: Text(l10n.languageEn),
                    ),
                  ],
                  selected: {settings.language},
                  onSelectionChanged: (selection) =>
                      controller.language = selection.single,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
